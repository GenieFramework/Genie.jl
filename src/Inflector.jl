"""
Handles the functionality for applying various gramatical rules.
"""
module Inflector

import Unicode
import Genie

const vowels = ["a", "e", "i", "o", "u"]


"""
    to_singular(word::String; is_irregular::Bool = false) :: Union{Nothing,String}

Returns the singural form of `word`.
"""
function to_singular(word::String; is_irregular::Bool = Inflector.is_irregular(word)) :: Union{Nothing,String}
  ( is_irregular || !endswith(word, "s") ) && return to_singular_irregular(word)
  endswith(word, "ies") && !in(word[end-3], vowels) && return (word[1:end-3] * "y")
  endswith(word, "s") && return (word[1:end-1])

  nothing
end


"""
    to_singular_irregular(word::String) :: Union{Nothing,String}

Returns the singular form of the irregular word `word`.
"""
function to_singular_irregular(word::String) :: Union{Nothing,String}
  irr = irregular(word)
  !isnothing(irr) ? (irr)[1] : nothing
end


"""
    to_plural(word::String; is_irregular::Bool = false) :: Union{Nothing,String}

Returns the plural form of `word`.
"""
function to_plural(word::String; is_irregular::Bool = Inflector.is_irregular(word)) :: Union{Nothing,String}
  is_irregular && return to_plural_irregular(word)
  endswith(word, "y") && !in(word[end-1], vowels) && return (word[1:end-1] * "ies") # category -> categories // story -> stories
  is_singular(word) ? (word * "s") : (word)
end


"""
    to_plural_irregular(word::String) :: Union{Nothing,String}

Returns the plural form of the irregular word `word`.
"""
function to_plural_irregular(word::String) :: Union{Nothing,String}
  irr = irregular(word)
  !isnothing(irr) ? (irr)[2] : nothing
end


"""
    from_underscores(word::String) :: String

Generates `SnakeCase` form of `word` from `underscore_case`.
"""
function from_underscores(word::String, underscore::String = "_") :: String
  mapreduce(x -> uppercasefirst(x), *, split(word, underscore))
end


"""
    is_singular(word::String) :: Bool

Returns wether or not `word` is a singular.
"""
function is_singular(word::String) :: Bool
  !is_plural(word)
end


"""
    is_plural(word::String) :: Bool

Returns wether or not `word` is a plural.
"""
function is_plural(word::String) :: Bool
  word = Unicode.normalize(word, casefold = true)
  irr_word = irregular(word)
  (isnothing(irr_word) || word != (irr_word)[1]) ||
    (isnothing(irr_word) || word == (irr_word)[2]) ||
    endswith(word, "s")
end


"""
    irregulars() :: Vector{Tuple{String,String}}

Returns a `vector` of words with irregular singular or plural forms.
"""
function irregulars() :: Vector{Tuple{String,String}}
  vcat(IRREGULAR_NOUNS, Genie.config.inflector_irregulars)
end


"""
    irregular(word::String) :: Union{Nothing,Tuple{String,String}}

Wether or not `word` has an irregular singular or plural form.
"""
function irregular(word::String) :: Union{Nothing,Tuple{String,String}}
  word = Unicode.normalize(word, casefold = true)

  for (k, v) in IRREGULAR_NOUNS
    (word == k || word == v) && return (k::String,v::String)
  end

  nothing
end


"""
    function is_irregular(word::String) :: Bool

Whether or not `word` has a singular or plural irregular form.
"""
function is_irregular(word::String) :: Bool
  !isnothing(irregular(word))
end


"""
Vector of nouns with irregular forms of singular and/or plural.
Each tuple contains pairs of singular and plural forms.
"""
const IRREGULAR_NOUNS = Vector{Tuple{String,String}}([
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
  ("mouse", "mice"),
  ("quiz", "quizzes"),
  ("search", "searches")
])
end
