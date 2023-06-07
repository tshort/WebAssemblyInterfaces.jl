# WebAssemblyInterfaces

[![Build Status](https://github.com/tshort/WebAssemblyInterfaces.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/tshort/WebAssemblyInterfaces.jl/actions/workflows/CI.yml?query=branch%3Amain)

NOTE: This is still experimental, and not all features have been tested with WebAssembly.

For a working example, see this [Lorenz Attraction App in Julia](http://tshort.github.io/Lorenz-WebAssembly-Model.jl). 

This is a small package to write out definitions in JavaScript that correspond to Julia types and object definitions. This JavaScript code is meant to be used with the [wasm-ffi](https://github.com/DeMille/wasm-ffi/) package, a great package for interfacing between JavaScript and WebAssembly. This allows JavaScript to read and write to memory that is shared by the Julia code (after being compiled to WebAssembly). The [wasm-ffi](https://github.com/DeMille/wasm-ffi/) package writes to the same memory layout used by Julia.

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
const Y = new ffi.Struct({
    a: 'f64',
    b: 'int64',
    c: ffi.julia.Tuple(['int64','f64']),
});

const YInt64_Int64_Int64 = new ffi.Struct({
    a: 'int64',
    b: 'int64',
    c: 'int64',
});

const X = new ffi.Struct({
    a: 'int64',
    b: Y,
    c: YInt64_Int64_Int64,
});

new X({
a: 2,
b: new Y({
a: 1.1,
b: 2,
c: new ffi.julia.Tuple(['int64','f64'], [1, 1.1]),
}),
c: new YInt64_Int64_Int64({
a: 1,
b: 2,
c: 3,
}),
})
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

### wasm-ffi

This repository also contains distribution code for the [wasm-ffi](https://github.com/DeMille/wasm-ffi/) package from [this fork](https://github.com/tshort/wasm-ffi/). This includes extensions for supporting Julia code. That includes:
* `ffi.julia.Array`
* `ffi.julia.MallocArray`
* `ffi.julia.Tuple`

The default assumes a 64-bit version of Julia. This means that pointers and Ints are 64 bits. You can pass 
`{ dialect: 'julia32' }` as the second argument (options) to `ffi.Wrapper`. `debug: true` is also a useful 
option to monitor WebAssembly allocations.

### Options going forward

* We include a copy of `wasm-ffi.browser.js`. Can we make it easier to use?

* Figure out where `walloc.o` should live. Should we add object code from other sources to make WebAssembly easier?

* We could create and package a set of method overrides for StaticCompiler that are targeted at WebAssembly. We could also develop Mixtape passes to be able to compile more code.
