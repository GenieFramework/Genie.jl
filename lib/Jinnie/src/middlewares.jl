function req_logger(app, req)
	log(req)
	return app(req)
end