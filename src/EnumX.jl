# SPDX-License-Identifier: MIT

module EnumX

export @enumx

abstract type Enum{T} <: Base.Enum{T} end

macro enumx(args...)
    return enumx(__module__, args...)
end

function enumx(_module_, name, args...)
    if name isa Symbol
        modname = name
        baseT = Int32
    elseif name isa Expr && name.head == :(::) && name.args[1] isa Symbol && length(name.args) == 2
        modname = name.args[1]
        baseT = Core.eval(_module_, name.args[2])
    else
        throw(ArgumentError("invalid EnumX.@enumx type specification: $(name)"))
    end
    name = modname
    namemap = Dict{baseT,Symbol}()
    next = 0
    for arg in args
        @assert arg isa Symbol # TODO
        namemap[next] = arg
        next += 1
    end
    module_block = quote
        primitive type Type <: Enum{$(baseT)} $(sizeof(baseT) * 8) end
        let namemap = $(namemap)
            check_valid(x) = x in keys(namemap) ||
                throw(ArgumentError("invalid value $(x) for Enum $($(QuoteNode(modname)))"))
            global function $(esc(:Type))(x::Integer)
                check_valid(x)
                return Base.bitcast($(esc(:Type)), convert($(baseT), x))
            end
            Base.Enums.namemap(::Base.Type{$(esc(:Type))}) = namemap
            Base.Enums.instances(::Base.Type{$(esc(:Type))}) =
                ($([esc(k) for k in values(namemap)]...),)
        end
    end
    for (k, v) in namemap
        push!(module_block.args,
            Expr(:const, Expr(:(=), esc(v), Expr(:call, esc(:Type), k)))
        )
    end
    return Expr(:toplevel, Expr(:module, false, esc(modname), module_block), nothing)
end

function Base.show(io::IO, ::MIME"text/plain", x::E) where E <: Enum
    print(io, "$(nameof(parentmodule(E))).$(Symbol(x)::Symbol) = $(Integer(x))")
    return nothing
end
function Base.show(io::IO, ::MIME"text/plain", ::Base.Type{E}) where E <: Enum
    iob = IOBuffer()
    insts = Base.Enums.instances(E)
    n = length(insts)
    stringmap = Dict{String, Int32}(
        string("$(nameof(parentmodule(E))).", v) => k for (k, v) in Base.Enums.namemap(E)
    )
    mx = maximum(textwidth, keys(stringmap); init = 0)
    print(iob, "Enum type $(nameof(parentmodule(E))).Type <: Enum{$(Base.Enums.basetype(E))} with $(n) instance$(n == 1 ? "" : "s"):")
    for (k, v) in stringmap
        print(iob, "\n", rpad(k, mx), " = $(v)")
    end
    write(io, seekstart(iob))
    return nothing
end

end # module EnumX
