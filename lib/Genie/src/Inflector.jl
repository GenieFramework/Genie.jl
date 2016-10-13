module Inflector
using Genie

const vowels = ["a", "e", "i", "o", "u"]

function to_singular(word::AbstractString; is_irregular::Bool = false)
  ( is_irregular || ! endswith(word, "s") ) && return to_singular_irregular(word)
  endswith(word, "ies") && ! in(word[end-3], vowels) && return Nullable{String}(word[1:end-3] * "y")
  endswith(word, "s") && return Nullable{String}(word[1:end-1])
  Nullable{String}()
end

function to_singular_irregular(word::AbstractString)
  irr = irregular(word)
  if ! isnull(irr)
    Nullable{Base.get(irr)[1]}
  else
    Nullable{String}()
  end
end

function to_plural(word::AbstractString; is_irregular::Bool = false)
  is_irregular && return to_plural_irregular(word)
  endswith(word, "y") && ! in(word[end-1], vowels) && return Nullable{String}(word[1:end-1] * "ies") # category -> categories // story -> stories
  is_singular(word) ? Nullable{String}(word * "s") : Nullable{String}(word)
end

function to_plural_irregular(word::AbstractString)
  irr = irregular(word)
  if ! isnull(irr)
    Nullable{String}(Base.get(irr)[2])
  else
    Nullable{String}()
  end
end

function from_underscores(word::AbstractString)
  mapreduce(x -> ucfirst(x), *, split(word, "_"))
end

function is_singular(word::AbstractString)
  ! is_plural(word)
end

function is_plural(word::AbstractString)
  endswith(word, "s") || ! isnull(irregular(word))
end

function irregulars()
  vcat(irregular_nouns, Genie.config.inflector_irregulars)
end

function irregular(word::AbstractString)
  for (k, v) in irregular_nouns
    (word == k || word == v) && return Nullable{Tuple{String,String}}(k, v)
  end

  Nullable{Tuple{String,String}}()
end

irregular_nouns = Vector{Tuple{String,String}}([
  ("alumnus", "alumni"),
  ("cactus", "cacti"),
  ("focus", "foci"),
  ("fungus", "fungi"),
  ("nucleus", "nuclei"),
  ("radius", "radii"),
  ("stimulus", "stimuli"),
  ("axis", "axes"),
  ("analysis", "analyses"),
  ("basis", "bases"),
  ("crisis", "crises"),
  ("diagnosis", "diagnoses"),
  ("ellipsis", "ellipses"),
  ("hypothesis", "hypotheses"),
  ("oasis", "oases"),
  ("paralysis", "paralyses"),
  ("parenthesis", "parentheses"),
  ("synthesis", "syntheses"),
  ("synopsis", "synopses"),
  ("thesis", "theses"),
  ("appendix", "appendices"),
  ("index", "indeces"),
  ("matrix", "matrices"),
  ("beau", "beaux"),
  ("bureau", "bureaus"),
  ("tableau", "tableaux"),
  ("child", "children"),
  ("man", "men"),
  ("ox", "oxen"),
  ("woman", "women"),
  ("bacterium", "bacteria"),
  ("corpus", "corpora"),
  ("criterion", "criteria"),
  ("curriculum", "curricula"),
  ("datum", "data"),
  ("genus", "genera"),
  ("medium", "media"),
  ("memorandum", "memoranda"),
  ("phenomenon", "phenomena"),
  ("stratum", "strata"),
  ("deer", "deer"),
  ("fish", "fish"),
  ("means", "means"),
  ("offspring", "offspring"),
  ("series", "series"),
  ("sheep", "sheep"),
  ("species", "species"),
  ("foot", "feet"),
  ("goose", "geese"),
  ("tooth", "teeth"),
  ("antenna", "antennae"),
  ("formula", "formulae"),
  ("nebula", "nebulae"),
  ("vertebra", "vertebrae"),
  ("vita", "vitae"),
  ("louse", "lice"),
  ("mouse", "mice")
])
end