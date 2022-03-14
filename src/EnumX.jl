# SPDX-License-Identifier: MIT

module EnumX

export @enumx

abstract type Enum{T} <: Base.Enum{T} end

@noinline panic(x) = throw(ArgumentError(x))
@noinline panic() = error("unreachable")

macro enumx(args...)
    return enumx(__module__, args...)
end

function symbol_map end

function enumx(_module_, name, args...)
    if name isa Symbol
        modname = name
        baseT = Int32
    elseif name isa Expr && name.head == :(::) && name.args[1] isa Symbol &&
           length(name.args) == 2
        modname = name.args[1]
        baseT = Core.eval(_module_, name.args[2])
    else
        panic("invalid EnumX.@enumx type specification: $(name).")
    end
    name = modname
    if length(args) == 1 && args[1] isa Expr && args[1].head === :block
        syms = args[1].args
    else
        syms = args
    end
    name_value_map = Vector{Pair{Symbol, baseT}}()
    next = zero(baseT)
    for s in syms
        s isa LineNumberNode && continue
        local sym
        if s isa Symbol
            if next == typemin(baseT)
                panic("value overflow for Enum $(modname): $(modname).$(s) = $(next).")
            end
            sym = s
        elseif s isa Expr && s.head === :(=) && s.args[1] isa Symbol && length(s.args) == 2
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
        if (idx = findfirst(x -> x.first === sym, name_value_map); idx !== nothing)
            v = name_value_map[idx].second
            panic(
                "duplicate name for Enum $(modname): $(modname).$(sym) = $(next)," *
                " name already used for $(modname).$(sym) = $(v)."
            )
        end
        push!(name_value_map, sym => next)

        next += oneunit(baseT)
    end
    value_name_map = Dict{baseT,Symbol}(v => k for (k, v) in reverse(name_value_map))
    module_block = quote
        primitive type Type <: Enum{$(baseT)} $(sizeof(baseT) * 8) end
        let value_name_map = $(value_name_map)
            check_valid(x) = x in keys(value_name_map) ||
                throw(ArgumentError("invalid value for Enum $($(QuoteNode(modname))): $(x)."))
            global function $(esc(:Type))(x::Integer)
                check_valid(x)
                return Base.bitcast($(esc(:Type)), convert($(baseT), x))
            end
            Base.Enums.namemap(::Base.Type{$(esc(:Type))}) = value_name_map
            Base.Enums.instances(::Base.Type{$(esc(:Type))}) =
                ($([esc(k) for (k,v) in name_value_map]...),)
            EnumX.symbol_map(::Base.Type{$(esc(:Type))}) = $(name_value_map)
        end
    end
    for (k, v) in name_value_map
        push!(module_block.args,
            Expr(:const, Expr(:(=), esc(k), Expr(:call, esc(:Type), v)))
        )
    end
    return Expr(:toplevel, Expr(:module, false, esc(modname), module_block), nothing)
end

function Base.show(io::IO, ::MIME"text/plain", x::E) where E <: Enum
    iob = IOBuffer()
    ix = Integer(x)
    for (k, v) in symbol_map(E)
        if v == ix
            print(iob, "$(nameof(parentmodule(E))).$(k) = ")
        end
    end
    print(iob, "$(Integer(x))")
    write(io, seekstart(iob))
    return nothing
end
function Base.show(io::IO, ::MIME"text/plain", ::Base.Type{E}) where E <: Enum
    iob = IOBuffer()
    insts = Base.Enums.instances(E)
    n = length(insts)
    stringmap = Dict{String, Int32}(
        string("$(nameof(parentmodule(E))).", k) => v for (k, v) in symbol_map(E)
    )
    mx = maximum(textwidth, keys(stringmap); init = 0)
    print(iob,
        "Enum type $(nameof(parentmodule(E))).Type <: ",
        "Enum{$(Base.Enums.basetype(E))} with $(n) instance$(n == 1 ? "" : "s"):"
    )
    for (k, v) in stringmap
        print(iob, "\n ", rpad(k, mx), " = $(v)")
    end
    write(io, seekstart(iob))
    return nothing
end

end # module EnumX
