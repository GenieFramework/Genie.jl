using Logging

@Logging.configure(level=DEBUG)

file_logger = Logger("file_logger")
Logging.configure(file_logger, level=DEBUG)
Logging.configure(file_logger, filename = joinpath("log", "jinnie.log"))

push!(loggers, file_logger)