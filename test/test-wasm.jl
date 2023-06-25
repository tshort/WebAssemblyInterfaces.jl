using TestEnv
TestEnv.activate("WebAssemblyInterfaces")
using Pkg
Pkg.develop("StaticCompiler")

using Test


using StaticCompiler, StaticTools
using WebAssemblyInterfaces

struct W{X,Y,Z} 
    x::X
    y::Y
    z::Z
end

# Note that we avoid Int64's here because JavaScript doesn't handle them well. 
# WebAssembly does, though, so if you don't need to interchange integers, Int64's are fine.

w = W([Int32(1):Int32(10);], (a = 4.0, b = ones(2, 3, 4)), W([10.0:-1:1;], [1.0:10;], 1.0))
WT = typeof(w)

f_x3(x)   = x.x[3]
f_ya(x)   = x.y.a
f_yb2(x)  = x.y.b[2]
f_zx3(x)  = x.z.x[3]
f_zy3(x)  = x.z.y[3]
f_test(x) = x.x[4] == x.y.a == 4x.y.b[2,3,4] == x.z.y[4]

compile_wasm(
    ((f_x3,   Tuple{WT}),
     (f_ya,   Tuple{WT}),
     (f_yb2,  Tuple{WT}),
     (f_zx3,  Tuple{WT}),
     (f_zy3,  Tuple{WT}),
     (f_test, Tuple{WT})),
    flags = `--allow-undefined --unresolved-symbols=ignore-all walloc.o`, filename = "test-wasm")
# compile_wasm(
#     f_zy3,   Tuple{WT},
#     flags = `--allow-undefined --unresolved-symbols=ignore-all walloc.o`, filename = "test-zx3")
    
w_types = js_types(WT)
w_def = js_def(w)


js = """
var ffi = require("../wasm-ffi/dist/wasm-ffi.bundle.js");

$w_types

var w = $w_def

var library = new ffi.Wrapper({
  f_x3:   ['number', [W]],
  f_ya:   ['number', [W]],
  f_yb2:  ['number', [W]],
  f_zx3:  ['number', [W]],
  f_zy3:  ['number', [W]],
  f_test: ['number', [W]],
}, {debug: true});

library.imports(wrap => ({
  env: {
    memory: new WebAssembly.Memory({ initial: 20 }),
    ijl_bounds_error_ints: function(x) {console.log(x)},
    ijl_apply_generic: function() {},
    ijl_throw: function() {},
  },
}));
library.fetch("./test-wasm.wasm").then(() => {
  x3   = library.f_x3(w)
  ya   = library.f_ya(w)
  yb2  = library.f_yb2(w)
  zx3  = library.f_zx3(w)
  zy3  = library.f_zy3(w)
  test = library.f_test(w)
})
"""
println(js)

using NodeCall
NodeCall.initialize();
p = node_eval(js)

@await p

@test f_test(w)
@test node"library.f_test(w)" == 1

@eval for f in (f_x3, f_ya, f_yb2, f_zx3, f_zy3)
    @test f(w) == node_eval("library.$f(w)")
end