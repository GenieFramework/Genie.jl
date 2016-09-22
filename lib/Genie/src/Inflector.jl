module Inflector
using Genie

function to_singular(word::AbstractString; is_irregular::Bool = false)
  ( is_irregular || ! endswith(word, "s") ) && return to_singular_irregular(word)
  endswith(word, "s") && return Nullable{AbstractString}(word[1:end-1])
  Nullable{AbstractString}()
end

function to_singular_irregular(word::AbstractString)
  irr = irregular(word)
  if ! isnull(irr)
    return Nullable{Base.get(irr)[1]}
  else
    return Nullable{AbstractString}()
  end
end

function to_plural(word::AbstractString; is_irregular::Bool = false)
  is_irregular && return to_plural_irregular(word)
  return is_singular(word) ? Nullable{AbstractString}(word * "s") : Nullable{AbstractString}(word)
end

function to_plural_irregular(word::AbstractString)
  irr = irregular(word)
  if ! isnull(irr)
    return Nullable{AbstractString}(Base.get(irr)[2])
  else
    return Nullable{AbstractString}()
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
    if word == k || word == v return Nullable{Tuple{AbstractString, AbstractString}}(k, v) end
  end

  Nullable{Tuple{AbstractString, AbstractString}}()
end

irregular_nouns = Array{Tuple{AbstractString, AbstractString},1}([
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