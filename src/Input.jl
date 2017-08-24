"""
Handles input coming through HttpServer requests.
"""
module Input

using HttpCommon, URIParser

export post, files, HttpInput, HttpPostData, HttpFiles, HttpFile

type HttpFile
  name::String
  mime::String
  data::Array{UInt8}

  HttpFile() = new("", "", UInt8[])
end

const HttpPostData = Dict{String, String}
const HttpFiles    = Dict{String, HttpFile}

type HttpInput
  post::HttpPostData
  files::HttpFiles

  HttpInput() = new(HttpPostData(), HttpFiles())
end

###

type HttpFormPart
  headers::Dict{String, Dict{String, String}}
  data::Array{UInt8}

  HttpFormPart() = new(Dict{String, Dict{String, String}}(), UInt8[])
end

###

function all(request::Request) :: HttpInput
  input::HttpInput = HttpInput()

  post_from_request!(request, input)

  input
end

function post(request::Request)
  input::HttpInput = all(request)

  input.post
end

function files(request::Request)
  input::HttpInput = all(request)

  input.files
end

###

function post_from_request!(request::Request, input::HttpInput)
  if get(request.headers, "Content-Type", "") == "application/x-www-form-urlencoded"
    post_url_encoded!(request.data, input.post)
  elseif searchindex(get(request.headers, "Content-Type", ""), "multipart/form-data") != 0
    post_multipart!(request, input.post, input.files)
  end
end

function post_url_encoded!(http_data::Array{UInt8, 1}, post_data::HttpPostData)
  params::Dict{String, String} = query_params(String(http_data))

  for (key::String, value::String) in params
    post_data[key] = value
  end
end

function post_multipart!(request::Request, post_data::HttpPostData, files::HttpFiles)
  boundary::String = request.headers["Content-Type"][(searchindex(request.headers["Content-Type"], "boundary=") + 9):end]

  boundary_length::Int = length(boundary)

  if boundary_length > 0
    form_parts::Array{HttpFormPart} = HttpFormPart[]

    get_mutliform_parts!(request.data, form_parts, boundary, boundary_length)

    ### Process form parts
    ### (This could potentially be done within get_mutliform_parts! - but then it would be even bigger than it is now)

    if length(form_parts) > 0
      for part::HttpFormPart in form_parts
        hasFile::Bool = false
        file::HttpFile = HttpFile()
        fileFieldName::String = ""

        for (field::String, values::Dict{String, String}) in part.headers
          if field == "Content-Disposition" && getkey(values, "form-data", null) != null

              # Check to see whether this part is a file upload
              # Otherwise, treat as basic POST data

              if getkey(values, "filename", null) != null
                if length(values["filename"]) > 0
                  fileFieldName = values["name"]
                  file.name = values["filename"]
                  hasFile = true
                end
              elseif getkey(values, "name", null) != null
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
end

###

function get_mutliform_parts!(http_data::Array{UInt8, 1}, formParts::Array{HttpFormPart}, boundary, boundaryLength::Int64 = length(boundary))
  ### Go through each byte of data, parsing it into POST data and files.

  # The loop is perhaps slightly ambitious, as I wanted to be able to parse all the data
  # in one pass - rather than one pass for boundaries, another for headers, etc.

  # According to the spec, the boundary chosen by the client must be a unique string
  # i.e. there should be no conflicts with the data within - so it should be safe to just do a basic string search.

  part::HttpFormPart = HttpFormPart()

  headerRaw::Array{UInt8} = UInt8[]

  captureAsData::Bool = false

  crOn::Bool = false
  hadLineEnding::Bool = false
  foundBoundary::Bool = false
  foundFinalBoundary::Bool = false

  bytes::Int64 = length(http_data)

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
      (byte == 0x0d && http_data[byteIndex + 1] == 0x0a && http_data[byteIndex + 2] == '-' && http_data[byteIndex + 3] == '-')
      || (byte == '-' && http_data[byteIndex + 1] == '-')
      )
    foundBoundary = true

    if byte == 0x0d
      byteIndexOffset = byteIndex + 3
    else
      byteIndexOffset = byteIndex + 1
    end

    byteTestIndex = byteIndexOffset

    testIndex = 1;

    while testIndex < boundaryLength
      byteTestIndex = byteIndexOffset + testIndex

      if byteTestIndex > bytes || http_data[byteTestIndex] != boundary[testIndex]
        foundBoundary = false
        break
      end

      testIndex = testIndex + 1
    end

    if foundBoundary
      if http_data[byteTestIndex + 2] == '-'
        foundFinalBoundary = true
        byteIndex = byteTestIndex + 5
      else
        byteIndex = byteTestIndex + 3
      end
    end
  else
    foundBoundary = false
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
                headerParts = split(header, ": ", 2)

                valueDecoded = parse_seicolon_fields(String(headerParts[2]));

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

function parse_seicolon_fields(dataString::String)
  dataString = dataString * ";"

  data = Dict{String, String}()

  prevCharacter::Char = 0x00
  inSingleQuotes::Bool = false
  inDoubleQuotes::Bool = false
  ignore::Bool = false
  workingString::String = ""

  dataStringLength::Int = length(dataString)

  dataStringLengthLoop::Int = dataStringLength + 1

  charIndex::Int = 1

  while charIndex < dataStringLengthLoop
    character = dataString[charIndex]

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

        if decoded != null
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

    ignore = false
  end

  return data
end

function parse_quoted_params(data::String)
  tokens = split(data, "=", 2)

  if length(tokens) == 2
    return (tokens[1], tokens[2])
  end

  return null
end


###

end
