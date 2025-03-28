# SPDX-License-Identifier: MIT

using EnumX, Test

# Needed to "render" docstrings, see https://github.com/JuliaLang/julia/issues/54664
import REPL

const T16 = Int16
getInt64() = Int64
const Elppa = -1
const Ananab = -1

@testset "EnumX" begin

    # Basic
    @enumx Fruit Apple Banana

    @test Fruit isa Module
    @test_broken Set(names(Fruit; all = true)) == Set([:Fruit, :Apple, :Banana, :T])
    @test issubset(Set([:Fruit, :Apple, :Banana, :T]), Set(names(Fruit; all = true)))
    @test Fruit.T <: EnumX.Enum{Int32} <: Base.Enum{Int32}
    @test !@isdefined(Apple)
    @test !@isdefined(Banana)

    @test Fruit.Apple isa EnumX.Enum
    @test Fruit.Apple isa Base.Enum
    @test Fruit.Banana isa EnumX.Enum
    @test Fruit.Banana isa Base.Enum

    @test instances(Fruit.T) === (Fruit.Apple, Fruit.Banana)
    @test Base.Enums.namemap(Fruit.T) == Dict{Int32, Symbol}(0 => :Apple, 1 => :Banana)
    @test Base.Enums.basetype(Fruit.T) == Int32

    @test Symbol(Fruit.Apple) === :Apple
    @test Symbol(Fruit.Banana) === :Banana

    @test Integer(Fruit.Apple) === Int32(0)
    @test Int(Fruit.Apple) === Int(0)
    @test Integer(Fruit.Banana) === Int32(1)
    @test Int(Fruit.Banana) === Int(1)

    @test Fruit.Apple === Fruit.Apple
    @test Fruit.Banana === Fruit.Banana

    @test Fruit.T(Int32(0)) === Fruit.T(0) === Fruit.Apple
    @test Fruit.T(Int32(1)) === Fruit.T(1) === Fruit.Banana
    @test_throws ArgumentError("invalid value for Enum Fruit: 123.") Fruit.T(Int32(123))
    @test_throws ArgumentError("invalid value for Enum Fruit: 123.") Fruit.T(123)

    # Public enum member values (#11)
    if VERSION >= v"1.11.0-DEV.469"
        @test Set(names(Fruit)) == Set([:Fruit, :Apple, :Banana])
        @test Base.ispublic(Fruit, :Apple)
        @test Base.ispublic(Fruit, :Banana)
    else
        @test Set(names(Fruit)) == Set([:Fruit])
    end

    @test Fruit.Apple < Fruit.Banana

    let io = IOBuffer()
        write(io, Fruit.Apple)
        seekstart(io)
        @test read(io, Fruit.T) === Fruit.Apple
        seekstart(io)
        write(io, Fruit.Banana)
        seekstart(io)
        @test read(io, Fruit.T) === Fruit.Banana
        seekstart(io)
        write(io, Int32(123))
        seekstart(io)
        @test_throws ArgumentError("invalid value for Enum Fruit: 123.") read(io, Fruit.T)
    end

    let io = IOBuffer()
        show(io, "text/plain", Fruit.T)
        str = String(take!(io))
        @test str == "Enum type Fruit.T <: Enum{Int32} with 2 instances:\n Fruit.Apple  = 0\n Fruit.Banana = 1"
        show(io, "text/plain", Fruit.Apple)
        str = String(take!(io))
        @test str == "Fruit.Apple = 0"
        show(io, "text/plain", Fruit.Banana)
        str = String(take!(io))
        @test str == "Fruit.Banana = 1"
        show(io, "text/plain", EnumX.Enum)
        str = String(take!(io))
        @test str == "EnumX.Enum"
        show(io, "text/plain", EnumX.Enum{Int32})
        str = String(take!(io))
        @test str == "EnumX.Enum{Int32}"
    end


    # Base type specification
    @enumx Fruit8::Int8 Apple
    @test Fruit8.T <: EnumX.Enum{Int8} <: Base.Enum{Int8}
    @test Base.Enums.basetype(Fruit8.T) === Int8
    @test Integer(Fruit8.Apple) === Int8(0)

    @enumx FruitU8::UInt8 Apple Banana # no overflow even if first is typemin(T)
    @test Base.Enums.basetype(FruitU8.T) === UInt8
    @test FruitU8.Apple === FruitU8.T(0)

    let io = IOBuffer()
        show(io, "text/plain", FruitU8.T)
        str = String(take!(io))
        @test str == "Enum type FruitU8.T <: Enum{UInt8} with 2 instances:\n FruitU8.Apple  = 0x00\n FruitU8.Banana = 0x01"
        show(io, "text/plain", FruitU8.Apple)
        str = String(take!(io))
        @test str == "FruitU8.Apple = 0x00"
        show(io, "text/plain", FruitU8.Banana)
        str = String(take!(io))
        @test str == "FruitU8.Banana = 0x01"
    end

    @enumx Fruit16::T16 Apple
    @test Fruit16.T <: EnumX.Enum{Int16} <: Base.Enum{Int16}
    @test Base.Enums.basetype(Fruit16.T) === Int16
    @test Integer(Fruit16.Apple) === Int16(0)

    @enumx Fruit64::getInt64() Apple
    @test Fruit64.T <: EnumX.Enum{Int64} <: Base.Enum{Int64}
    @test Base.Enums.basetype(Fruit64.T) === Int64
    @test Integer(Fruit64.Apple) == Int64(0)

    try
        @macroexpand @enumx (Fr + uit) Apple
        error()
    catch err
        err isa LoadError && (err = err.error)
        @test err isa ArgumentError
        @test err.msg == "invalid EnumX.@enumx type specification: Fr + uit."
    end


    # Block syntax
    @enumx FruitBlock begin
        Apple
        Banana
    end
    @test FruitBlock.T <: EnumX.Enum{Int32} <: Base.Enum{Int32}
    @test FruitBlock.Apple === FruitBlock.T(0)
    @test FruitBlock.Banana === FruitBlock.T(1)

    @enumx FruitBlock8::Int8 begin
        Apple
        Banana
    end
    @test FruitBlock8.T <: EnumX.Enum{Int8} <: Base.Enum{Int8}
    @test FruitBlock8.Apple === FruitBlock8.T(0)
    @test FruitBlock8.Banana === FruitBlock8.T(1)


    # Custom values
    @enumx FruitValues Apple = 1 Banana = (1 + 2) Orange
    @test FruitValues.Apple === FruitValues.T(1)
    @test FruitValues.Banana === FruitValues.T(3)
    @test FruitValues.Orange === FruitValues.T(4)

    @enumx FruitValues8::Int8 Apple = -1 Banana = (1 + 2) Orange
    @test FruitValues8.Apple === FruitValues8.T(-1)
    @test FruitValues8.Banana === FruitValues8.T(3)
    @test FruitValues8.Orange === FruitValues8.T(4)

    @enumx FruitValuesBlock begin
        Apple = sum((1, 2, 3))
        Banana
    end
    @test FruitValuesBlock.Apple === FruitValuesBlock.T(6)
    @test FruitValuesBlock.Banana === FruitValuesBlock.T(7)

    try
        @macroexpand @enumx Fruit::Int8 Apple = typemax(Int8) Banana
        error()
    catch err
        err isa LoadError && (err = err.error)
        @test err isa ArgumentError
        @test err.msg == "value overflow for Enum Fruit: Fruit.Banana = -128."
    end
    try
        @macroexpand @enumx Fruit::Int8 Apple = "apple"
        error()
    catch err
        err isa LoadError && (err = err.error)
        @test err isa ArgumentError
        @test err.msg == "invalid value for Enum Fruit{Int8}: Fruit.Apple = \"apple\"."
    end
    try
        @macroexpand @enumx Fruit::Int8 Apple = 128
        error()
    catch err
        err isa LoadError && (err = err.error)
        @test err isa ArgumentError
        @test err.msg == "invalid value for Enum Fruit{Int8}: Fruit.Apple = 128."
    end
    try
        @macroexpand @enumx Fruit::Int8 Apple()
        error()
    catch err
        err isa LoadError && (err = err.error)
        @test err isa ArgumentError
        @test err.msg == "invalid EnumX.@enumx entry: Apple()"
    end
    try
        @macroexpand @enumx Fruit Apple Apple
        error()
    catch err
        err isa LoadError && (err = err.error)
        @test err isa ArgumentError
        @test err.msg == "duplicate name for Enum Fruit: Fruit.Apple = 1, name already used for Fruit.Apple = 0."
    end


    # Duplicate values
    @enumx FruitDup Apple = 0 Banana = 0
    @test FruitDup.Apple === FruitDup.Banana === FruitDup.T(0)

    let io = IOBuffer()
        show(io, "text/plain", FruitDup.T)
        str = String(take!(io))
        @test str == "Enum type FruitDup.T <: Enum{Int32} with 2 instances:\n FruitDup.Apple  = 0\n FruitDup.Banana = 0"
        show(io, "text/plain", FruitDup.Apple)
        str = String(take!(io))
        @test str == "FruitDup.Apple = FruitDup.Banana = 0"
        show(io, "text/plain", FruitDup.Banana)
        str = String(take!(io))
        @test str == "FruitDup.Apple = FruitDup.Banana = 0"
    end


    # Initialize with previous instance name
    @enumx FruitPrev Elppa Banana = Elppa Orange = Ananab
    @test FruitPrev.Elppa === FruitPrev.Banana === FruitPrev.T(0)
    @test FruitPrev.Orange === FruitPrev.T(-1)


    # Custom typename
    @enumx T = Typ FruitT Apple Banana
    @test isdefined(FruitT, :Typ)
    @test !isdefined(FruitT, :T)
    @test FruitT.Typ <: EnumX.Enum
    @test FruitT.Apple === FruitT.Typ(0)

    let io = IOBuffer()
        show(io, "text/plain", FruitT.Typ)
        str = String(take!(io))
        @test str == "Enum type FruitT.Typ <: Enum{Int32} with 2 instances:\n FruitT.Apple  = 0\n FruitT.Banana = 1"
    end

    # Custom typename with quoted symbol
    @enumx T = :Typ FruitST Apple Banana
    @test isdefined(FruitST, :Typ)
    @test !isdefined(FruitST, :T)
    @test FruitST.Typ <: EnumX.Enum
    @test FruitST.Apple === FruitST.Typ(0)

    try
        @macroexpand @enumx T = Apple Fruit Apple
        error()
    catch err
        err isa LoadError && (err = err.error)
        @test err isa ArgumentError
        @test err.msg == "instance name Fruit.Apple reserved for the Enum typename."
    end


    # Empty enum
    @enumx FruitEmpty
    @test instances(FruitEmpty.T) == ()
    let io = IOBuffer()
        show(io, "text/plain", FruitEmpty.T)
        str = String(take!(io))
        @test str == "Enum type FruitEmpty.T <: Enum{Int32} with 0 instances"
    end

    @enumx T = Typ FruitEmptyT
    @test instances(FruitEmptyT.Typ) == ()


    # Showing invalid instances
    @enumx Invalid A
    let io = IOBuffer()
        invalid = Base.bitcast(Invalid.T, Int32(1))
        show(io, "text/plain", invalid)
        str = String(take!(io))
        @test str == "Invalid.#invalid# = 1"
    end


    # Documented type (module) and instances
    begin
        """
        Documentation for FruitDoc
        """
        @enumx FruitDoc begin
            "Apple documentation."
            Apple
            """
            Banana documentation
            on multiple lines.
            """
            Banana = 2
            Orange = Apple
        end
        @eval const LINENUMBER = $(@__LINE__)
        @eval const FILENAME = $(@__FILE__)
        @eval const MODULE = $(@__MODULE__)
    end

    function get_doc_metadata(mod, s)
        Base.Docs.meta(mod)[Base.Docs.Binding(mod, s)].docs[Union{}].data
    end

    @test FruitDoc.Apple === FruitDoc.T(0)
    @test FruitDoc.Banana === FruitDoc.T(2)
    @test FruitDoc.Orange === FruitDoc.T(0)

    mod_doc = @doc(FruitDoc)
    @test sprint(show, mod_doc) == "Documentation for FruitDoc\n"
    mod_doc_data = get_doc_metadata(FruitDoc, :FruitDoc)
    @test mod_doc_data[:linenumber] == LINENUMBER - 13
    @test mod_doc_data[:path] == FILENAME
    @test mod_doc_data[:module] == MODULE

    apple_doc = @doc(FruitDoc.Apple)
    @test sprint(show, apple_doc) == "Apple documentation.\n"
    apple_doc_data = get_doc_metadata(FruitDoc, :Apple)
    @test apple_doc_data[:linenumber] == LINENUMBER - 9
    @test apple_doc_data[:path] == FILENAME
    @test apple_doc_data[:module] == FruitDoc

    banana_doc = @doc(FruitDoc.Banana)
    @test sprint(show, banana_doc) == "Banana documentation on multiple lines.\n"
    banana_doc_data = get_doc_metadata(FruitDoc, :Banana)
    @test banana_doc_data[:linenumber] == LINENUMBER - 7
    @test banana_doc_data[:path] == FILENAME
    @test banana_doc_data[:module] == FruitDoc

    orange_doc = @doc(FruitDoc.Orange)
    @test startswith(sprint(show, orange_doc), "No documentation found")

end # testset
