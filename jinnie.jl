#!/usr/local/bin/julia --color=yes
module App

push!(LOAD_PATH, abspath("lib/Jinnie/src"))

export config

using Configuration

const config = Config(output_length = 100) #, supress_output = true, debug_db = false, debug_requests = false, debug_responses = false)
using Jinnie

end