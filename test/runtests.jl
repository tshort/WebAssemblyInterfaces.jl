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
println(s)

@test contains(s, """
const Y = new ffi.Struct({
    a: 'f64',
    b: 'int64',
    c: ffi.rust.tuple(['int64','f64']),
});
""")

@test contains(s, """
new X({
a: 2,
b: new Y({
a: 1.1,
b: 2,
c: new ffi.rust.tuple(['int64','f64'], [1, 1.1]),
}),
c: new YInt64_Int64_Int64({
a: 1,
b: 2,
c: 3,
}),
})
""")

# More sophisticated tests could use NodeJS.jl to run some JavaScript/WebAssembly.

end
