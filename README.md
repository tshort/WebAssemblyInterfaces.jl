# WebAssemblyInterfaces

[![Build Status](https://github.com/tshort/WebAssemblyInterfaces.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/tshort/WebAssemblyInterfaces.jl/actions/workflows/CI.yml?query=branch%3Amain)

NOTE: This is still experimental, and not all features have been tested with WebAssembly.

This is a small package to write out definitions in JavaScript that correspond to Julia types and object definitions. This JavaScript code is meant to be used with the [wasm-ffi](https://github.com/DeMille/wasm-ffi/tree/master) package, a great package for interfacing between JavaScript and WebAssembly. This allows JavaScript to read and write to memory that is shared by the Julia code (after being compiled to WebAssembly). The [wasm-ffi](https://github.com/DeMille/wasm-ffi/tree/master) package writes to the same memory layout used by Julia.

The following types are supported:
* Structs, tuples, named tuples
* Concrete types that include: Bool, Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64, Float32, and Float64 

Functions and other types that don't have a size are not written. For vectors, the `MallocVector` type from [StaticTools](https://github.com/brenhinkeller/StaticTools.jl) works with the `ffi.rust.vector` type in wasm-ffi. The memory layouts do not match exactly, but it works for some uses.

`wasm-ffi` performs allocations when objects are created on the JavaScript side. It is also possible to do allocation on the Julia side. The WebAssembly file needs to include `allocate` and `free` functions.

Three functions are provided:

* `js_types(T)`: Return a string with the JavaScript definition of type `T`.
* `js_def(x)`: Return a string with the JavaScript code to define object `x`.
* `js_repr(x)`: Return a string with the JavaScript code with the types and the code to define `x`.

Here is an example of Julia code that defines a custom type and generates JavaScript interfacing code.

```jl
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

using WebAssemblyInterfaces

print(js_repr(x))
```

Here is the JavaScript code that is printed:
```js

```

Here is a Julia function that could operate on this object. This can be compiled with [StaticCompiler](https://github.com/tshort/StaticCompiler.jl). The Julia code can read data from the object passed in, and it can write to this object in memory.

```jl
function f(x)
    x.a = x.b[2] * x.c[3]
    return x.c[1] + x.b.c[1]
end

# Compile it to WebAssembly:
using StaticCompiler
wasm_path = compile_wasm(f, Tuple{typeof(x)}, flags = `walloc.o`)

```

### Still in Progress

* Should we include a copy of `wasm-ffi.browser.js`? It makes sense if we add support for more Julia types.
* Figure out where `walloc.o` should live.
