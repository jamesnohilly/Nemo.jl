```@meta
CurrentModule = Nemo
DocTestSetup = quote
    using Nemo
end
```

# Residue rings

Nemo allows the creation of residue rings of the form $R/(a)$ for an element
$a$ of a ring $R$.

We don't require $(a)$ to be a prime or maximal ideal. Instead, we allow the
creation of the residue ring $R/(a)$ for any nonzero $a$ and simply raise an
exception if an impossible inverse is encountered during computations 
involving elements of $R/(a)$. Of course, a GCD function must be available for the
base ring $R$.

There is a generic implementation of residue rings of this form in AbstractAlgebra.jl,
which accepts any ring $R$ as base ring.

The associated types of parent object and elements for each kind of residue rings in
Nemo are given in the following table.

Base ring                   | Library            | Element type     | Parent type
----------------------------|--------------------|------------------|--------------------
Generic ring $R$            | AbstractAlgebra.jl | `EuclideanRingResidueRingElem{T}` | `EuclideanRingResidueRing{T}`
$\mathbb{Z}$ (Int modulus)  | FLINT              | `zzModRingElem`  | `zzModRing`
$\mathbb{Z}$ (ZZ modulus)   | FLINT              | `ZZModRingElem`  | `ZZModRing`

The modulus $a$ of a residue ring is stored in its parent object.

All residue element types belong to the abstract type `ResElem` and all the
residue ring parent object types belong to the abstract type `ResidueRing`.
This enables one to write generic functions that accept any Nemo residue type.

## Residue functionality

All the residue rings in Nemo provide the functionality described in AbstractAlgebra
for residue rings:

<https://nemocas.github.io/AbstractAlgebra.jl/stable/residue>

In addition, generic residue rings are available.

We describe Nemo specific residue ring functionality below.

### GCD

```@docs
gcdx(::zzModRingElem, ::zzModRingElem)
gcdx(::ZZModRingElem, ::ZZModRingElem)
```

**Examples**

```jldoctest
julia> R, = residue_ring(ZZ, 123456789012345678949);

julia> g, s, t = gcdx(R(123), R(456))
(1, 123456789012345678928, 41152263004115226322)
```
