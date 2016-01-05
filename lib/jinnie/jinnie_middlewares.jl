module Jinnie_Middlewares

using Jinnie_Logger

function req_logger(app, req)
	Jinnie_Logger.req(req)
	return app(req)
end

end
