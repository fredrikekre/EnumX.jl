# EnumX.jl

[![CI][gh-actions-img]][gh-actions-url]
[![codecov][codecov-img]][codecov-url]

This is what I wish [`Base.@enum`][at-enum] was.

## Usage

EnumX exports the macro `@enumx`, which works similarly to `Base.@enum`, but with
some improvements.

The main drawback of `Base.@enum` is that the names for instances
are *not* scoped. This means, for example, that it is inconvenient to use "common" names
for enum instances, and it is impossible to have multiple enums with the same instance
names.

`EnumX.@enumx` solves these limitations by putting everything behind a module scope such
that instances are hidden and instead accessed using dot-syntax:

```julia
julia> using EnumX

julia> @enumx Fruit Apple Banana

julia> Fruit.Apple
Fruit.Apple = 0

julia> Fruit.Banana
Fruit.Banana = 1
```

`Fruit` is a module -- the actual enum type is defined as `Fruit.T` by default:

```julia
julia> Fruit.T
Enum type Fruit.T <: Enum{Int32} with 2 instances:
 Fruit.Apple  = 0
 Fruit.Banana = 1

julia> Fruit.T <: Base.Enum
true
```

Another typename can be passed as the first argument to `@enumx` as follows:

```julia
julia> @enumx T=FruitEnum Fruit Apple

julia> Fruit.FruitEnum
Enum type Fruit.FruitEnum <: Enum{Int32} with 1 instance:
 Fruit.Apple = 0
```

Since the only reserved name in the example above is the module `Fruit` we can create
another enum with overlapping instance names (this would not be possible with `Base.@enum`):

```julia
julia> @enumx YellowFruits Banana Lemon

julia> YellowFruits.Banana
YellowFruits.Banana = 0
```

`@enumx` also allows for duplicate values:

```julia
julia> Fruit.T
Enum type Fruit.T <: Enum{Int32} with 2 instances:
 Fruit.Apple  = 1
 Fruit.Banana = 1

julia> Fruit.Apple
Fruit.Apple = Fruit.Banana = 1

julia> Fruit.Banana
Fruit.Apple = Fruit.Banana = 1
```

`@enumx` also lets you use previous enum names for value initialization:
```julia
julia> @enumx Fruit Apple Banana Orange=Apple

julia> Fruit.T
Enum type Fruit.T <: Enum{Int32} with 3 instances:
 Fruit.Apple  = 0
 Fruit.Banana = 1
 Fruit.Orange = 0
```

Other than that, functionality should be comparable to `Base.@enum`:

 - Base type specification (defaults to `Int32`):
   ```julia
   julia> @enumx Fruit::UInt8 Apple Banana

   julia> typeof(Integer(Fruit.Apple))
   UInt8
   ```

 - Specifying values (if not specified, defaults to the value of the previous instance + 1):
   ```julia
   julia> @enumx Fruit Apple=4 Banana=(1 + 5) Orange

   julia> Fruit.T
   Enum type Fruit.T <: Enum{Int32} with 3 instances:
    Fruit.Apple  = 4
    Fruit.Banana = 6
    Fruit.Orange = 7
   ```

 - Definition with `begin`/`end` block:
   ```julia
   julia> @enumx Fruit begin
              Apple
              Banana
              Orange
          end
   ```

## See also

**Community discussions**
 - [Encapsulating enum access via dot syntax][discourse-1]
 - [Can not reuse enum member in different member][discourse-2]
 - [Solving the drawbacks of `@enum`][discourse-3]

**Related packages**
 - [CEnum.jl][CEnum]: C-compatible Enums.
 - [SuperEnum.jl][SuperEnum]: Similar approach as EnumX, but doesn't give you `Base.Enum`s.
 - [NamespacedEnums.jl][NamespacedEnums]: Discontinued package similar to EnumX, which
   gave me the idea to let user override the default `.T` typename.


[at-enum]: https://docs.julialang.org/en/v1/base/base/#Base.Enums.@enum
[discourse-1]: https://discourse.julialang.org/t/encapsulating-enum-access-via-dot-syntax/11785
[discourse-2]: https://discourse.julialang.org/t/cannot-reuse-enum-member-in-different-enum/21342
[discourse-3]: https://discourse.julialang.org/t/solving-the-drawbacks-of-enum/74506
[CEnum]: https://github.com/JuliaInterop/CEnum.jl
[SuperEnum]: https://github.com/kindlychung/SuperEnum.jl
[NamespacedEnums]: https://github.com/christopher-dG/NamespacedEnums.jl


[gh-actions-img]: https://github.com/fredrikekre/EnumX.jl/actions/workflows/ci.yml/badge.svg?branch=master&event=push
[gh-actions-url]: https://github.com/fredrikekre/EnumX.jl/actions/workflows/ci.yml

[codecov-img]: https://codecov.io/gh/fredrikekre/EnumX.jl/branch/master/graph/badge.svg?token=K7C8OASVZR
[codecov-url]: https://codecov.io/gh/fredrikekre/EnumX.jl
