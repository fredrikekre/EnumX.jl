# SPDX-License-Identifier: MIT

using EnumX, Test

const T16 = Int16
getInt64() = Int64

@testset "EnumX" begin

# Basic
@enumx Fruit Apple Banana

@test Fruit isa Module
@test Set(names(Fruit)) == Set([:Fruit])
@test_broken Set(names(Fruit; all=true)) == Set([:Fruit, :Apple, :Banana, :Type])
@test issubset(Set([:Fruit, :Apple, :Banana, :Type]), Set(names(Fruit; all=true)))
@test Fruit.Type <: EnumX.Enum{Int32} <: Base.Enum{Int32}
@test !@isdefined(Apple)
@test !@isdefined(Banana)

@test Fruit.Apple isa EnumX.Enum
@test Fruit.Apple isa Base.Enum
@test Fruit.Banana isa EnumX.Enum
@test Fruit.Banana isa Base.Enum

@test instances(Fruit.Type) === (Fruit.Apple, Fruit.Banana)
@test Base.Enums.namemap(Fruit.Type) == Dict{Int32,Symbol}(0 => :Apple, 1 => :Banana)
@test Base.Enums.basetype(Fruit.Type) == Int32

@test Symbol(Fruit.Apple) === :Apple
@test Symbol(Fruit.Banana) === :Banana

@test Integer(Fruit.Apple) === Int32(0)
@test Int(Fruit.Apple) === Int(0)
@test Integer(Fruit.Banana) === Int32(1)
@test Int(Fruit.Banana) === Int(1)

@test Fruit.Apple === Fruit.Apple
@test Fruit.Banana === Fruit.Banana

@test Fruit.Type(Int32(0)) === Fruit.Type(0) === Fruit.Apple
@test Fruit.Type(Int32(1)) === Fruit.Type(1) === Fruit.Banana
@test_throws ArgumentError("invalid value 123 for Enum Fruit") Fruit.Type(Int32(123))
@test_throws ArgumentError("invalid value 123 for Enum Fruit") Fruit.Type(123)

@test Fruit.Apple < Fruit.Banana

let io = IOBuffer()
    write(io, Fruit.Apple)
    seekstart(io)
    @test read(io, Fruit.Type) === Fruit.Apple
    seekstart(io)
    write(io, Fruit.Banana)
    seekstart(io)
    @test read(io, Fruit.Type) === Fruit.Banana
    seekstart(io)
    write(io, Int32(123))
    seekstart(io)
    @test_throws ArgumentError("invalid value 123 for Enum Fruit") read(io, Fruit.Type)
end

let io = IOBuffer()
    show(io, "text/plain", Fruit.Type)
    str = String(take!(io))
    @test str == "Enum type Fruit.Type <: Enum{Int32} with 2 instances:\nFruit.Apple  = 0\nFruit.Banana = 1"
    show(io, "text/plain", Fruit.Apple)
    str = String(take!(io))
    @test str == "Fruit.Apple = 0"
    show(io, "text/plain", Fruit.Banana)
    str = String(take!(io))
    @test str == "Fruit.Banana = 1"
end


# Base type specification
@enumx Fruit8::Int8 Apple
@test Fruit8.Type <: EnumX.Enum{Int8} <: Base.Enum{Int8}
@test Base.Enums.basetype(Fruit8.Type) === Int8
@test Integer(Fruit8.Apple) === Int8(0)

@enumx Fruit16::T16 Apple
@test Fruit16.Type <: EnumX.Enum{Int16} <: Base.Enum{Int16}
@test Base.Enums.basetype(Fruit16.Type) === Int16
@test Integer(Fruit16.Apple) === Int16(0)

@enumx Fruit64::getInt64() Apple
@test Fruit64.Type <: EnumX.Enum{Int64} <: Base.Enum{Int64}
@test Base.Enums.basetype(Fruit64.Type) === Int64
@test Integer(Fruit64.Apple) == Int64(0)

try
    @macroexpand @enumx (Fr + uit) Apple
catch err
    err isa LoadError && (err = err.error)
    @test err isa ArgumentError
    @test err.msg == "invalid EnumX.@enumx type specification: Fr + uit"
end


# Block syntax
@enumx FruitBlock begin
    Apple
    Banana
end
@test FruitBlock.Type <: EnumX.Enum{Int32} <: Base.Enum{Int32}
@test FruitBlock.Apple === FruitBlock.Type(0)
@test FruitBlock.Banana === FruitBlock.Type(1)

@enumx FruitBlock8::Int8 begin
    Apple
    Banana
end
@test FruitBlock8.Type <: EnumX.Enum{Int8} <: Base.Enum{Int8}
@test FruitBlock8.Apple === FruitBlock8.Type(0)
@test FruitBlock8.Banana === FruitBlock8.Type(1)

end # testset
