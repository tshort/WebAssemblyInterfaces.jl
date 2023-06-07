# wasm-ffi
#### A lightweight foreign function interface library for JavaScript & WebAssembly

This is a fork of Sterling DeMille's awesome [wasm-ffi](https://github.com/DeMille/wasm-ffi) package.

It provides the following extensions for Julia code:

* `ffi.julia.Array64`
* `ffi.julia.Array32`  (not done, yet)
* `ffi.julia.Tuple`
* `ffi.julia.MallocArray64`     (from [StaticTools](https://github.com/brenhinkeller/StaticTools.jl))
* `ffi.julia.MallocArray32`  (not done, yet)

The `32` and `64` indicate whether the pointers and integers involved are 32 or 64 bits. Match these to the version of Julia you are using. It also includes `ffi.types.pointer64` for use on 64-bit versions of Julia in place of `ffi.types.pointer`.

Here is an example of how to initialize an array in JavaScript. 
```js
var N = 100;
var x  = new ffi.julia.Array('f64', 1, new Float64Array(N));
```
The arguments are:

* Element type: `'f64'`  
* Number of dimensions: `1`
* A JavaScript typed array to hold the contents: `new Float64Array(N)`

Here is the JavaScript type definition for the variable `x`.

```js
ffi.julia.Array(`f64`, 1)
```

For multidimensional arrays, another argument at the end is needed to specify `size`:

```js
var y  = new ffi.julia.Array('f64', 2, new Float64Array(6), [2,3]);
```


To build the packaged JavaScript files, run `npx webpack` in this folder. 
To initialize NPM stuff, run `npm install`.

