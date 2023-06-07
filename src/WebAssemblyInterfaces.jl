module WebAssemblyInterfaces

export js_repr, js_types, js_def

function fixname(s)
    # JS names have to be letter, numbers, or underscore
    replace(string(s), r"[^a-zA-Z0-9_]" => s"_")
end

BuiltinTypes = Union{Bool, Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64, Float32, Float64} 

const default_map = Dict{Type,String}()
for T in (Bool, Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64) 
    default_map[T] = string("'", lowercase(repr(T)), "'")
end
default_map[Float32] = "'f32'"
default_map[Float64] = "'f64'"

struct Context
    type_map::Dict{Type,String}
    new_types::Vector{String}
end
Context(; type_map = copy(default_map), new_types = String[]) = Context(type_map, new_types)

function definition_repr(ctx::Context, x::AbstractVector{T}) where T 
    string("[", definition_repr(ctx, x[1]), ", ", length(x), "]")
end

tname(::Type{T}) where {T} = string(nameof(T), join(T.parameters, "_"))

function definition_repr(ctx::Context, x::Type{T}) where T
    if haskey(ctx.type_map, T)
        return ctx.type_map[T]
    end 
    # if isconcretetype(T) && !ismutabletype(T)
        name = fixname(nameof(T))
        collect(values(ctx.type_map))
        if name in values(ctx.type_map)
            name = fixname(tname(T))
        end
        ctx.type_map[T] = name
        s = string("const ", name, " = new ffi.Struct({\n")
        for i in 1:fieldcount(T)
            FT = fieldtype(T, i)
            sz = try sizeof(FT) catch; sizeof(Int) end
            if sz > 0
                if ismutabletype(FT)
                    FT = Base.RefValue{FT}
                end
                s *= string("    ", 
                            fixname(string(fieldname(T, i))), ": ", 
                            get(ctx.type_map, FT, definition_repr(ctx, FT)),
                            ",\n")
            end
        end
        s *= "});\n"
        push!(ctx.new_types, s)
        return name
    # end
end

function definition_repr(ctx::Context, ::Type{NTuple{N, T}}) where {N,T}
    string("[", definition_repr(ctx, T), ", ", N, "]")
end 

function definition_repr(ctx::Context, T::Type{<:Tuple})
    string("ffi.julia.Tuple([", join((definition_repr(ctx, p) for p in T.parameters), ","), "])")
end 

function definition_repr(ctx::Context, ::Type{Base.RefValue{T}}) where T
    string("ffi.julia.pointer(", definition_repr(ctx, T), ")")
end 

function definition_repr(ctx::Context, ::Type{<:Enum})  # kludge for now
    string("'int32'")
end 

function definition_repr(ctx::Context, ::Type{<:Array{T,N}}) where {T,N}
    string("ffi.julia.Array(", definition_repr(ctx, T), ", ", N, ")")
end 


function js_types(T::Type; ctx = Context())
    definition_repr(ctx, T)
    return join(ctx.new_types, "\n")
end

function js_def(x::T; ctx = Context()) where T
    typename = definition_repr(ctx, T)
    s = string("new ", typename, "({\n")
    for i in 1:fieldcount(T)
        FT = fieldtype(T, i)
        sz = try sizeof(FT) catch; sizeof(Int) end
        if sz > 0
            val = getfield(x, i)
            if ismutabletype(FT)
                val = Ref(val)
            end
            s *= string(fixname(string(fieldname(T, i))), ": ", 
                        js_def(val, ctx = ctx),
                        ",\n")
        end
    end
    s *= "})"
    return s
end

js_def(x::T; args...) where T <: Union{BuiltinTypes} = x

function js_def(x::NTuple{N,T}; ctx = Context()) where {N,T}
    string("[", join(string.(x), ","), "]")
end

function js_def(x::Base.RefValue{T}; ctx = Context()) where T
    string("new ffi.Pointer(", definition_repr(ctx, T), ", ", js_def(x[]; ctx), ")")
end

function js_def(x::T; ctx = Context()) where T <: Tuple
    string("new ffi.julia.Tuple([", 
           join((definition_repr(ctx, p) for p in T.parameters), ","), "], [",
           join((js_def(z; ctx) for z in x), ", "), "])")
end

function js_def(x::Enum; ctx = Context())  # kludge for now
    Int32(x)
end 

function js_def(x::Array{T,N}; ctx = Context()) where {T,N}
    string("new ffi.julia.Array(", definition_repr(ctx, T), ", ", N, ", [", 
           (string(js_def(v; ctx), ", ") for v in x)..., "]", N > 1 ? string(", ", [size(x)...], ")") : ")")
end 

function js_repr(x)
    ctx = Context()
    string(
        js_types(typeof(x); ctx),
        "\n",
        js_def(x; ctx),
        "\n",
    )
end




end
