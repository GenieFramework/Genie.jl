using Logging

# @Logging.configure(level=DEBUG)
# @info "Logging ready"

console_logger = Logger("console_logger")
Logging.configure(console_logger, level = DEBUG)
Logging.configure(console_logger, output = STDOUT)

file_logger = Logger("file_logger")
Logging.configure(file_logger, level = DEBUG)
Logging.configure(file_logger, filename = joinpath("log", "jinnie.log"))

push!(loggers, console_logger)
push!(loggers, file_logger)