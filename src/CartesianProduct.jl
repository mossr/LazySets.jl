import Base.*

export CartesianProduct,
       CartesianProductArray,
       is_contained

"""
    CartesianProduct{S1<:LazySet,S2<:LazySet} <: LazySet

Type that represents a Cartesian product of two convex sets.

### Fields

- `X` -- first convex set
- `Y` -- second convex set

### Notes

The Cartesian product of three elements is obtained recursively.
See also `CartesianProductArray` for an implementation of a Cartesian product of
many sets without recursion, instead using an array.

- `CartesianProduct{S1<:LazySet,S2<:LazySet}` -- default constructor

- `CartesianProduct(Xarr::Vector{S}) where {S<:LazySet}`
  -- constructor from an array of convex sets
"""
struct CartesianProduct{S1<:LazySet,S2<:LazySet} <: LazySet
    X::S1
    Y::S2
end
CartesianProduct(Xarr::Vector{S}) where {S<:LazySet} =
    (length(Xarr) == 0
        ? VoidSet(1)
        : length(Xarr) == 1
            ? Xarr[1]
            : length(Xarr) == 2
                ? CartesianProduct(Xarr[1], Xarr[2])
                : CartesianProduct(Xarr[1],
                                   CartesianProduct(Xarr[2:length(Xarr)])))

"""
```
    *(X::LazySet, Y::LazySet)::CartesianProduct
```

Return the Cartesian product of two convex sets.

### Input

- `X` -- convex set
- `Y` -- convex set

### Output

The Cartesian product of the two convex sets.
"""
function *(X::LazySet, Y::LazySet)::CartesianProduct
    CartesianProduct(X, Y)
end

"""
    dim(cp::CartesianProduct)

Return the dimension of a Cartesian product.

### Input

- `cp` -- Cartesian product

### Output

The ambient dimension of the Cartesian product.
"""
function dim(cp::CartesianProduct)
    return dim(cp.X) + dim(cp.Y)
end

"""
    σ(d::AbstractVector{<:Real}, cp::CartesianProduct)::AbstractVector{<:Real}

Return the support vector of a Cartesian product.

### Input

- `d`  -- direction
- `cp` -- Cartesian product

### Output

The support vector in the given direction.
If the direction has norm zero, the result depends on the product sets.
"""
function σ(d::AbstractVector{<:Real},
           cp::CartesianProduct)::AbstractVector{<:Real}
    return [σ(view(d, 1:dim(cp.X)), cp.X);
            σ(view(d, dim(cp.X)+1:length(d)), cp.Y)]
end

"""
    is_contained(x::AbstractVector{<:Real}, cp::CartesianProduct)::Bool

Return whether a given vector is contained in a Cartesian product set.

### Input

- `x`  -- vector
- `cp` -- Cartesian product

### Output

Return `true` iff ``x ∈ cp``.
"""
function is_contained(x::AbstractVector{<:Real}, cp::CartesianProduct)::Bool
    return is_contained(view(x, 1:dim(cp.X)), cp.X) &&
           is_contained(view(x, dim(cp.X)+1:length(x)), cp.Y)
end

# ======================================
#  Cartesian product of an array of sets
# ======================================
"""
    CartesianProductArray{S<:LazySet} <: LazySet

Type that represents the Cartesian product of a finite number of convex sets.

### Fields

- `sfarray` -- array of sets

### Notes

- `CartesianProductArray(sfarray::Vector{<:LazySet})` -- default constructor

- `CartesianProductArray()` -- constructor for an empty Cartesian product

- `CartesianProductArray(n::Integer)`
  -- constructor for an empty Cartesian product with size hint
"""
struct CartesianProductArray{S<:LazySet} <: LazySet
    sfarray::Vector{S}
end
# constructor for an empty Cartesian product
CartesianProductArray() = CartesianProductArray{LazySet}(Vector{LazySet}(0))
# constructor for an empty Cartesian product with size hint
function CartesianProductArray(n::Integer)::CartesianProductArray
    arr = Vector{LazySet}(0)
    sizehint!(arr, n)
    return CartesianProductArray(arr)
end

"""
```
    *(cpa::CartesianProductArray, S::LazySet)::CartesianProductArray
```

Multiply a convex set to a Cartesian product of a finite number of convex sets
from the right.

### Input

- `cpa` -- Cartesian product array (is modified)
- `S`   -- convex set

### Output

The modified Cartesian product of a finite number of convex sets.
"""
function *(cpa::CartesianProductArray, S::LazySet)::CartesianProductArray
    push!(cpa.sfarray, S)
    return cpa
end

"""
```
    *(S::LazySet, cpa::CartesianProductArray)::CartesianProductArray
```

Multiply a convex set to a Cartesian product of a finite number of convex sets
from the left.

### Input

- `S`   -- convex set
- `cpa` -- Cartesian product array (is modified)

### Output

The modified Cartesian product of a finite number of convex sets.
"""
function *(S::LazySet, cpa::CartesianProductArray)::CartesianProductArray
    push!(cpa.sfarray, S)
    return cpa
end

"""
```
    *(cpa1::CartesianProductArray, cpa2::CartesianProductArray)::CartesianProductArray
```

Multiply a finite Cartesian product of convex sets to another finite Cartesian
product.

### Input

- `cpa1` -- first Cartesian product array (is modified)
- `cpa2` -- second Cartesian product array

### Output

The modified first Cartesian product.
"""
function *(cpa1::CartesianProductArray,
           cpa2::CartesianProductArray)::CartesianProductArray
    append!(cpa1.sfarray, cpa2.sfarray)
    return cpa1
end

"""
    dim(cpa::CartesianProductArray)

Return the dimension of a Cartesian product of a finite number of convex sets.

### Input

- `cpa` -- Cartesian product array

### Output

The ambient dimension of the Cartesian product of a finite number of convex
sets.
"""
function dim(cpa::CartesianProductArray)
    return length(cpa.sfarray) == 0 ? 0 : sum([dim(sj) for sj in cpa.sfarray])
end

"""
    σ(d::AbstractVector{<:Real}, cpa::CartesianProductArray)::AbstractVector{<:Real}

Support vector of a Cartesian product.

### Input

- `d`   -- direction
- `cpa` -- Cartesian product array

### Output

The support vector in the given direction.
If the direction has norm zero, the result depends on the product sets.
"""
function σ(d::AbstractVector{<:Real},
           cpa::CartesianProductArray)::AbstractVector{<:Real}
    svec = similar(d)
    jinit = 1
    for sj in cpa.sfarray
        jend = jinit + dim(sj) - 1
        svec[jinit:jend] = σ(d[jinit:jend], sj)
        jinit = jend + 1
    end
    return svec
end

"""
    is_contained(x::AbstractVector{<:Real}, cpa::CartesianProductArray)::Bool

Return whether a given vector is contained in a Cartesian product of a finite
number of sets.

### Input

- `x`   -- vector
- `cpa` -- Cartesian product array

### Output

Return `true` iff ``x ∈ cpa``.
"""
function is_contained(x::AbstractVector{<:Real},
                      cpa::CartesianProductArray)::Bool
    jinit = 1
    for sj in cpa
        jend = jinit + dim(sj) - 1
        if !is_contained(x[jinit:jend], sj)
            return false
        end
        jinit = jend + 1
    end
    return true
end
