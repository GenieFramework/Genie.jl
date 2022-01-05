"""
AMQP functionality for Genie.
"""
module AMQP
using AMQP 
import Genie, Logging


function getconnection(port::Int = Genie.config.AMQP_PORT,  user::String = Genie.config.AMQP_USER, password::String = Genie.config.AMQP_PASSWORD, virtualhost::String = Genie.config.AMQP_VIRTUALHOST, host::String = Genie.config.AMQP_HOST)
    try
        auth_params = Dict{String,Any}("MECHANISM"=>"AMQPLAIN", "LOGIN"=>user, "PASSWORD"=>password)
        conn = Connection(;virtualhost=virtualhost, host=host,port=port,auth_params=auth_params)  
        @info conn
    catch(e)
        @error "Failed parsing `server` parameter info."
        @error ex
    end
end