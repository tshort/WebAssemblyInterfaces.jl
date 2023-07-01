using StaticTools
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

jsz = sizeof(Int) * 8

x = X(Int64(2), Y(1.1, Int64(2), (Int64(1), 1.1)), Y(Int64(1), Int64(2), Int64(3)))

SZ = Int == Int32 ? 32 : 64

@testset "Basics" begin

s = js_repr(x)

@test contains(s, """
var Y = ffi.julia$SZ.Struct({
    a: 'f64',
    b: 'int64',
    c: ffi.julia$SZ.Tuple(['int64','f64']),
});
""")

@test contains(s, """
new X({
a: 2,
b: new Y({
a: 1.1,
b: 2,
c: new ffi.julia$SZ.Tuple(['int64','f64'], [1, 1.1]),
}),
c: new YInt64_Int64_Int64({
a: 1,
b: 2,
c: 3,
}),
})
""")


s = js_repr(ones(3,2))

@test contains(s, string("new ffi.julia$SZ.Array('f64', 2, [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, ], [3, 2])"))

s = js_repr(MallocArray(ones(3)))

@test contains(s, string("new ffi.julia$SZ.MallocArray('f64', 1, [1.0, 1.0, 1.0, ])"))


# More sophisticated tests could use NodeJS.jl to run some JavaScript/WebAssembly.

end

@testset "WebAssembly" begin
    include("test-wasm.jl")
end
