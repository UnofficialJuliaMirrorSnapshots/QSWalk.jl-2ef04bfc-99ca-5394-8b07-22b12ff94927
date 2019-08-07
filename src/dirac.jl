export
  ket,
  bra,
  ketbra,
  proj,
  res,
  unres,
  fourier_matrix


"""
    ket(index, size)

Return `index`-th base (column) vector in the `size`-dimensional vector space.
To be consistent with Julia indexing, `index` = 1, 2, ..., `size`.

# Examples

```jldoctest; setup = :(using QSWalk)
julia> ket(1, 2)
2-element SparseArrays.SparseVector{Int64,Int64} with 1 stored entry:
  [1]  =  1
```
"""
function ket(index::Int, size::Int)

  @argumentcheck size > 0 "vector size must be positive"
  @assert 1 <=  index <=  size "index must be positive and not bigger than vector size"

  ret = spzeros(Int, size)
  ret[index]  =  1
  ret
end

"""
    bra(index, size)

Return `index`-th base row vector in the `size`-dimensional vector space, with
`index` = 1, 2, ..., `size`.

# Examples

```jldoctest; setup = :(using QSWalk)
julia> bra(1, 2)
1×2 LinearAlgebra.Adjoint{Int64,SparseArrays.SparseVector{Int64,Int64}}:
 1  0
```
"""
function bra(index::Int, size::Int)
  ket(index, size)'
end

"""
    ketbra(irow, icol, size)

Return matrix acting on `size`-dimensional vector space, `irow`,
`icol` = 1, 2, ..., `size`. The matrix consists of single non-zero element
equal to one, located at position (`irow`, `icol`).

# Examples

```jldoctest; setup = :(using QSWalk)
julia> ketbra(1, 2, 3)
3×3 SparseArrays.SparseMatrixCSC{Int64,Int64} with 1 stored entry:
  [1, 2]  =  1

```
"""
function ketbra(irow::Int, icol::Int, size::Int)
  ket(irow, size)*bra(icol, size)
end

"""
    proj(index, size)

Return projector onto `index`-th base vector in `size`-dimensional vector space,
with `index` = 1, 2, ..., `size`. This is equivalent to `ketbra(index, index,
size)`.

```jldoctest; setup = :(using QSWalk)
julia> proj(1, 2)
2×2 SparseArrays.SparseMatrixCSC{Int64,Int64} with 1 stored entry:
  [1, 1]  =  1
```
"""
function proj(index::Int, size::Int)
  ketbra(index, index, size)
end

"""
    proj(vector)

Return projector onto the subspace spanned by vector `vector`.

# Examples
```jldoctest; setup = :(using QSWalk)
julia> v = 1/sqrt(2) * (ket(1, 3)+ket(3, 3))
3-element SparseArrays.SparseVector{Float64,Int64} with 2 stored entries:
  [1]  =  0.707107
  [3]  =  0.707107

julia> proj(v)
3×3 SparseArrays.SparseMatrixCSC{Float64,Int64} with 4 stored entries:
  [1, 1]  =  0.5
  [3, 1]  =  0.5
  [1, 3]  =  0.5
  [3, 3]  =  0.5
```
"""
function proj(vector::AbstractVector)
  vector*vector'
end

"""

    res(matrix)

Return vectorization of the `matrix` in the row order. This is equivalent to
`Base.vec(transpose(matrix))`.

# Examples

```jldoctest; setup = :(using QSWalk)
julia> M = reshape(1:9, (3, 3))'*1im
3×3 Array{Complex{Int64},2}:
 0+1im  0+2im  0+3im
 0+4im  0+5im  0+6im
 0+7im  0+8im  0+9im

julia> v = res(M)
9-element reshape(::LinearAlgebra.Transpose{Complex{Int64},Array{Complex{Int64},2}}, 9) with eltype Complex{Int64}:
 0 + 1im
 0 + 2im
 0 + 3im
 0 + 4im
 0 + 5im
 0 + 6im
 0 + 7im
 0 + 8im
 0 + 9im

julia> res(unres(v)) == v
true
```
"""
function res(matrix::AbstractMatrix)
  Base.vec(transpose(matrix))
end

"""

    unres(vector)

Return square matrix with elements from `vector`. The `vector` is expected to
have perfect square number of arguments.

# Examples
```jldoctest; setup = :(using QSWalk)
julia> v = collect(1:9)*im
9-element Array{Complex{Int64},1}:
 0 + 1im
 0 + 2im
 0 + 3im
 0 + 4im
 0 + 5im
 0 + 6im
 0 + 7im
 0 + 8im
 0 + 9im

julia> unres(v)
3×3 LinearAlgebra.Transpose{Complex{Int64},Array{Complex{Int64},2}}:
 0+1im  0+2im  0+3im
 0+4im  0+5im  0+6im
 0+7im  0+8im  0+9im

julia> res(unres(v)) == v
true
```
"""
function unres(vector::AbstractVector)
  dim = floor(Int64, sqrt(length(vector)))
  @argumentcheck dim*dim == length(vector) "Expected vector with perfect square number of elements."

  transpose(reshape(vector, (dim, dim)))
end


"""

    fourier_matrix(size)

Returns Fourier matrix of size `size`×`size`.

# Examples

```jldoctest; setup = :(using QSWalk)
julia> fourier_matrix(1)
1×1 SparseArrays.SparseMatrixCSC{Complex{Float64},Int64} with 1 stored entry:
  [1, 1]  =  1.0+0.0im

julia> fourier_matrix(2)
2×2 SparseArrays.SparseMatrixCSC{Complex{Float64},Int64} with 4 stored entries:
  [1, 1]  =  1.0+0.0im
  [2, 1]  =  1.0+0.0im
  [1, 2]  =  1.0+0.0im
  [2, 2]  =  -1.0+1.22465e-16im

```
"""
function fourier_matrix(size::Int)
  @argumentcheck size>0 "Size of the matrix needs to be positive"
  sparse([exp(2im*π*(i-1)*(j-1)/size) for i = 1:size, j = 1:size])
end
