type Foo 
  class::AbstractString
  Foo() = new("Foo")
end

module Foo

function tostring(f::Foo)
  f.class
end

end