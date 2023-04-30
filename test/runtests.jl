using WebAssemblyInterfaces
using Test

mutable struct X{A,B,C}
    a::A
    b::B
    c::C
end

struct Y{A,B,C}
    a::A
    b::B
    c::C
end

x = X(2, Y(1.1, 2, (1, 1.1)), Y(1, 2, 3))


@testset "Basics" begin

s = js_repr(x)
print(s)

# More sophisticated tests could use NodeJS.jl to run some JavaScript/WebAssembly.

end
