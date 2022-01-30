"""
Handles input coming through Http server requests.
"""
module Input

import HttpCommon, HTTP

export post, files, HttpInput, HttpPostData, HttpFiles, HttpFile


"""
    HttpFile

Represents a file sent over HTTP
"""
mutable struct HttpFile
  name::String
  mime::String
  data::Array{UInt8}
end
HttpFile() = HttpFile("", "", UInt8[])

const HttpPostData  = Dict{String, Union{String, Vector{String}}}
const HttpFiles     = Dict{String,HttpFile}

mutable struct HttpInput
  post::HttpPostData
  files::HttpFiles
end
HttpInput() = HttpInput(HttpPostData(), HttpFiles())

###

mutable struct HttpFormPart
  headers::Dict{String, Dict{String,String}}
  data::Array{UInt8}
end
HttpFormPart() = HttpFormPart(Dict{String,Dict{String,String}}(), UInt8[])

###

function all(request::HTTP.Request) :: HttpInput
  input::HttpInput = HttpInput()
  post_from_request!(request, input)

  input
end

function post(request::HTTP.Request)
  input::HttpInput = all(request)

  input.post
end

function files(request::HTTP.Request)
  input::HttpInput = all(request)

  input.files
end

###

function post_from_request!(request::HTTP.Request, input::HttpInput)
  headers = Dict(request.headers)

  if first(something(findfirst("application/x-www-form-urlencoded", get(headers, "Content-Type", "")), 0:-1)) != 0
    post_url_encoded!(request.body, input.post)
  elseif first(something(findfirst("multipart/form-data", get(headers, "Content-Type", "")), 0:-1)) != 0
    post_multipart!(request, input.post, input.files)
  end

  nothing
end

function post_url_encoded!(http_data::Array{UInt8, 1}, post_data::HttpPostData)
  if occursin("%5B%5D", String(copy(http_data))) || occursin("[]", String(copy(http_data))) # array values []
    for query_part in split(String(http_data), "&")
      qp = split(query_part, "=")
      (size(qp)[1] == 1) && (push!(qp, ""))

      k = Symbol(HTTP.URIs.unescapeuri(qp[1]))
      v = HTTP.URIs.unescapeuri(qp[2])
      # collect values like x[] in an array
      if endswith(string(k), "[]")
        if haskey(post_data, string(k))
          push!(post_data[string(k)], string(v))
        else
          post_data[string(k)] = [string(v)]
        end
      else
        post_data[string(k)] = string(v)
      end
    end
  else
    params::Dict{String,String} = HTTP.URIs.queryparams(String(http_data))

    for (key::String, value::String) in params
      post_data[key] = value
    end
  end
end

function post_multipart!(request::HTTP.Request, post_data::HttpPostData, files::HttpFiles) :: Nothing
  headers = Dict(request.headers)
  boundary::String = headers["Content-Type"][(findfirst("boundary=", headers["Content-Type"])[end] + 1):end]

  boundary_length::Int = length(boundary)

  if boundary_length > 0
    form_parts::Array{HttpFormPart} = HttpFormPart[]

    get_multiform_parts!(request.body, form_parts, boundary, boundary_length)

    ### Process form parts

    if length(form_parts) > 0
      for part::HttpFormPart in form_parts
        hasFile::Bool = false
        file::HttpFile = HttpFile()
        fileFieldName::String = ""

        for (field::String, values::Dict{String,String}) in part.headers
          if field == "Content-Disposition" && getkey(values, "form-data", nothing) != nothing

            # Check to see whether this part is a file upload
            # Otherwise, treat as basic POST data

            if getkey(values, "filename", nothing) != nothing
              if length(values["filename"]) > 0
                fileFieldName = values["name"]
                file.name = values["filename"]
                hasFile = true
              end
            elseif getkey(values, "name", nothing) != nothing
              post_data[values["name"]] = String(part.data)
            end
          elseif field == "Content-Type"
            (file.mime, mime) = first(values)
          end
        end # for

        if hasFile
          file.data = part.data

          files[fileFieldName] = file

          fileFieldName = ""
          file = HttpFile()
          hasFile = false
        end # if
      end # for
    end # if
  end

  nothing
end

###

function get_multiform_parts!(http_data::Vector{UInt8}, formParts::Array{HttpFormPart}, boundary, boundaryLength::Int = length(boundary))
  ### Go through each byte of data, parsing it into POST data and files.

  # According to the spec, the boundary chosen by the client must be a unique string
  # i.e. there should be no conflicts with the data within - so it should be safe to just do a basic string search.

  part::HttpFormPart = HttpFormPart()

  headerRaw::Array{UInt8} = UInt8[]

  captureAsData::Bool = false

  crOn::Bool = false
  hadLineEnding::Bool = false
  foundBoundary::Bool = false
  foundFinalBoundary::Bool = false

  bytes::Int = length(http_data)

  byteIndexOffset::Int = 0
  testIndex::Int = 1
  byteTestIndex::Int = 0

  byte::UInt8 = 0x00

  # Skip over the first boundary and CRLF

  byteIndex::Int = boundaryLength + 5

  while !foundFinalBoundary && byteIndex <= bytes
    byte = http_data[byteIndex]

    # Test for boundary.

    if (
      (byte == 0x0d && bytes >= byteIndex+3 && http_data[byteIndex + 1] == 0x0a && Char(http_data[byteIndex + 2]) == '-' && Char(http_data[byteIndex + 3]) == '-')
      || (byte == '-' && bytes >= byteIndex+1 && Char(http_data[byteIndex + 1]) == '-')
      )
      foundBoundary = true
    end

    if byte == 0x0d
      byteIndexOffset = byteIndex + 3
    else
      byteIndexOffset = byteIndex + 1
    end

    byteTestIndex = byteIndexOffset

    testIndex = 1;

    # Find the position of the next char NOT in the boundary
    if foundBoundary
      while testIndex < boundaryLength
        byteTestIndex = byteIndexOffset + testIndex

        if byteTestIndex > bytes || Char(http_data[byteTestIndex]) != boundary[testIndex]
          break
        end

        testIndex = testIndex + 1
      end
    end

    # Check if this boundary is the final one
    if foundBoundary
      if Char(http_data[byteTestIndex + 2]) == '-'
        foundFinalBoundary = true
        byteIndex = byteTestIndex + 5
      else
        byteIndex = byteTestIndex + 3
      end
    end

    ## Otherwise, process data

    if foundBoundary
      captureAsData = false
      crOn = false
      hadLineEnding = false
      foundBoundary = false

      push!(formParts, part)

      part = HttpFormPart()
    else
      if captureAsData
        push!(part.data, byte)
      else
        ## Check for CR

        if byte == 0x0d
          crOn = true
        else
          ## Check for LF and previous CR

          if byte == 0x0a && crOn
            ## Check for CRLFCRLF

            if hadLineEnding
              ## End of headers

              captureAsData = true

              hadLineEnding = false
            else
              ## End of single-line header

              header::String = String(headerRaw)

              if length(header) > 0
                headerParts = split(header, ": "; limit=2)

                valueDecoded = parse_semicolon_fields(String(headerParts[2]));

                if length(valueDecoded) > 0
                  part.headers[headerParts[1]] = valueDecoded
                end
              end

              headerRaw = UInt8[]

              hadLineEnding = true
            end
          else
            if hadLineEnding
              hadLineEnding = false
            end

            push!(headerRaw, byte)
          end

          crOn = false
        end
      end
    end

    byteIndex = byteIndex + 1
  end
end

###

function parse_semicolon_fields(dataString::String)
  dataString = dataString * ";"

  data = Dict{String,String}()

  prevCharacter::Char = 0x00
  inSingleQuotes::Bool = false
  inDoubleQuotes::Bool = false
  ignore::Bool = false
  workingString::String = ""

  dataStringLength::Int = length(dataString)

  dataStringLengthLoop::Int = dataStringLength + 1

  charIndex::Int = 1
  utfIndex::Int = 1 # real index for uft-8

  while charIndex < dataStringLengthLoop
    # character = dataString[charIndex]
    character = dataString[utfIndex]

    if ! inSingleQuotes && character == '"' && prevCharacter != '\\'
      inDoubleQuotes = ! inDoubleQuotes
      ignore = true
    end

    if ! inDoubleQuotes && character == '\'' && prevCharacter != '\\'
      inSingleQuotes = ! inSingleQuotes
      ignore = true
    end

    if charIndex == dataStringLength || (character == ';' && !(inSingleQuotes || inDoubleQuotes))
      workingString = strip(workingString)

      if length(workingString) > 0
        decoded = parse_quoted_params(workingString)

        if decoded != nothing
          (key, value) = decoded

          data[key] = value
        else
          data[workingString] = workingString
        end

        workingString = ""
      end
    elseif ! ignore
      workingString = workingString * string(character)
    end

    prevCharacter = character

    charIndex  = charIndex + 1

    utfIndex = nextind(dataString, utfIndex)   # real index for uft-8

    ignore = false
  end

  return data
end

function parse_quoted_params(data::String)
  tokens = split(data, "="; limit=2)

  if length(tokens) == 2
    return (tokens[1], tokens[2])
  end

  return nothing
end


###

end
