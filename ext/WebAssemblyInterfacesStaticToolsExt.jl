module WebAssemblyInterfacesStaticToolsExt

using WebAssemblyInterfaces, StaticTools

function WebAssemblyInterfaces.definition_repr(
        ctx::WebAssemblyInterfaces.Context, 
        ::Type{<:MallocArray{T,N}}) where {T,N}
    string("ffi.julia.MallocArray(", 
           WebAssemblyInterfaces.definition_repr(ctx, T), ", ", N, ")")
end 

function WebAssemblyInterfaces.js_def(
        x::MallocArray{T,N}; 
        ctx = WebAssemblyInterfaces.Context()) where {T,N}
    string("new ffi.julia.MallocArray(", 
           WebAssemblyInterfaces.definition_repr(ctx, T), ", ", N, ", [", 
           (string(js_def(v; ctx), ", ") for v in x)..., "])")
end 

end # module