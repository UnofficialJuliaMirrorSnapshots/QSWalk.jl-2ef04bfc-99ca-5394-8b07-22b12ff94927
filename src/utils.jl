export
  SparseDenseMatrix,
  SparseDenseVector,
  Vertex,
  VertexSet,
  vertexsetsize,
  subspace,
  vlist,
  length

import Base: ==, hash, getindex, length

macro argumentcheck(ex, msgs...)
    msg = isempty(msgs) ? ex : msgs[1]
    if isa(msg, AbstractString)
        msg = msg # pass-through
    elseif !isempty(msgs) && (isa(msg, Expr) || isa(msg, Symbol))
        #message is an expression needing evaluating
        msg = :(Main.Base.string($(esc(msg))))
    #elseif isdefined(Main, :Base) && isdefined(Main.Base, :string) && applicable(Main.Base.string, msg)
        #msg = Main.Base.string(msg)
    #else
        # string() might not be defined during bootstrap
        #msg = :(Main.Base.string($(Expr(:quote, msg))))
    end
    return :($(esc(ex)) ? $(nothing) : throw(Main.Base.ArgumentError($msg)))
end

"""
    type Vertex

Type consisting of list of `Int`, describing the labels of vectors from the
canonical basis corresponding to the `Vertex`. To get the vector label one can
use `Vertex()` function, or `Vertex[i]` for a unique label.

See [1] for the more information and usage exmaples.

[1] K. Domino, A. Glos, M. Ostaszewski, Superdiffusive quantum stochastic walk
definable on arbitrary directed graph, Quantum Information & Computation,
Vol.17 No.11&12, pp. 0973-0986, arXiv:1701.04624.
"""
struct Vertex
  subspace::Vector{Int}

  Vertex(v::Vector{Int}) = all(v.>0) ? new(v) : throw(ArgumentError("Vector should consist of positive elments"))
end

"""
    subspace(v)

Returns the subspace connected to vertex `v`.

```jldoctest; setup = :(using QSWalk)
julia> v = Vertex([1,2,3])
Vertex([1, 2, 3])

julia> subspace(v)
3-element Array{Int64,1}:
 1
 2
 3
```
"""
subspace(v::Vertex) = v.subspace

==(v::Vertex, w::Vertex) = subspace(v) == subspace(w)
hash(v::Vertex) = hash(subspace(v))

==(v::Tuple{Vertex, Vertex}, w::Tuple{Vertex, Vertex}) = [subspace(v[1]), subspace(v[2])] == [subspace(w[1]), subspace(w[2])]
hash(v::Tuple{Vertex, Vertex}) = hash([subspace(v[1]), subspace(v[2])])
getindex(v::Vertex, i::Int) = v.subspace[i]

length(v::Vertex) = length(subspace(v))


function checkvertexset(partition::Vector{Vector{Int}})
  joined = Int[]
  for lin = partition
    append!(joined, lin)
  end
  length(joined) == length(Set(joined))
end

checkvertexset(vset::Vector{Vertex}) = checkvertexset([subspace(v) for v = vset])

"""
    type VertexSet

Type consisting of a list of `Vertex` objects. It describes the partition of the
linear subspace. Object of this type should be constructed using
`make_vertex_set` or by `nm_lind` functions. In order to get a
list of the vertices from an object of type `vertexset`, one should use
`vlist` function, or, for a specific `Vertex`, an getindex function
`vertexset[i]`.
"""
struct VertexSet
  vertices::Vector{Vertex}

  VertexSet(vset::Vector{Vertex}) = checkvertexset(vset) ? new(vset) : throw(ArgumentError("Vertices should correspond to orthogonal linear spaces"))
end

VertexSet(vset::Vector{Vector{Int}}) = VertexSet([Vertex(v) for v = vset])

"""
    vlist(vset)

Returns the list of vertices for given `vset` of type `VertexSet`.

```jldoctest; setup = :(using QSWalk)
julia> vset = VertexSet([[1], [2, 3, 4], [5, 6, 7], [8, 9]])
VertexSet(Vertex[Vertex([1]), Vertex([2, 3, 4]), Vertex([5, 6, 7]), Vertex([8, 9])])

julia> vlist(vset)
4-element Array{Vertex,1}:
 Vertex([1])
 Vertex([2, 3, 4])
 Vertex([5, 6, 7])
 Vertex([8, 9])
```
"""
vlist(vset::VertexSet) = vset.vertices

==(v::VertexSet, w::VertexSet) = v.vertices == w.vertices

getindex(vset::VertexSet, i::Int) = vlist(vset)[i]
getindex(vset::VertexSet, veci::Vector{Int}) = vlist(vset)[veci]
length(vset::VertexSet) = length(vlist(vset))

"""
    vertexsetsize(vertexset)

Return the dimension of the linearspace corresponding to given `vertexset`.

# Examples

```jldoctest; setup = :(using QSWalk)
julia> vertexsetsize(VertexSet([[1, 2, 3], [4, 5]]))
5
```
"""
function vertexsetsize(vset::VertexSet)
  sum(length.(vlist(vset)))
end


"""

    incidence_list(A[; epsilon])

Return list of indices of non-zero elements of the matrix `A`. The `i`-th element of the
result list is the vector of indices `j` for which `abs(A[j, i]) >=  epsilon`.

# Examples

```jldoctest; setup = :(using QSWalk)
julia> A = [1 2 3; 0 3. 4.; 0 0 5.]
3×3 Array{Float64,2}:
 1.0  2.0  3.0
 0.0  3.0  4.0
 0.0  0.0  5.0

julia> QSWalk.incidence_list(A)
3-element Array{Array{Int64,1},1}:
 [1]
 [1, 2]
 [1, 2, 3]

julia> QSWalk.incidence_list(A, epsilon = 2.5)
3-element Array{Array{Int64,1},1}:
 []
 [2]
 [1, 2, 3]

```
"""
function incidence_list(A::AbstractMatrix{<:Number};
                        epsilon::Real = eps())
  @argumentcheck epsilon >= 0 "epsilon needs to be nonnegative"
  @argumentcheck size(A, 1) == size(A, 2) "A matrix must be square"
  [findall(x -> abs(x)>= epsilon, A[:, i]) for i = 1:size(A, 1)]
end

"""

    reversed_incidence_list(A[; epsilon])

For given matrix `A` the function returns list of indices. The `i`-th element of
result list is the vector of indices for which `abs(A[i, j]) >=  epsilon`.

# Examples

```jldoctest; setup = :(using QSWalk)
julia> A = [1 2 3; 0 3. 4.; 0 0 5.]
3×3 Array{Float64,2}:
 1.0  2.0  3.0
 0.0  3.0  4.0
 0.0  0.0  5.0

julia> QSWalk.reversed_incidence_list(A)
3-element Array{Array{Int64,1},1}:
 [1, 2, 3]
 [2, 3]
 [3]

julia> QSWalk.reversed_incidence_list(A, epsilon = 2.5)
3-element Array{Array{Int64,1},1}:
 [3]
 [2, 3]
 [3]
```
"""
function reversed_incidence_list(A::AbstractMatrix; epsilon::Real = eps())
  incidence_list(transpose(A), epsilon = epsilon)
end

"""

    revinc_to_vertexset(revincidence_list)

Return `vertexset` of type `VertexSet` corresponding to given list of indices.
The function map to consecutive element list orthogonal subspaces. The
dimensions of the subspaces equal to size of each element of revincidence_list.
The exception is empty list, for which onedimensional subspace is attached.

# Examples

```jldoctest; setup = :(using QSWalk)
julia> vset = [Int64[], [2], [1, 2, 3]]
3-element Array{Array{Int64,1},1}:
 []
 [2]
 [1, 2, 3]

julia> vlist(QSWalk.revinc_to_vertexset(vset))
3-element Array{Vertex,1}:
 Vertex([1])
 Vertex([2])
 Vertex([3, 4, 5])

```
"""
function revinc_to_vertexset(revincidence_list::Vector{Vector{Int}})
  vertexset = Vector{Int}[]
  start = 1
  for i = revincidence_list
    if length(i)!= 0
      push!(vertexset, collect(start:(start+length(i)-1)))
      start+= length(i)
    else
      push!(vertexset, [start])
      start +=  1
    end
  end
  VertexSet(vertexset)
end

"""

    make_vertex_set(A[, epsilon])

Creates object of type `VertexSet` which represents how vertices are located in
matrix. Should be used only in the nondefault use of `evolve_generator` function.
It is always equal to the second element if output of `evolve_generator` function.

# Examples

```jldoctest; setup = :(using QSWalk)
julia> A = [1 2 3; 0 3. 4.; 0 0 5.]
3×3 Array{Float64,2}:
 1.0  2.0  3.0
 0.0  3.0  4.0
 0.0  0.0  5.0

julia> vlist(make_vertex_set(A))
3-element Array{Vertex,1}:
 Vertex([1, 2, 3])
 Vertex([4, 5])
 Vertex([6])

julia> vlist(make_vertex_set(A, epsilon = 2.5))
3-element Array{Vertex,1}:
 Vertex([1])
 Vertex([2, 3])
 Vertex([4])
```
"""
function make_vertex_set(A::AbstractMatrix; epsilon::Real = eps())
  @argumentcheck epsilon >= 0 "epsilon needs to be nonnegative"
  @argumentcheck size(A, 1) == size(A, 2) "A matrix must be square"
  revinc_to_vertexset(reversed_incidence_list(A, epsilon = epsilon))
end
