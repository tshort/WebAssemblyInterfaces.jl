# using TestEnv
# TestEnv.activate("WebAssemblyInterfaces")
# using Pkg
# Pkg.develop("StaticCompiler")


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

f_x3(x)   = @inbounds x.x[3]
f_ya(x)   = @inbounds x.y.a
f_yb2(x)  = @inbounds x.y.b[2]
f_zx3(x)  = @inbounds x.z.x[3]
f_zy3(x)  = @inbounds x.z.y[3]
f_test(x) = @inbounds x.x[4] == x.y.a == 4x.y.b[2,3,4] == x.z.y[4]

compile_wasm(
    (
      (f_ya,   Tuple{WT}),
      (f_x3,   Tuple{WT}),
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
  console.log(library.f_x3(w))
  console.log(library.f_ya(w))
  console.log(library.f_yb2(w))
  console.log(library.f_zx3(w))
  console.log(library.f_zy3(w))
  console.log(library.f_test(w))
  x3   = library.f_x3(w)
  ya   = library.f_ya(w)
  yb2  = library.f_yb2(w)
  zx3  = library.f_zx3(w)
  zy3  = library.f_zy3(w)
  test = library.f_test(w)
  console.log(x3   == $(f_x3(w)))
  console.log(ya   == $(f_ya(w)))
  console.log(yb2  == $(f_yb2(w)))
  console.log(zx3  == $(f_zx3(w)))
  console.log(zy3  == $(f_zy3(w)))
  console.log(test == $(f_test(w)))
  console.log(x3)
  console.log(ya)
  console.log(yb2)
  console.log(zx3)
  console.log(zy3)
  console.log(test)
})
"""
println(js)

# using NodeCall
# NodeCall.initialize();
# p = node_eval(js)
# @await p
# @test node"library.f_test(w)" == 1
# @eval for f in (f_x3, f_ya, f_yb2, f_zx3, f_zy3)
#     @test f(w) == node_eval("library.$f(w)")
# end


@test f_test(w)

using NodeJS

@show jsresult = read(`$(nodejs_cmd()) -e $js`, String)

@test contains(jsresult, "true\ntrue\ntrue\ntrue\ntrue")
