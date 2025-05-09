###############################################################################
#
#   ArbTypes.jl : Parent and object types for Arb
#
#   Copyright (C) 2015 Tommy Hofmann
#   Copyright (C) 2015 Fredrik Johansson
#
###############################################################################

arb_check_precision(p::Int) = (p >= 2 && p < (typemax(Int) >> 4)) || throw(ArgumentError("invalid precision"))

# Rounding modes

const ARB_RND_DOWN = Cint(0)   # towards zero
const ARB_RND_UP = Cint(1)     # away from zero
const ARB_RND_FLOOR = Cint(2)  # towards -infinity
const ARB_RND_CEIL = Cint(3)   # towards +infinity
const ARB_RND_NEAR = Cint(4)   # to nearest

################################################################################
#
#  Structs for shallow operations
#
################################################################################

mutable struct arf_struct
  exp::Int    # ZZRingElem
  size::UInt  # mp_size_t
  d1::UInt    # mantissa_struct
  d2::UInt

  function arf_struct(exp, size, d1, d2)
    new(exp, size, d1, d2)
  end

  function arf_struct()
    z = new()
    @ccall libflint.arf_init(z::Ref{arf_struct})::Nothing
    finalizer(_arf_clear_fn, z)
    return z
  end
end

function _arf_clear_fn(x::arf_struct)
  @ccall libflint.arf_clear(x::Ref{arf_struct})::Nothing
end

mutable struct mag_struct
  exp::Int  # ZZRingElem
  man::UInt # mp_limb_t
end

mutable struct arb_struct
  mid_exp::Int # ZZRingElem
  mid_size::UInt # mp_size_t
  mid_d1::UInt # mantissa_struct
  mid_d2::UInt
  rad_exp::Int # ZZRingElem
  rad_man::UInt
end

mutable struct acb_struct
  real_mid_exp::Int # ZZRingElem
  real_mid_size::UInt # mp_size_t
  real_mid_d1::Int # mantissa_struct
  real_mid_d2::Int
  real_rad_exp::Int # ZZRingElem
  real_rad_man::UInt
  imag_mid_exp::Int # ZZRingElem
  imag_mid_size::UInt # mp_size_t
  imag_mid_d1::Int # mantissa_struct
  imag_mid_d2::Int
  imag_rad_exp::Int # ZZRingElem
  imag_rad_man::UInt
end

const arf_structOrPtr = Union{arf_struct, Ref{arf_struct}, Ptr{arf_struct}}
const mag_structOrPtr = Union{mag_struct, Ref{mag_struct}, Ptr{mag_struct}}
const arb_structOrPtr = Union{arb_struct, Ref{arb_struct}, Ptr{arb_struct}}
const acb_structOrPtr = Union{acb_struct, Ref{acb_struct}, Ptr{acb_struct}}

_mid_ptr(x::arb_structOrPtr) = @ccall libflint.arb_mid_ptr(x::Ref{arb_struct})::Ptr{arf_struct}
_rad_ptr(x::arb_structOrPtr) = @ccall libflint.arb_rad_ptr(x::Ref{arb_struct})::Ptr{mag_struct}

_real_ptr(x::acb_structOrPtr) = @ccall libflint.acb_real_ptr(x::Ref{acb_struct})::Ptr{arb_struct}
_imag_ptr(x::acb_structOrPtr) = @ccall libflint.acb_imag_ptr(x::Ref{acb_struct})::Ptr{arb_struct}

################################################################################
#
#  Types and memory management for ArbField
#
################################################################################

struct RealField <: Field
end

mutable struct RealFieldElem <: FieldElem
  mid_exp::Int    # ZZRingElem
  mid_size::UInt  # mp_size_t
  mid_d1::UInt    # mantissa_struct
  mid_d2::UInt
  rad_exp::Int    # ZZRingElem
  rad_man::UInt

  function RealFieldElem()
    z = new()
    @ccall libflint.arb_init(z::Ref{RealFieldElem})::Nothing
    finalizer(_arb_clear_fn, z)
    return z
  end

  function RealFieldElem(x::Union{Real, ZZRingElem, QQFieldElem, AbstractString, RealFieldElem}, p::Int)
    z = RealFieldElem()
    _arb_set(z, x, p)
    return z
  end

  function RealFieldElem(x::Union{Real, ZZRingElem})
    z = RealFieldElem()
    _arb_set(z, x)
    return z
  end

  function RealFieldElem(mid::RealFieldElem, rad::RealFieldElem)
    z = RealFieldElem()
    _arb_set(z, mid)
    @ccall libflint.arb_add_error(z::Ref{RealFieldElem}, rad::Ref{RealFieldElem})::Nothing
    return z
  end

end

function _arb_clear_fn(x::RealFieldElem)
  @ccall libflint.arb_clear(x::Ref{RealFieldElem})::Nothing
end

# fixed precision

@attributes mutable struct ArbField <: Field
  prec::Int

  function ArbField(p::Int = 256; cached::Bool = true)
    arb_check_precision(p)
    return get_cached!(ArbFieldID, p, cached) do
      return new(p)
    end
  end
end

const ArbFieldID = CacheDictType{Int, ArbField}()

precision(x::ArbField) = x.prec

mutable struct ArbFieldElem <: FieldElem
  mid_exp::Int # ZZRingElem
  mid_size::UInt # mp_size_t
  mid_d1::UInt # mantissa_struct
  mid_d2::UInt
  rad_exp::Int # ZZRingElem
  rad_man::UInt
  parent::ArbField

  function ArbFieldElem()
    z = new()
    @ccall libflint.arb_init(z::Ref{ArbFieldElem})::Nothing
    finalizer(_arb_clear_fn, z)
    return z
  end

  function ArbFieldElem(x::Union{Real, ZZRingElem, QQFieldElem, AbstractString, ArbFieldElem}, p::Int)
    z = ArbFieldElem()
    _arb_set(z, x, p)
    return z
  end

  function ArbFieldElem(x::Union{Real, ZZRingElem, ArbFieldElem})
    z = ArbFieldElem()
    _arb_set(z, x)
    return z
  end

  function ArbFieldElem(mid::ArbFieldElem, rad::ArbFieldElem)
    z = ArbFieldElem()
    _arb_set(z, mid)
    @ccall libflint.arb_add_error(z::Ref{ArbFieldElem}, rad::Ref{ArbFieldElem})::Nothing
    return z
  end

  #function ArbFieldElem(x::arf)
  #  z = ArbFieldElem()
  #  @ccall libflint.arb_set_arf(z::Ref{ArbFieldElem}, x::Ptr{arf})::Nothing
  #  return z
  #end
end

function _arb_clear_fn(x::ArbFieldElem)
  @ccall libflint.arb_clear(x::Ref{ArbFieldElem})::Nothing
end


################################################################################
#
#  Types and memory management for AcbField
#
################################################################################

struct ComplexField <: Field
end

mutable struct ComplexFieldElem <: FieldElem
  real_mid_exp::Int     # ZZRingElem
  real_mid_size::UInt   # mp_size_t
  real_mid_d1::UInt     # mantissa_struct
  real_mid_d2::UInt
  real_rad_exp::Int     # ZZRingElem
  real_rad_man::UInt
  imag_mid_exp::Int     # ZZRingElem
  imag_mid_size::UInt   # mp_size_t
  imag_mid_d1::UInt     # mantissa_struct
  imag_mid_d2::UInt
  imag_rad_exp::Int     # ZZRingElem
  imag_rad_man::UInt

  function ComplexFieldElem()
    z = new()
    @ccall libflint.acb_init(z::Ref{ComplexFieldElem})::Nothing
    finalizer(_acb_clear_fn, z)
    return z
  end

  function ComplexFieldElem(x::Union{Number, ZZRingElem, RealFieldElem, ComplexFieldElem})
    z = ComplexFieldElem()
    _acb_set(z, x)
    return z
  end

  function ComplexFieldElem(x::Union{Number, ZZRingElem, QQFieldElem, RealFieldElem, ComplexFieldElem, AbstractString}, p::Int)
    z = ComplexFieldElem()
    _acb_set(z, x, p)
    return z
  end

  function ComplexFieldElem(x::T, y::T, p::Int) where {T <: Union{Real, ZZRingElem, QQFieldElem, AbstractString, RealFieldElem}}
    z = ComplexFieldElem()
    _acb_set(z, (x, y), p)
    return z
  end
end

function _acb_clear_fn(x::ComplexFieldElem)
  @ccall libflint.acb_clear(x::Ref{ComplexFieldElem})::Nothing
end

################################################################################
#
#  Precision management
#
################################################################################

struct Balls
end

# ArbFieldElem as in arblib
const ARB_DEFAULT_PRECISION = Ref{Int}(64)

@doc raw"""
    set_precision!(::Type{Balls}, n::Int)

Set the precision for all ball arithmetic to be `n`.

# Examples

```julia
julia> const_pi(RealField())
[3.141592653589793239 +/- 5.96e-19]

julia> set_precision!(Balls, 200); const_pi(RealField())
[3.14159265358979323846264338327950288419716939937510582097494 +/- 5.73e-60]
```
"""
function set_precision!(::Type{Balls}, n::Int)
  arb_check_precision(n)
  ARB_DEFAULT_PRECISION[] = n
end

@doc raw"""
    precision(::Type{Balls})

Return the precision for ball arithmetic.

# Examples

```julia
julia> set_precision!(Balls, 200); precision(Balls)
200
```
"""
function Base.precision(::Type{Balls})
  return ARB_DEFAULT_PRECISION[]
end

@doc raw"""
    set_precision!(f, ::Type{Balls}, n::Int)

Change ball arithmetic precision to `n` for the duration of `f`..

# Examples

```jldoctest
julia> set_precision!(Balls, 4) do
         const_pi(RealField())
       end
[3e+0 +/- 0.376]

julia> set_precision!(Balls, 200) do
         const_pi(RealField())
       end
[3.1415926535897932385 +/- 3.74e-20]
```
"""
function set_precision!(f, ::Type{Balls}, prec::Int)
  arb_check_precision(prec)
  old = precision(Balls)
  set_precision!(Balls, prec)
  x = f()
  set_precision!(Balls, old)
  return x
end

for T in [RealField, ComplexField]
  @eval begin
    precision(::$T) = precision(Balls)
    precision(::Type{$T}) = precision(Balls)

    set_precision!(::$T, n) = set_precision!(Balls, n)
    set_precision!(::Type{$T}, n) = set_precision!(Balls, n)

    set_precision!(f, ::$T, n) = set_precision!(f, Balls, n)
    set_precision!(f, ::Type{$T}, n) = set_precision!(f, Balls, n)
  end
end

# fixed precision

@attributes mutable struct AcbField <: Field
  prec::Int

  function AcbField(p::Int = 256; cached::Bool = true)
    arb_check_precision(p)
    return get_cached!(AcbFieldID, p, cached) do
      return new(p)
    end
  end
end

const AcbFieldID = CacheDictType{Int, AcbField}()

precision(x::AcbField) = x.prec

mutable struct AcbFieldElem <: FieldElem
  real_mid_exp::Int     # ZZRingElem
  real_mid_size::UInt # mp_size_t
  real_mid_d1::UInt    # mantissa_struct
  real_mid_d2::UInt
  real_rad_exp::Int     # ZZRingElem
  real_rad_man::UInt
  imag_mid_exp::Int     # ZZRingElem
  imag_mid_size::UInt # mp_size_t
  imag_mid_d1::UInt    # mantissa_struct
  imag_mid_d2::UInt
  imag_rad_exp::Int     # ZZRingElem
  imag_rad_man::UInt
  parent::AcbField

  function AcbFieldElem()
    z = new()
    @ccall libflint.acb_init(z::Ref{AcbFieldElem})::Nothing
    finalizer(_acb_clear_fn, z)
    return z
  end

  function AcbFieldElem(x::Union{Number, ZZRingElem, ArbFieldElem, AcbFieldElem})
    z = AcbFieldElem()
    _acb_set(z, x)
    return z
  end

  function AcbFieldElem(x::Union{Number, ZZRingElem, QQFieldElem, ArbFieldElem, AcbFieldElem, AbstractString}, p::Int)
    z = AcbFieldElem()
    _acb_set(z, x, p)
    return z
  end

  #function AcbFieldElem{T <: Union{Int, UInt, Float64, ZZRingElem, BigFloat, ArbFieldElem}}(x::T, y::T)
  #  z = AcbFieldElem()
  #  _acb_set(z, (x, y))
  #  return z
  #end

  function AcbFieldElem(x::T, y::T, p::Int) where {T <: Union{Real, ZZRingElem, QQFieldElem, AbstractString, ArbFieldElem}}
    z = AcbFieldElem()
    _acb_set(z, (x, y), p)
    return z
  end
end

function _acb_clear_fn(x::AcbFieldElem)
  @ccall libflint.acb_clear(x::Ref{AcbFieldElem})::Nothing
end

################################################################################
#
#  Integration things
#
################################################################################

mutable struct acb_calc_integrate_opts
  deg_limit::Int   # <= 0: default of 0.5*min(prec, rel_goal) + 10
  eval_limit::Int  # <= 0: default of 1000*prec*prec^2
  depth_limit::Int # <= 0: default of 2*prec
  use_heap::Int32  # 0 append to the top of a stack; 1 binary heap
  verbose::Int32   # 1 less verbose; 2 more verbose

  function acb_calc_integrate_opts(deg_limit::Int, eval_limit::Int,
      depth_limit::Int, use_heap::Int32, verbose::Int32)
    return new(deg_limit, eval_limit, depth_limit, use_heap, verbose)
  end

  function acb_calc_integrate_opts()
    opts = new()
    @ccall libflint.acb_calc_integrate_opt_init(opts::Ref{acb_calc_integrate_opts})::Nothing
    return opts
  end
end

################################################################################
#
#  Types and memory management for ArbPolyRing
#
################################################################################

@attributes mutable struct RealPolyRing <: PolyRing{RealFieldElem}
  S::Symbol

  function RealPolyRing(R::RealField, S::Symbol, cached::Bool = true)
    return get_cached!(RealPolyRingID, (S, ), cached) do
      return new(S)
    end
  end
end

const RealPolyRingID = CacheDictType{Tuple{Symbol}, RealPolyRing}()

mutable struct RealPolyRingElem <: PolyRingElem{RealFieldElem}
  coeffs::Ptr{Nothing}
  alloc::Int
  length::Int
  parent::RealPolyRing

  function RealPolyRingElem()
    z = new()
    @ccall libflint.arb_poly_init(z::Ref{RealPolyRingElem})::Nothing
    finalizer(_RealPoly_clear_fn, z)
    return z
  end

  function RealPolyRingElem(x::RealFieldElem, p::Int)
    z = RealPolyRingElem()
    setcoeff!(z, 0, x)
    return z
  end

  function RealPolyRingElem(x::Vector{RealFieldElem}, p::Int)
    z = RealPolyRingElem()
    for i in 1:length(x)
      setcoeff!(z, i - 1, x[i])
    end
    return z
  end

  function RealPolyRingElem(x::RealPolyRingElem)
    z = RealPolyRingElem()
    @ccall libflint.arb_poly_set(z::Ref{RealPolyRingElem}, x::Ref{RealPolyRingElem})::Nothing
    return z
  end

  function RealPolyRingElem(x::RealPolyRingElem, p::Int)
    z = RealPolyRingElem()
    @ccall libflint.arb_poly_set_round(z::Ref{RealPolyRingElem}, x::Ref{RealPolyRingElem}, p::Int)::Nothing
    return z
  end

  function RealPolyRingElem(x::ZZPolyRingElem, p::Int)
    z = RealPolyRingElem()
    @ccall libflint.arb_poly_set_fmpz_poly(z::Ref{RealPolyRingElem}, x::Ref{ZZPolyRingElem}, p::Int)::Nothing
    return z
  end

  function RealPolyRingElem(x::QQPolyRingElem, p::Int)
    z = RealPolyRingElem()
    @ccall libflint.arb_poly_set_fmpq_poly(z::Ref{RealPolyRingElem}, x::Ref{QQPolyRingElem}, p::Int)::Nothing
    return z
  end
end

function _RealPoly_clear_fn(x::RealPolyRingElem)
  @ccall libflint.arb_poly_clear(x::Ref{RealPolyRingElem})::Nothing
end

parent(x::RealPolyRingElem) = x.parent

var(x::RealPolyRing) = x.S

base_ring(a::RealPolyRing) = RealField()

# fixed precision

@attributes mutable struct ArbPolyRing <: PolyRing{ArbFieldElem}
  base_ring::ArbField
  S::Symbol

  function ArbPolyRing(R::ArbField, S::Symbol, cached::Bool = true)
    return get_cached!(ArbPolyRingID, (R, S), cached) do
      return new(R, S)
    end
  end
end

const ArbPolyRingID = CacheDictType{Tuple{ArbField, Symbol}, ArbPolyRing}()

mutable struct ArbPolyRingElem <: PolyRingElem{ArbFieldElem}
  coeffs::Ptr{Nothing}
  alloc::Int
  length::Int
  parent::ArbPolyRing

  function ArbPolyRingElem()
    z = new()
    @ccall libflint.arb_poly_init(z::Ref{ArbPolyRingElem})::Nothing
    finalizer(_arb_poly_clear_fn, z)
    return z
  end

  function ArbPolyRingElem(x::ArbFieldElem, p::Int)
    z = ArbPolyRingElem()
    setcoeff!(z, 0, x)
    return z
  end

  function ArbPolyRingElem(x::Vector{ArbFieldElem}, p::Int)
    z = ArbPolyRingElem()
    for i in 1:length(x)
      setcoeff!(z, i - 1, x[i])
    end
    return z
  end

  function ArbPolyRingElem(x::ArbPolyRingElem)
    z = ArbPolyRingElem()
    @ccall libflint.arb_poly_set(z::Ref{ArbPolyRingElem}, x::Ref{ArbPolyRingElem})::Nothing
    return z
  end

  function ArbPolyRingElem(x::ArbPolyRingElem, p::Int)
    z = ArbPolyRingElem()
    @ccall libflint.arb_poly_set_round(z::Ref{ArbPolyRingElem}, x::Ref{ArbPolyRingElem}, p::Int)::Nothing
    return z
  end

  function ArbPolyRingElem(x::ZZPolyRingElem, p::Int)
    z = ArbPolyRingElem()
    @ccall libflint.arb_poly_set_fmpz_poly(z::Ref{ArbPolyRingElem}, x::Ref{ZZPolyRingElem}, p::Int)::Nothing
    return z
  end

  function ArbPolyRingElem(x::QQPolyRingElem, p::Int)
    z = ArbPolyRingElem()
    @ccall libflint.arb_poly_set_fmpq_poly(z::Ref{ArbPolyRingElem}, x::Ref{QQPolyRingElem}, p::Int)::Nothing
    return z
  end
end

function _arb_poly_clear_fn(x::ArbPolyRingElem)
  @ccall libflint.arb_poly_clear(x::Ref{ArbPolyRingElem})::Nothing
end

parent(x::ArbPolyRingElem) = x.parent

var(x::ArbPolyRing) = x.S

precision(x::ArbPolyRing) = precision(x.base_ring)

base_ring(a::ArbPolyRing) = a.base_ring

################################################################################
#
#  Types and memory management for AcbPolyRing
#
################################################################################

@attributes mutable struct ComplexPolyRing <: PolyRing{ComplexFieldElem}
  S::Symbol

  function ComplexPolyRing(R::ComplexField, S::Symbol, cached::Bool = true)
    return get_cached!(ComplexPolyRingID, (S, ), cached) do
      return new(S)
    end
  end
end

const ComplexPolyRingID = CacheDictType{Tuple{Symbol}, ComplexPolyRing}()

mutable struct ComplexPolyRingElem <: PolyRingElem{ComplexFieldElem}
  coeffs::Ptr{Nothing}
  alloc::Int
  length::Int
  parent::ComplexPolyRing

  function ComplexPolyRingElem()
    z = new()
    @ccall libflint.acb_poly_init(z::Ref{ComplexPolyRingElem})::Nothing
    finalizer(_acb_poly_clear_fn, z)
    return z
  end

  function ComplexPolyRingElem(x::ComplexFieldElem, p::Int)
    z = ComplexPolyRingElem()
    setcoeff!(z, 0, x)
    return z
  end

  function ComplexPolyRingElem(x::Vector{ComplexFieldElem}, p::Int)
    z = ComplexPolyRingElem()
    for i in 1:length(x)
      setcoeff!(z, i - 1, x[i])
    end
    return z
  end

  function ComplexPolyRingElem(x::ComplexPolyRingElem)
    z = ComplexPolyRingElem()
    @ccall libflint.acb_poly_set(z::Ref{ComplexPolyRingElem}, x::Ref{ComplexPolyRingElem})::Nothing
    return z
  end

  function ComplexPolyRingElem(x::RealPolyRingElem, p::Int)
    z = ComplexPolyRingElem()
    @ccall libflint.acb_poly_set_arb_poly(z::Ref{ComplexPolyRingElem}, x::Ref{ArbPolyRingElem}, p::Int)::Nothing
    @ccall libflint.acb_poly_set_round(z::Ref{ComplexPolyRingElem}, z::Ref{ComplexPolyRingElem}, p::Int)::Nothing
    return z
  end

  function ComplexPolyRingElem(x::ComplexPolyRingElem, p::Int)
    z = ComplexPolyRingElem()
    @ccall libflint.acb_poly_set_round(z::Ref{ComplexPolyRingElem}, x::Ref{ComplexPolyRingElem}, p::Int)::Nothing
    return z
  end

  function ComplexPolyRingElem(x::ZZPolyRingElem, p::Int)
    z = ComplexPolyRingElem()
    @ccall libflint.acb_poly_set_fmpz_poly(z::Ref{ComplexPolyRingElem}, x::Ref{ZZPolyRingElem}, p::Int)::Nothing
    return z
  end

  function ComplexPolyRingElem(x::QQPolyRingElem, p::Int)
    z = ComplexPolyRingElem()
    @ccall libflint.acb_poly_set_fmpq_poly(z::Ref{ComplexPolyRingElem}, x::Ref{QQPolyRingElem}, p::Int)::Nothing
    return z
  end
end

function _acb_poly_clear_fn(x::ComplexPolyRingElem)
  @ccall libflint.acb_poly_clear(x::Ref{ComplexPolyRingElem})::Nothing
end

parent(x::ComplexPolyRingElem) = x.parent

var(x::ComplexPolyRing) = x.S

base_ring(a::ComplexPolyRing) = ComplexField()

# fixed precision

@attributes mutable struct AcbPolyRing <: PolyRing{AcbFieldElem}
  base_ring::AcbField
  S::Symbol

  function AcbPolyRing(R::AcbField, S::Symbol, cached::Bool = true)
    return get_cached!(AcbPolyRingID, (R, S), cached) do
      return new(R, S)
    end
  end
end

const AcbPolyRingID = CacheDictType{Tuple{AcbField, Symbol}, AcbPolyRing}()

mutable struct AcbPolyRingElem <: PolyRingElem{AcbFieldElem}
  coeffs::Ptr{Nothing}
  alloc::Int
  length::Int
  parent::AcbPolyRing

  function AcbPolyRingElem()
    z = new()
    @ccall libflint.acb_poly_init(z::Ref{AcbPolyRingElem})::Nothing
    finalizer(_acb_poly_clear_fn, z)
    return z
  end

  function AcbPolyRingElem(x::AcbFieldElem, p::Int)
    z = AcbPolyRingElem()
    setcoeff!(z, 0, x)
    return z
  end

  function AcbPolyRingElem(x::Vector{AcbFieldElem}, p::Int)
    z = AcbPolyRingElem()
    for i in 1:length(x)
      setcoeff!(z, i - 1, x[i])
    end
    return z
  end

  function AcbPolyRingElem(x::AcbPolyRingElem)
    z = AcbPolyRingElem()
    @ccall libflint.acb_poly_set(z::Ref{AcbPolyRingElem}, x::Ref{AcbPolyRingElem})::Nothing
    return z
  end

  function AcbPolyRingElem(x::ArbPolyRingElem, p::Int)
    z = AcbPolyRingElem()
    @ccall libflint.acb_poly_set_arb_poly(z::Ref{AcbPolyRingElem}, x::Ref{ArbPolyRingElem}, p::Int)::Nothing
    @ccall libflint.acb_poly_set_round(z::Ref{AcbPolyRingElem}, z::Ref{AcbPolyRingElem}, p::Int)::Nothing
    return z
  end

  function AcbPolyRingElem(x::AcbPolyRingElem, p::Int)
    z = AcbPolyRingElem()
    @ccall libflint.acb_poly_set_round(z::Ref{AcbPolyRingElem}, x::Ref{AcbPolyRingElem}, p::Int)::Nothing
    return z
  end

  function AcbPolyRingElem(x::ZZPolyRingElem, p::Int)
    z = AcbPolyRingElem()
    @ccall libflint.acb_poly_set_fmpz_poly(z::Ref{AcbPolyRingElem}, x::Ref{ZZPolyRingElem}, p::Int)::Nothing
    return z
  end

  function AcbPolyRingElem(x::QQPolyRingElem, p::Int)
    z = AcbPolyRingElem()
    @ccall libflint.acb_poly_set_fmpq_poly(z::Ref{AcbPolyRingElem}, x::Ref{QQPolyRingElem}, p::Int)::Nothing
    return z
  end
end

function _acb_poly_clear_fn(x::AcbPolyRingElem)
  @ccall libflint.acb_poly_clear(x::Ref{AcbPolyRingElem})::Nothing
end

parent(x::AcbPolyRingElem) = x.parent

var(x::AcbPolyRing) = x.S

precision(x::AcbPolyRing) = precision(x.base_ring)

base_ring(a::AcbPolyRing) = a.base_ring



################################################################################
#
#  Types and memory management for ArbMatrixSpace
#
################################################################################

const RealMatrixSpace = AbstractAlgebra.Generic.MatSpace{RealFieldElem}

mutable struct RealMatrix <: MatElem{RealFieldElem}
  entries::Ptr{Nothing}
  r::Int
  c::Int
  rows::Ptr{Nothing}
  #base_ring::ArbField

  # MatElem interface
  RealMatrix(::RealField, ::UndefInitializer, r::Int, c::Int) = RealMatrix(r, c)

  function RealMatrix(r::Int, c::Int)
    z = new()
    @ccall libflint.arb_mat_init(z::Ref{RealMatrix}, r::Int, c::Int)::Nothing
    finalizer(_arb_mat_clear_fn, z)
    return z
  end

  function RealMatrix(a::ZZMatrix)
    z = RealMatrix(a.r, a.c)
    @ccall libflint.arb_mat_set_fmpz_mat(z::Ref{RealMatrix}, a::Ref{ZZMatrix})::Nothing
    return z
  end

  function RealMatrix(a::ZZMatrix, prec::Int)
    z = RealMatrix(a.r, a.c)
    @ccall libflint.arb_mat_set_round_fmpz_mat(z::Ref{RealMatrix}, a::Ref{ZZMatrix}, prec::Int)::Nothing
    return z
  end

  function RealMatrix(r::Int, c::Int, arr::AbstractMatrix{T}) where {T <: Union{Int, UInt, ZZRingElem, Float64, BigFloat, RealFieldElem}}
    z = RealMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _arb_set(el, arr[i, j])
      end
    end
    return z
  end

  function RealMatrix(r::Int, c::Int, arr::AbstractVector{T}) where {T <: Union{Int, UInt, ZZRingElem, Float64, BigFloat, RealFieldElem}}
    z = RealMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _arb_set(el, arr[(i-1)*c+j])
      end
    end
    return z
  end

  function RealMatrix(r::Int, c::Int, arr::AbstractMatrix{T}, prec::Int) where {T <: Union{Int, UInt, ZZRingElem, QQFieldElem, Float64, BigFloat, RealFieldElem, AbstractString}}
    z = RealMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _arb_set(el, arr[i, j], prec)
      end
    end
    return z
  end

  function RealMatrix(r::Int, c::Int, arr::AbstractVector{T}, prec::Int) where {T <: Union{Int, UInt, ZZRingElem, QQFieldElem, Float64, BigFloat, RealFieldElem, AbstractString}}
    z = RealMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _arb_set(el, arr[(i-1)*c+j], prec)
      end
    end
    return z
  end

  function RealMatrix(a::QQMatrix, prec::Int)
    z = RealMatrix(a.r, a.c)
    @ccall libflint.arb_mat_set_fmpq_mat(z::Ref{RealMatrix}, a::Ref{QQMatrix}, prec::Int)::Nothing
    return z
  end
end

function _arb_mat_clear_fn(x::RealMatrix)
  @ccall libflint.arb_mat_clear(x::Ref{RealMatrix})::Nothing
end

# fixed precision

const ArbMatrixSpace = AbstractAlgebra.Generic.MatSpace{ArbFieldElem}

mutable struct ArbMatrix <: MatElem{ArbFieldElem}
  entries::Ptr{Nothing}
  r::Int
  c::Int
  rows::Ptr{Nothing}
  base_ring::ArbField

  # MatElem interface
  function ArbMatrix(R::ArbField, ::UndefInitializer, r::Int, c::Int)
    z = ArbMatrix(r, c)
    z.base_ring = R
    return z
  end

  function ArbMatrix(r::Int, c::Int)
    z = new()
    @ccall libflint.arb_mat_init(z::Ref{ArbMatrix}, r::Int, c::Int)::Nothing
    finalizer(_arb_mat_clear_fn, z)
    return z
  end

  function ArbMatrix(a::ZZMatrix)
    z = ArbMatrix(a.r, a.c)
    @ccall libflint.arb_mat_set_fmpz_mat(z::Ref{ArbMatrix}, a::Ref{ZZMatrix})::Nothing
    return z
  end

  function ArbMatrix(a::ZZMatrix, prec::Int)
    z = ArbMatrix(a.r, a.c)
    @ccall libflint.arb_mat_set_round_fmpz_mat(z::Ref{ArbMatrix}, a::Ref{ZZMatrix}, prec::Int)::Nothing
    return z
  end

  function ArbMatrix(r::Int, c::Int, arr::AbstractMatrix{T}) where {T <: Union{Int, UInt, ZZRingElem, Float64, BigFloat, ArbFieldElem}}
    z = ArbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _arb_set(el, arr[i, j])
      end
    end
    return z
  end

  function ArbMatrix(r::Int, c::Int, arr::AbstractVector{T}) where {T <: Union{Int, UInt, ZZRingElem, Float64, BigFloat, ArbFieldElem}}
    z = ArbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _arb_set(el, arr[(i-1)*c+j])
      end
    end
    return z
  end

  function ArbMatrix(r::Int, c::Int, arr::AbstractMatrix{T}, prec::Int) where {T <: Union{Int, UInt, ZZRingElem, QQFieldElem, Float64, BigFloat, ArbFieldElem, AbstractString}}
    z = ArbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _arb_set(el, arr[i, j], prec)
      end
    end
    return z
  end

  function ArbMatrix(r::Int, c::Int, arr::AbstractVector{T}, prec::Int) where {T <: Union{Int, UInt, ZZRingElem, QQFieldElem, Float64, BigFloat, ArbFieldElem, AbstractString}}
    z = ArbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _arb_set(el, arr[(i-1)*c+j], prec)
      end
    end
    return z
  end

  function ArbMatrix(a::QQMatrix, prec::Int)
    z = ArbMatrix(a.r, a.c)
    @ccall libflint.arb_mat_set_fmpq_mat(z::Ref{ArbMatrix}, a::Ref{QQMatrix}, prec::Int)::Nothing
    return z
  end
end

function _arb_mat_clear_fn(x::ArbMatrix)
  @ccall libflint.arb_mat_clear(x::Ref{ArbMatrix})::Nothing
end

################################################################################
#
#  Types and memory management for AcbMatrixSpace
#
################################################################################

const ComplexMatrixSpace = AbstractAlgebra.Generic.MatSpace{ComplexFieldElem}

mutable struct ComplexMatrix <: MatElem{ComplexFieldElem}
  entries::Ptr{Nothing}
  r::Int
  c::Int
  rows::Ptr{Nothing}
  #base_ring::AcbField

  # MatElem interface
  ComplexMatrix(::ComplexField, ::UndefInitializer, r::Int, c::Int) = ComplexMatrix(r, c)

  function ComplexMatrix(r::Int, c::Int)
    z = new()
    @ccall libflint.acb_mat_init(z::Ref{ComplexMatrix}, r::Int, c::Int)::Nothing
    finalizer(_acb_mat_clear_fn, z)
    return z
  end

  function ComplexMatrix(a::ZZMatrix)
    z = ComplexMatrix(a.r, a.c)
    @ccall libflint.acb_mat_set_fmpz_mat(z::Ref{ComplexMatrix}, a::Ref{ZZMatrix})::Nothing
    return z
  end

  function ComplexMatrix(a::ZZMatrix, prec::Int)
    z = ComplexMatrix(a.r, a.c)
    @ccall libflint.acb_mat_set_round_fmpz_mat(z::Ref{ComplexMatrix}, a::Ref{ZZMatrix}, prec::Int)::Nothing
    return z
  end

  function ComplexMatrix(a::RealMatrix)
    z = ComplexMatrix(a.r, a.c)
    @ccall libflint.acb_mat_set_arb_mat(z::Ref{ComplexMatrix}, a::Ref{ArbMatrix})::Nothing
    return z
  end

  function ComplexMatrix(a::ArbMatrix, prec::Int)
    z = ComplexMatrix(a.r, a.c)
    @ccall libflint.acb_mat_set_round_arb_mat(z::Ref{ComplexMatrix}, a::Ref{ArbMatrix}, prec::Int)::Nothing
    return z
  end

  function ComplexMatrix(r::Int, c::Int, arr::AbstractMatrix{T}) where {T <: Union{Int, UInt, Float64, ZZRingElem}}
    z = ComplexMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[i, j])
      end
    end
    return z
  end

  function ComplexMatrix(r::Int, c::Int, arr::AbstractMatrix{T}) where {T <: Union{BigFloat, ComplexFieldElem, RealFieldElem}}
    z = ComplexMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[i, j])
      end
    end
    return z
  end

  function ComplexMatrix(r::Int, c::Int, arr::AbstractVector{T}) where {T <: Union{Int, UInt, Float64, ZZRingElem}}
    z = ComplexMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[(i-1)*c+j])
      end
    end
    return z
  end

  function ComplexMatrix(r::Int, c::Int, arr::AbstractVector{T}) where {T <: Union{BigFloat, ComplexFieldElem, RealFieldElem}}
    z = ComplexMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[(i-1)*c+j])
      end
    end
    return z
  end

  function ComplexMatrix(r::Int, c::Int, arr::AbstractMatrix{T}, prec::Int) where {T <: Union{Int, UInt, ZZRingElem, QQFieldElem, Float64}}
    z = ComplexMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[i, j], prec)
      end
    end
    return z
  end

  function ComplexMatrix(r::Int, c::Int, arr::AbstractMatrix{T}, prec::Int) where {T <: Union{BigFloat, RealFieldElem, AbstractString, ComplexFieldElem}}
    z = ComplexMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[i, j], prec)
      end
    end
    return z
  end

  function ComplexMatrix(r::Int, c::Int, arr::AbstractVector{T}, prec::Int) where {T <: Union{Int, UInt, ZZRingElem, QQFieldElem, Float64}}
    z = ComplexMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[(i-1)*c+j], prec)
      end
    end
    return z
  end

  function ComplexMatrix(r::Int, c::Int, arr::AbstractVector{T}, prec::Int) where {T <: Union{BigFloat, RealFieldElem, AbstractString, ComplexFieldElem}}
    z = ComplexMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[(i-1)*c+j], prec)
      end
    end
    return z
  end

  function ComplexMatrix(r::Int, c::Int, arr::AbstractMatrix{Tuple{T, T}}, prec::Int) where {T <: Union{Int, UInt, Float64, ZZRingElem}}
    z = ComplexMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[i, j], prec)
      end
    end
    return z
  end

  function ComplexMatrix(r::Int, c::Int, arr::AbstractMatrix{Tuple{T, T}}, prec::Int) where {T <: Union{QQFieldElem, BigFloat, RealFieldElem, AbstractString}}
    z = ComplexMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[i, j], prec)
      end
    end
    return z
  end

  function ComplexMatrix(r::Int, c::Int, arr::AbstractVector{Tuple{T, T}}, prec::Int) where {T <: Union{Int, UInt, Float64, ZZRingElem}}
    z = ComplexMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[(i-1)*c+j], prec)
      end
    end
    return z
  end

  function ComplexMatrix(r::Int, c::Int, arr::AbstractVector{Tuple{T, T}}, prec::Int) where {T <: Union{QQFieldElem, BigFloat, RealFieldElem, AbstractString}}
    z = ComplexMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[(i-1)*c+j], prec)
      end
    end
    return z
  end

  function ComplexMatrix(a::QQMatrix, prec::Int)
    z = ComplexMatrix(a.r, a.c)
    @ccall libflint.acb_mat_set_fmpq_mat(z::Ref{ComplexMatrix}, a::Ref{QQMatrix}, prec::Int)::Nothing
    return z
  end
end

function _acb_mat_clear_fn(x::ComplexMatrix)
  @ccall libflint.acb_mat_clear(x::Ref{ComplexMatrix})::Nothing
end

# fixed precision

const AcbMatrixSpace = AbstractAlgebra.Generic.MatSpace{AcbFieldElem}

mutable struct AcbMatrix <: MatElem{AcbFieldElem}
  entries::Ptr{Nothing}
  r::Int
  c::Int
  rows::Ptr{Nothing}
  base_ring::AcbField

  # MatElem interface
  function AcbMatrix(R::AcbField, ::UndefInitializer, r::Int, c::Int)
    z = AcbMatrix(r, c)
    z.base_ring = R
    return z
  end

  function AcbMatrix(r::Int, c::Int)
    z = new()
    @ccall libflint.acb_mat_init(z::Ref{AcbMatrix}, r::Int, c::Int)::Nothing
    finalizer(_acb_mat_clear_fn, z)
    return z
  end

  function AcbMatrix(a::ZZMatrix)
    z = AcbMatrix(a.r, a.c)
    @ccall libflint.acb_mat_set_fmpz_mat(z::Ref{AcbMatrix}, a::Ref{ZZMatrix})::Nothing
    return z
  end

  function AcbMatrix(a::ZZMatrix, prec::Int)
    z = AcbMatrix(a.r, a.c)
    @ccall libflint.acb_mat_set_round_fmpz_mat(z::Ref{AcbMatrix}, a::Ref{ZZMatrix}, prec::Int)::Nothing
    return z
  end

  function AcbMatrix(a::ArbMatrix)
    z = AcbMatrix(a.r, a.c)
    @ccall libflint.acb_mat_set_arb_mat(z::Ref{AcbMatrix}, a::Ref{ArbMatrix})::Nothing
    return z
  end

  function AcbMatrix(a::ArbMatrix, prec::Int)
    z = AcbMatrix(a.r, a.c)
    @ccall libflint.acb_mat_set_round_arb_mat(z::Ref{AcbMatrix}, a::Ref{ArbMatrix}, prec::Int)::Nothing
    return z
  end

  function AcbMatrix(r::Int, c::Int, arr::AbstractMatrix{T}) where {T <: Union{Int, UInt, Float64, ZZRingElem}}
    z = AcbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[i, j])
      end
    end
    return z
  end

  function AcbMatrix(r::Int, c::Int, arr::AbstractMatrix{T}) where {T <: Union{BigFloat, AcbFieldElem, ArbFieldElem}}
    z = AcbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[i, j])
      end
    end
    return z
  end

  function AcbMatrix(r::Int, c::Int, arr::AbstractVector{T}) where {T <: Union{Int, UInt, Float64, ZZRingElem}}
    z = AcbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[(i-1)*c+j])
      end
    end
    return z
  end

  function AcbMatrix(r::Int, c::Int, arr::AbstractVector{T}) where {T <: Union{BigFloat, AcbFieldElem, ArbFieldElem}}
    z = AcbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[(i-1)*c+j])
      end
    end
    return z
  end

  function AcbMatrix(r::Int, c::Int, arr::AbstractMatrix{T}, prec::Int) where {T <: Union{Int, UInt, ZZRingElem, QQFieldElem, Float64}}
    z = AcbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[i, j], prec)
      end
    end
    return z
  end

  function AcbMatrix(r::Int, c::Int, arr::AbstractMatrix{T}, prec::Int) where {T <: Union{BigFloat, ArbFieldElem, AbstractString, AcbFieldElem}}
    z = AcbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[i, j], prec)
      end
    end
    return z
  end

  function AcbMatrix(r::Int, c::Int, arr::AbstractVector{T}, prec::Int) where {T <: Union{Int, UInt, ZZRingElem, QQFieldElem, Float64}}
    z = AcbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[(i-1)*c+j], prec)
      end
    end
    return z
  end

  function AcbMatrix(r::Int, c::Int, arr::AbstractVector{T}, prec::Int) where {T <: Union{BigFloat, ArbFieldElem, AbstractString, AcbFieldElem}}
    z = AcbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[(i-1)*c+j], prec)
      end
    end
    return z
  end

  function AcbMatrix(r::Int, c::Int, arr::AbstractMatrix{Tuple{T, T}}, prec::Int) where {T <: Union{Int, UInt, Float64, ZZRingElem}}
    z = AcbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[i, j], prec)
      end
    end
    return z
  end

  function AcbMatrix(r::Int, c::Int, arr::AbstractMatrix{Tuple{T, T}}, prec::Int) where {T <: Union{QQFieldElem, BigFloat, ArbFieldElem, AbstractString}}
    z = AcbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[i, j], prec)
      end
    end
    return z
  end

  function AcbMatrix(r::Int, c::Int, arr::AbstractVector{Tuple{T, T}}, prec::Int) where {T <: Union{Int, UInt, Float64, ZZRingElem}}
    z = AcbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[(i-1)*c+j], prec)
      end
    end
    return z
  end

  function AcbMatrix(r::Int, c::Int, arr::AbstractVector{Tuple{T, T}}, prec::Int) where {T <: Union{QQFieldElem, BigFloat, ArbFieldElem, AbstractString}}
    z = AcbMatrix(r, c)
    GC.@preserve z for i = 1:r
      for j = 1:c
        el = mat_entry_ptr(z, i, j)
        _acb_set(el, arr[(i-1)*c+j], prec)
      end
    end
    return z
  end

  function AcbMatrix(a::QQMatrix, prec::Int)
    z = AcbMatrix(a.r, a.c)
    @ccall libflint.acb_mat_set_fmpq_mat(z::Ref{AcbMatrix}, a::Ref{QQMatrix}, prec::Int)::Nothing
    return z
  end
end

function _acb_mat_clear_fn(x::AcbMatrix)
  @ccall libflint.acb_mat_clear(x::Ref{AcbMatrix})::Nothing
end


################################################################################
#
#   Type unions
#
################################################################################

const RealFieldElemOrPtr = Union{RealFieldElem, Ref{RealFieldElem}, Ptr{RealFieldElem}}
const ArbFieldElemOrPtr = Union{ArbFieldElem, Ref{ArbFieldElem}, Ptr{ArbFieldElem}}
const ComplexFieldElemOrPtr = Union{ComplexFieldElem, Ref{ComplexFieldElem}, Ptr{ComplexFieldElem}}
const AcbFieldElemOrPtr = Union{AcbFieldElem, Ref{AcbFieldElem}, Ptr{AcbFieldElem}}

const RealPolyRingElemOrPtr = Union{RealPolyRingElem, Ref{RealPolyRingElem}, Ptr{RealPolyRingElem}}
const ArbPolyRingElemOrPtr = Union{ArbPolyRingElem, Ref{ArbPolyRingElem}, Ptr{ArbPolyRingElem}}
const ComplexPolyRingElemOrPtr = Union{ComplexPolyRingElem, Ref{ComplexPolyRingElem}, Ptr{ComplexPolyRingElem}}
const AcbPolyRingElemOrPtr = Union{AcbPolyRingElem, Ref{AcbPolyRingElem}, Ptr{AcbPolyRingElem}}

const RealMatrixOrPtr = Union{RealMatrix, Ref{RealMatrix}, Ptr{RealMatrix}}
const ArbMatrixOrPtr = Union{ArbMatrix, Ref{ArbMatrix}, Ptr{ArbMatrix}}
const ComplexMatrixOrPtr = Union{ComplexMatrix, Ref{ComplexMatrix}, Ptr{ComplexMatrix}}
const AcbMatrixOrPtr = Union{AcbMatrix, Ref{AcbMatrix}, Ptr{AcbMatrix}}
