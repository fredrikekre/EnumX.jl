# SPDX-License-Identifier: MIT

using EnumX, Test

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

end # testset
