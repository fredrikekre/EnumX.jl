# SPDX-License-Identifier: MIT

module EnumX

export @enumx

abstract type Enum{T} <: Base.Enum{T} end

@noinline panic(x) = throw(ArgumentError(x))

"""
    @enumx

Macro for generating an enum type with instances.

`@enumx` can be used as a drop in replacement for `@enum` from `Base`, but have several
improvements. See the [README](https://github.com/fredrikekre/EnumX.jl) or the module
docstring (`?EnumX` in the REPL) for more details.

# Examples
```julia
julia> @enumx Fruit Apple Banana

julia> Fruit.T
Enum type Fruit.T <: Enum{Int32} with 2 instances:
 Fruit.Apple  = 0
 Fruit.Banana = 1

julia> Fruit.Apple
Fruit.Apple = 0
```
"""
macro enumx(args...)
    return enumx(__module__, Any[args...])
end

function symbol_map end

function enumx(_module_, args)
    T = :T
    if length(args) > 1 && Meta.isexpr(args[1], :(=), 2) && args[1].args[1] === :T &&
            (args[1].args[2] isa Symbol || args[1].args[2] isa QuoteNode)
        T = args[1].args[2]
        T isa QuoteNode && (T = T.value)
        popfirst!(args) # drop T=...
    end
    name = popfirst!(args)
    if name isa Symbol
        modname = name
        baseT = Int32
    elseif Meta.isexpr(name, :(::), 2) && name.args[1] isa Symbol
        modname = name.args[1]
        baseT = Core.eval(_module_, name.args[2])
    else
        panic("invalid EnumX.@enumx type specification: $(name).")
    end
    name = modname
    if length(args) == 1 && Meta.isexpr(args[1], :block)
        syms = args[1].args
    else
        syms = args
    end
    name_value_map = Vector{Pair{Symbol, baseT}}()
    doc_entries = Vector{Pair{Symbol, Expr}}()
    next = zero(baseT)
    first = true
    for s in syms
        s isa LineNumberNode && continue
        # Handle doc expressions
        doc_expr = nothing
        if Meta.isexpr(s, :macrocall, 4) && s.args[1] isa GlobalRef && s.args[1].mod === Core &&
                s.args[1].name === Symbol("@doc")
            doc_expr = s
            s = s.args[4]
        end
        if s isa Symbol
            if !first && next == typemin(baseT)
                panic("value overflow for Enum $(modname): $(modname).$(s) = $(next).")
            end
            sym = s
        elseif Meta.isexpr(s, :(=), 2) && s.args[1] isa Symbol
            if s.args[2] isa Symbol &&
                    (i = findfirst(x -> x.first === s.args[2], name_value_map); i !== nothing)
                @assert name_value_map[i].first === s.args[2]
                nx = name_value_map[i].second
            else
                nx = Core.eval(_module_, s.args[2])
            end
            if !(nx isa Integer && typemin(baseT) <= nx <= typemax(baseT))
                panic(
                    "invalid value for Enum $(modname){$(baseT)}: " *
                        "$(modname).$(s.args[1]) = $(repr(nx))."
                )
            end
            next = convert(baseT, nx)
            sym = s.args[1]
        else
            panic("invalid EnumX.@enumx entry: $(s)")
        end
        if sym === T
            panic("instance name $(modname).$(sym) reserved for the Enum typename.")
        end
        if (idx = findfirst(x -> x.first === sym, name_value_map); idx !== nothing)
            v = name_value_map[idx].second
            panic(
                "duplicate name for Enum $(modname): $(modname).$(sym) = $(next)," *
                    " name already used for $(modname).$(sym) = $(v)."
            )
        end
        push!(name_value_map, sym => next)
        if doc_expr !== nothing
            # Replace the documented expression since it might be :(Apple = ...)
            doc_expr.args[4] = sym
            push!(doc_entries, sym => doc_expr)
        end

        next += oneunit(baseT)
        first = false
    end
    value_name_map = Dict{baseT, Symbol}(v => k for (k, v) in reverse(name_value_map))
    module_block = quote
        primitive type $(T) <: Enum{$(baseT)} $(sizeof(baseT) * 8) end
        let value_name_map = $(value_name_map)
            check_valid(x) = x in keys(value_name_map) ||
                throw(ArgumentError("invalid value for Enum $($(QuoteNode(modname))): $(x)."))
            global function $(esc(T))(x::Integer)
                check_valid(x)
                return Base.bitcast($(esc(T)), convert($(baseT), x))
            end
            Base.Enums.namemap(::Base.Type{$(esc(T))}) = value_name_map
            Base.Enums.instances(::Base.Type{$(esc(T))}) =
                ($([esc(k) for (k, v) in name_value_map]...),)
            EnumX.symbol_map(::Base.Type{$(esc(T))}) = $(name_value_map)
        end
    end
    if VERSION >= v"1.11.0-DEV.469"
        push!(
            module_block.args,
            esc(Expr(:public, values(value_name_map)...))
        )
    end
    for (k, v) in name_value_map
        push!(
            module_block.args,
            Expr(:const, Expr(:(=), esc(k), Expr(:call, esc(T), v)))
        )
    end
    for (_, v) in doc_entries
        push!(module_block.args, v)
    end
    # Document the module and the type
    mdoc = Expr(:block, Expr(:meta, :doc), esc(modname))
    # TODO: Attach to the type too?
    # Tdoc = Expr(:block, Expr(:meta, :doc), Expr(:., esc(modname), QuoteNode(T)))
    return Expr(:toplevel, Expr(:module, false, esc(modname), module_block), mdoc, #=Tdoc,=# nothing)
end

function Base.show(io::IO, ::MIME"text/plain", x::E) where {E <: Enum}
    iob = IOBuffer()
    ix = Integer(x)
    found = false
    for (k, v) in symbol_map(E)
        if v == ix
            print(iob, "$(nameof(parentmodule(E))).$(k) = ")
            found = true
        end
    end
    if !found
        print(iob, "$(nameof(parentmodule(E))).#invalid# = ")
    end
    show(iob, ix)
    write(io, seekstart(iob))
    return nothing
end
function Base.show(io::IO, ::MIME"text/plain", ::Type{E}) where {E <: Enum}
    if !isconcretetype(E) # handle EnumX.Enum and EnumX.Enum{T}
        invoke(show, Tuple{IO, Type}, io, E)
        return
    end
    iob = IOBuffer()
    insts = Base.Enums.instances(E)
    n = length(insts)
    stringmap = Pair{String, Base.Enums.basetype(E)}[
        string("$(nameof(parentmodule(E))).", k) => v for (k, v) in symbol_map(E)
    ]
    mx = maximum(x -> textwidth(x.first), stringmap; init = 0)
    print(
        iob,
        "Enum type $(nameof(parentmodule(E))).$(nameof(E)) <: ",
        "Enum{$(Base.Enums.basetype(E))} with $(n) instance$(n == 1 ? "" : "s")$(n > 0 ? ":" : "")"
    )
    for (k, v) in stringmap
        print(iob, "\n ", rpad(k, mx), " = ")
        show(iob, v)
    end
    write(io, seekstart(iob))
    return nothing
end

end # module EnumX
