using Debug
using Logging

Logging.configure(level=DEBUG)

function a()
  :a
end

function b()
  Logging.info("b")
  :b
end

@debug function c()
  :c 
end

a()
b()
c()