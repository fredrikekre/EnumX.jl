# EnumX.jl

[![CI](https://github.com/fredrikekre/EnumX.jl/actions/workflows/CI.yml/badge.svg?branch=master&event=push)](https://github.com/fredrikekre/EnumX.jl/actions/workflows/CI.yml)
[![Codecov](https://codecov.io/gh/fredrikekre/EnumX.jl/branch/master/graph/badge.svg?token=K7C8OASVZR)](https://codecov.io/gh/fredrikekre/EnumX.jl)
[![code style: runic](https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black)](https://github.com/fredrikekre/Runic.jl)

This is what I wish
[`Base.@enum`](https://docs.julialang.org/en/v1/base/base/#Base.Enums.@enum) was.

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

Since the instances are scoped into a module, tab-completion is obtained "for free",
which helps a lot with discoverability of the instance names:

```julia
julia> @enumx Fruit Apple Banana

julia> Fruit.<TAB>
Apple Banana T
```

Since the only reserved name in the example above is the module `Fruit` we can create
another enum with overlapping instance names (this would not be possible with `Base.@enum`):

```julia
julia> @enumx YellowFruit Banana Lemon

julia> YellowFruit.Banana
YellowFruit.Banana = 0
```

Instances can be documented like `struct` fields. A docstring before the macro is
attached to the *module* `Fruit` (i.e. not the "hidden" type `Fruit.T`):

```julia
julia> "Documentation for Fruit enum-module."
       @enumx Fruit begin
           "Documentation for Fruit.Apple instance."
           Apple
       end

help?> Fruit
  Documentation for Fruit enum-module.

help?> Fruit.Apple
  Documentation for Fruit.Apple instance.
```

`@enumx` allows for duplicate values (unlike `Base.@enum`):

```julia
julia> @enumx Fruit Apple=1 Banana=1

julia> Fruit.T
Enum type Fruit.T <: Enum{Int32} with 2 instances:
 Fruit.Apple  = 1
 Fruit.Banana = 1

julia> Fruit.Apple
Fruit.Apple = Fruit.Banana = 1

julia> Fruit.Banana
Fruit.Apple = Fruit.Banana = 1
```

`@enumx` lets you use previous enum names for value initialization:

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

 - Specifying values with literals or expressions (if not specified, defaults to the value
   of the previous instance + 1):
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
 - [Encapsulating enum access via dot syntax](https://discourse.julialang.org/t/encapsulating-enum-access-via-dot-syntax/11785)
 - [Can not reuse enum member in different member](https://discourse.julialang.org/t/cannot-reuse-enum-member-in-different-enum/21342)
 - [Solving the drawbacks of `@enum`](https://discourse.julialang.org/t/solving-the-drawbacks-of-enum/74506)

**Related packages**
 - [CEnum.jl](https://github.com/JuliaInterop/CEnum.jl): C-compatible Enums.
 - [SuperEnum.jl](https://github.com/kindlychung/SuperEnum.jl): Similar approach as EnumX,
   but doesn't give you `Base.Enum`s.
 - [NamespacedEnums.jl](https://github.com/christopher-dG/NamespacedEnums.jl): Discontinued
   package similar to EnumX, which gave me the idea to let user override the default `.T`
   typename.
