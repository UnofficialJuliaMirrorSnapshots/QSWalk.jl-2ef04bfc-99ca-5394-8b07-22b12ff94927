export
  default_nm_loc_ham,
  nm_loc_ham,
  nm_lind,
  make_vertex_set,
  nm_glob_ham,
  nm_init,
  nm_measurement

"""

    default_nm_loc_ham(size)

Return default local Hamiltonian of size `size`×`size` for the demoralization
procedure. The Hamiltonian is sparse with nonzero elements on the first
upper diagonal (equal to `1im`) and lower diagonal (equal to `-1im`).

*Note:* This function is used to provide the default argument for
`nm_loc_ham` function.

# Examples

```jldoctest
julia> QSWalk.default_nm_loc_ham(4)
4×4 SparseArrays.SparseMatrixCSC{Complex{Float64},Int64} with 6 stored entries:
  [2, 1]  =  0.0-1.0im
  [1, 2]  =  0.0+1.0im
  [3, 2]  =  0.0-1.0im
  [2, 3]  =  0.0+1.0im
  [4, 3]  =  0.0-1.0im
  [3, 4]  =  0.0+1.0im
```
"""
function default_nm_loc_ham(size::Int)
  @argumentcheck size>0 "Size of default local Hamiltonian needs to be positive"
  if size == 1
    return spzeros(ComplexF64, 1, 1)
  else
    spdiagm(1=>im*ones(size-1), -1=>-im*ones(size-1))
  end
end

"""

    nm_loc_ham(vertexset[, hamiltoniansByDegree])

Return Hamiltonian acting locally on each vertex from `vertexset` linear
subspace. `hamiltoniansByDegree` is a dictionary `Dict{Int,
SparseDenseMatrix}`, which, for a given dimension of vertex linear subspace,
yields a hermitian operator. Only matrices for existing dimensions needs to be
specified.

*Note:* Value of `vertexset` should be generated by `make_vertex_set` in order
to match demoralization procedure. Numerical analysis suggests, that
hamiltonians should be complex valued.

# Examples

```jldoctest
julia> vset = VertexSet([[1, 2], [3, 4]])
VertexSet(Vertex[Vertex([1, 2]), Vertex([3, 4])])

julia> Matrix(nm_loc_ham(vset))
4×4 Array{Complex{Float64},2}:
 0.0+0.0im  0.0+1.0im  0.0+0.0im  0.0+0.0im
 0.0-1.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+1.0im
 0.0+0.0im  0.0+0.0im  0.0-1.0im  0.0+0.0im

julia> A = [1 1im; -1im 1]
2×2 Array{Complex{Int64},2}:
 1+0im  0+1im
 0-1im  1+0im

julia> nm_loc_ham(vset, Dict{Int,Matrix{ComplexF64}}(2  => A))
4×4 SparseArrays.SparseMatrixCSC{Complex{Float64},Int64} with 8 stored entries:
  [1, 1]  =  1.0+0.0im
  [2, 1]  =  0.0-1.0im
  [1, 2]  =  0.0+1.0im
  [2, 2]  =  1.0+0.0im
  [3, 3]  =  1.0+0.0im
  [4, 3]  =  0.0-1.0im
  [3, 4]  =  0.0+1.0im
  [4, 4]  =  1.0+0.0im
```
"""
function nm_loc_ham(vset::VertexSet,
                    hamiltonians::Dict{Int, <:AbstractMatrix{<:Number}}
                        = Dict(l =>default_nm_loc_ham(l) for l = length.(vlist(vset))))
  @argumentcheck all([size(h, 1) == size(h, 2) for h = values(hamiltonians)])  "Hamiltonians must consists of square matrices"
  verticeslengths = length.(vlist(vset))
  @assert all([l in keys(hamiltonians) for l = verticeslengths]) "Missing degree in the Dictionary: $verticeslengths needed"

  hamiltonianlist = Dict{Vertex,AbstractMatrix{<:Number}}(v =>hamiltonians[length(v)] for v = vlist(vset))
  nm_loc_ham(vset, hamiltonianlist)
end

"""

    nm_loc_ham(vertexset[, hamiltoniansByVertex])

Return Hamiltonian acting locally on each vertex from `vertexset` linear
subspace. `hamiltoniansByVertex` is a dictionary
`Dict{Vertex, SparseDenseMatrix}`, which, for a given vertex, yields a hermitian
operator of the size equal to the dimension of the vertex subspace.

*Note:* Value of `vertexset` should be generated by `make_vertex_set` in order
to match demoralization procedure. Numerical analysis suggests, that
hamiltonians should be complex valued.

# Examples

```jldoctest
julia> vset = VertexSet([[1, 2], [3, 4]])
VertexSet(Vertex[Vertex([1, 2]), Vertex([3, 4])])

julia> Matrix(nm_loc_ham(vset))
4×4 Array{Complex{Float64},2}:
 0.0+0.0im  0.0+1.0im  0.0+0.0im  0.0+0.0im
 0.0-1.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+1.0im
 0.0+0.0im  0.0+0.0im  0.0-1.0im  0.0+0.0im

julia> A, B = [1 1im; -1im 1], [0 1; 1 0]
(Complex{Int64}[1+0im 0+1im; 0-1im 1+0im], [0 1; 1 0])

julia> v1, v2 = vlist(vset)
2-element Array{Vertex,1}:
 Vertex([1, 2])
 Vertex([3, 4])

julia> nm_loc_ham(vset, Dict{Vertex,Matrix{Number}}(v1  => A, v2  => B))
4×4 SparseArrays.SparseMatrixCSC{Complex{Float64},Int64} with 6 stored entries:
  [1, 1]  =  1.0+0.0im
  [2, 1]  =  0.0-1.0im
  [1, 2]  =  0.0+1.0im
  [2, 2]  =  1.0+0.0im
  [4, 3]  =  1.0+0.0im
  [3, 4]  =  1.0+0.0im
```
"""
function nm_loc_ham(vset::VertexSet,
                    hamiltonians::Dict{Vertex,<:AbstractMatrix{<:Number}})
  @argumentcheck all([size(h, 1) == size(h, 2) for h = values(hamiltonians)])  "Hamiltonians must consists of square matrices"
  @assert all([v in keys(hamiltonians) for v = vlist(vset)]) "Missing hamiltonian for some vertex"
  @assert all([length(v) == size(hamiltonians[v], 1) for v = vlist(vset)]) "The vertex length and hamiltonian size do no match"

  result = spzeros(ComplexF64, vertexsetsize(vset), vertexsetsize(vset))
  for v = vlist(vset)
    result[subspace(v), subspace(v)] = hamiltonians[v]
  end
  result
end

"""

    nm_lind(A[, lindbladians][, epsilon])

Return single Lindbladian operator and a vertex set describing how vertices are
bound to subspaces. The operator is constructed according to the
corection scheme presented in [1]. Parameter `A` is a square matrix, describing
the connection between the canonical subspaces in a similar manner as the adjacency matrix.
Parameter `epsilon`, with the default value `eps()`, determines the relevant
values by `abs(A[i, j]) >=  epsilon` formula. List `lindbladians` describes the
elementary matrices used. It can be `Dict{Int, SparseDenseMatrix}`,
which returns the matrix by the indegree, or `Dict{Vertex, SparseDenseMatrix}`
which, for different vertices, may return different
matrix. The matrix should have orthogonal columns and be of the size
outdeg of the vertex. As default the function uses Fourier matrices.

*Note:* It is expected that for all pair of vertices there exists a matrix in the
`lindbladians` list.

*Note:* The orthogonality of matrices in `lindbladians` is not verified.

*Note:* The submatrices of the result matrix are multiplied by corresponding `A`
element.

[1] K. Domino, A. Glos, M. Ostaszewski, Superdiffusive quantum stochastic walk
definable on arbitrary directed graph, Quantum Information & Computation,
Vol.17 No.11&12, pp. 0973-0986, arXiv:1701.04624.

# Examples

```jldoctest
julia> A = [0 1 0; 1 0 1; 0 1 0]
3×3 Array{Int64, 2}:
 0  1  0
 1  0  1
 0  1  0

julia> L, vset = nm_lind(A)
(
  [2, 1] = 1.0+0.0im
  [3, 1] = 1.0+0.0im
  [1, 2] = 1.0+0.0im
  [4, 2] = 1.0+0.0im
  [1, 3] = 1.0+0.0im
  [4, 3] = 1.0+0.0im
  [2, 4] = 1.0+0.0im
  [3, 4] = -1.0+1.22465e-16im, QSWalk.VertexSet(QSWalk.Vertex[QSWalk.Vertex([1]), QSWalk.Vertex([2, 3]), QSWalk.Vertex([4])]))

julia> B1, B2 = 2*eye(1), 3*ones(2, 2)
([2.0], [3.0 3.0; 3.0 3.0])

julia> nm_lind(A, Dict(1  => B1, 2 =>B2 ))
(
  [2, 1] = 3.0+0.0im
  [3, 1] = 3.0+0.0im
  [1, 2] = 2.0+0.0im
  [4, 2] = 2.0+0.0im
  [1, 3] = 2.0+0.0im
  [4, 3] = 2.0+0.0im
  [2, 4] = 3.0+0.0im
  [3, 4] = 3.0+0.0im, QSWalk.VertexSet(QSWalk.Vertex[QSWalk.Vertex([1]), QSWalk.Vertex([2, 3]), QSWalk.Vertex([4])]))

julia> v1, v2, v3 = vlist(vset)
3-element Array{QSWalk.Vertex, 1}:
 QSWalk.Vertex([1])
 QSWalk.Vertex([2, 3])
 QSWalk.Vertex([4])

 julia> nm_lind(A, Dict(v1  => ones(1, 1), v2  => [2 2; 2 -2], v3 =>3*ones(1, 1)))[1] |> full
 4×4 Array{Complex{Float64}, 2}:
  0.0+0.0im  1.0+0.0im  1.0+0.0im   0.0+0.0im
  2.0+0.0im  0.0+0.0im  0.0+0.0im   2.0+0.0im
  2.0+0.0im  0.0+0.0im  0.0+0.0im  -2.0+0.0im
  0.0+0.0im  3.0+0.0im  3.0+0.0im   0.0+0.0im
```
"""
function nm_lind(A::AbstractMatrix{<:Number},
                 lindbladians::Dict{Int, <:AbstractMatrix{<:Number}};
                 epsilon::Real = eps())
  @argumentcheck epsilon>= 0 "epsilon needs to be nonnegative"

  revincidence_list = reversed_incidence_list(A, epsilon = epsilon)
  vset = revinc_to_vertexset(revincidence_list)
  verticeslengths = length.(vlist(vset))

  @assert all([ l in keys(lindbladians) for l = verticeslengths]) "Missing degrees in lindbladians: $verticeslengths needed"

  L = spzeros(ComplexF64, vertexsetsize(vset), vertexsetsize(vset))
  for i = 1:size(A, 1), (index, j) = enumerate(revincidence_list[i]), k in subspace(vset[j])
      L[subspace(vset[i]), k] = A[i, j]*lindbladians[length(vset[i])][:, index]
  end
  L, vset
end,

function nm_lind(A::AbstractMatrix{<:Number};
                 epsilon::Real = eps())
  vset = make_vertex_set(A, epsilon = epsilon)
  degrees = [length(v) for v = vlist(vset)]

  nm_lind(A, Dict(d =>fourier_matrix(d) for d = degrees), epsilon = epsilon)
end,

function nm_lind(A::AbstractMatrix{<:Number},
                 lindbladians::Dict{Vertex, <:AbstractMatrix{<:Number}};
                 epsilon::Real = eps())
  @argumentcheck all([size(l, 1) == size(l, 2) for l = values(lindbladians)])  "lindbladians should consist of square matrix"
  @argumentcheck epsilon>= 0 "epsilon needs to be nonnegative"

  revincidence_list = reversed_incidence_list(A; epsilon = epsilon)
  vset = revinc_to_vertexset(revincidence_list)

  @argumentcheck all([ v in keys(lindbladians) for v = vlist(vset)]) "Some vertex is missing in lindbladians"
  @argumentcheck all([ length(v) == size(lindbladians[v], 1) for v = vlist(vset)]) "Size of the lindbladians should equal to indegree of the vertex"

  L = spzeros(ComplexF64, vertexsetsize(vset), vertexsetsize(vset))
  for i = 1:size(A, 1), (index, j) = enumerate(revincidence_list[i]), l = subspace(vset[j])
    L[subspace(vset[i]), l] = A[i, j]*lindbladians[vset[i]][:, index]
  end
  L, vset
end

"""

    nm_glob_ham(A[, hamiltonians][, epsilon])

Return global Hamiltonian for the moralization procedure. Matrix `A` should the
adjacency matrix of a directed graph, for which one aims to construct the
nonmoralizing dynamics. Here, `hamiltonians` is an optional argument which is a
Dictionary with keys of type `Tuple{Int, Int}` or `Tuple{Vertex, Vertex}`. The
first collects the submatrices according to their shape, while the second
collects them according to each pair of vertices. As the default all-one
submatrices are chosen. The last argument states that only those elements for
which `abs(A[i, j]) >= epsilon` are considered.

*Note:* The submatrices of the result matrix are scaled by corresponding `A`
element.

# Examples

```jldoctest
julia> A = [ 0 1 0; 1 0 1; 0 1 0]
3×3 Array{Int64, 2}:
 0  1  0
 1  0  1
 0  1  0

julia> nm_glob_ham(A) |> full
4×4 Array{Complex{Float64}, 2}:
 0.0+0.0im  1.0+0.0im  1.0+0.0im  0.0+0.0im
 1.0+0.0im  0.0+0.0im  0.0+0.0im  1.0+0.0im
 1.0+0.0im  0.0+0.0im  0.0+0.0im  1.0+0.0im
 0.0+0.0im  1.0+0.0im  1.0+0.0im  0.0+0.0im

julia> nm_glob_ham(A, Dict((1, 2) => (2+1im)*ones(1, 2), (2, 1) =>1im*ones(2, 1))) |> full
4×4 Array{Complex{Float64}, 2}:
 0.0+0.0im  2.0+1.0im  2.0+1.0im  0.0+0.0im
 2.0-1.0im  0.0+0.0im  0.0+0.0im  0.0+1.0im
 2.0-1.0im  0.0+0.0im  0.0+0.0im  0.0+1.0im
 0.0+0.0im  0.0-1.0im  0.0-1.0im  0.0+0.0im

julia> v1, v2, v3 = make_vertex_set(A)()
3-element Array{QSWalk.Vertex, 1}:
 QSWalk.Vertex([1])
 QSWalk.Vertex([2, 3])
 QSWalk.Vertex([4])

julia> nm_glob_ham(A, Dict((v1, v2) =>2*ones(1, 2), (v2, v3) =>[1im 2im;]')) |> full
4×4 Array{Complex{Float64}, 2}:
 0.0+0.0im  2.0+0.0im  2.0+0.0im  0.0+0.0im
 2.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+1.0im
 2.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+2.0im
 0.0+0.0im  0.0-1.0im  0.0-2.0im  0.0+0.0im
```
"""
function nm_glob_ham(A::AbstractMatrix{<:Number},
                     hamiltonians::Dict{Tuple{Int, Int}, <:AbstractMatrix{<:Number}};
                     epsilon::Real = eps())
  @argumentcheck epsilon>= 0 "epsilon needs to be nonnegative"

  revincidence_list = reversed_incidence_list(A, epsilon = epsilon)
  vset = revinc_to_vertexset(revincidence_list)

  H = spzeros(ComplexF64, vertexsetsize(vset), vertexsetsize(vset))
  for (index, i) = enumerate(revincidence_list), j = i
    if index < j
      hamiltonianshape = length.((subspace(vset[index]), subspace(vset[j])))
      @argumentcheck hamiltonianshape in keys(hamiltonians) "hamiltonian of size $hamiltonianshape not found"
      @argumentcheck hamiltonianshape == size(hamiltonians[hamiltonianshape]) "hamiltonian for key $(hamiltonianshape) shoud have shape $(hamiltonianshape)"
      H[subspace(vset[index]), subspace(vset[j])] = A[index, j]*hamiltonians[hamiltonianshape]
    end
  end
  H + H'
end,

function nm_glob_ham(A::T;
                     epsilon::Real = eps()) where T<:AbstractMatrix{<:Number}
  #indlist = incidence_list(A, epsilon = epsilon)
  revindlist = reversed_incidence_list(A, epsilon = epsilon)

  alloneshamiltonians = Dict{Tuple{Int, Int}, T}()
  for v = revindlist, w = v
    w = revindlist[w]
    length_w = max(1, length(w))
    length_v = max(1, length(v))
    alloneshamiltonians[(length_v, length_w)] = ones(length_v, length_w)
    alloneshamiltonians[(length_w, length_v)] = ones(length_w, length_v)
  end
  nm_glob_ham(A, alloneshamiltonians, epsilon = epsilon)
end,

function nm_glob_ham(A::AbstractMatrix{<:Number},
                     hamiltonians::Dict{Tuple{Vertex, Vertex}, <:AbstractMatrix{<:Number}};
                     epsilon::Real = eps())
  @argumentcheck epsilon >= 0 "epsilon needs to be nonnegative"
  revincidence_list = reversed_incidence_list(A, epsilon = epsilon)
  vset = revinc_to_vertexset(revincidence_list)

  H = spzeros(ComplexF64, vertexsetsize(vset), vertexsetsize(vset))
  for (index, i) = enumerate(revincidence_list), j = i
    if index < j
      key = (vset[index], vset[j])
      @argumentcheck key in keys(hamiltonians) "hamiltonian for $key not found"
      @argumentcheck length.(key) == size(hamiltonians[key]) "hamiltonian for key $key shoud have shape $(length.(key))"
      H[subspace(vset[j]), subspace(vset[index])] = A[index, j]*transpose(hamiltonians[key])
    end
  end
  H + H'
end

"""

    nm_measurement(probability, vertexset)

Return joint probability of `probability`, which is real-valued probability vector
according to `vertexset`.

*Note:* It is up to user to provide proper probability vector.

# Examples

```jldoctest
julia> probability = [0.05, 0.1, 0.25, 0.3, 0.01, 0.20, 0.04, 0.05]
8-element Array{Float64,1}:
 0.05
 0.1
 0.25
 0.3
 0.01
 0.2
 0.04
 0.05

julia> nm_measurement(probability, VertexSet([[1, 4], [2, 3, 5], [6], [7, 8]]))
4-element Array{Float64,1}:
 0.35
 0.36
 0.2
 0.09
```
"""
function nm_measurement(probability::AbstractVector{<:Number},
                        vset::VertexSet)
  @assert vertexsetsize(vset) == length(probability) "vertexset size and probability vector length do not match"

  [sum(probability[subspace(vertex)]) for vertex = vlist(vset)]
end

"""

    nm_measurement(state, vertexset)

Return joint probability of cannonical measurement of density matrix `state`,
according to `vertexset`.

*Note:* It is up to user to provide proper density state.

# Examples

```jldoctest
julia> state = [1/6 0 1/6; 0 2/3 0; 1/6 0 1/6]
3×3 Array{Float64,2}:
 0.166667  0.0       0.166667
 0.0       0.666667  0.0
 0.166667  0.0       0.166667

julia> nm_measurement(state, VertexSet([[1, 3], [2]]))
2-element Array{Float64,1}:
 0.3333333333333333
 0.6666666666666666
```
"""
function nm_measurement(state::AbstractMatrix{<:Number},
                        vset::VertexSet)
  @argumentcheck size(state, 1) == size(state, 2) "state should be square matrix"
  @assert vertexsetsize(vset) == size(state, 1) "vertexset size and state size do not match"

  nm_measurement(real.(diag(state)), vset)
end

"""
    nm_init(init_vertices, vertexset)

Create initial state in the case of the nonmoralizing evolution based on
`init_vertices` of type `Vector{Vertex}`. The result is
a block diagonal matrix, where each block corresponds to vertex from `vertexset`.
The final state represent an uniform probability over `nm_measurement`.

*Note:* The function returns sparse matrix with `ComplexF64` field type.

# Examples

```jldoctest
julia> vset = VertexSet([[1], [2, 3, 4], [5, 6, 7], [8, 9]])
VertexSet(Vertex[Vertex([1]), Vertex([2, 3, 4]), Vertex([5, 6, 7]), Vertex([8, 9])])

julia> nm_init(vset[[1, 3, 4]], vset)
9×9 SparseArrays.SparseMatrixCSC{Complex{Float64},Int64} with 6 stored entries:
  [1, 1]  =  0.333333+0.0im
  [5, 5]  =  0.111111+0.0im
  [6, 6]  =  0.111111+0.0im
  [7, 7]  =  0.111111+0.0im
  [8, 8]  =  0.166667+0.0im
  [9, 9]  =  0.166667+0.0im
```
"""
function nm_init(initialvertices::AbstractVector{Vertex},
                 vset::VertexSet)
  @assert all([v in vlist(vset) for v = initialvertices]) "initialvertices is not a subset of vertexset"

  L = spzeros(ComplexF64, vertexsetsize(vset), vertexsetsize(vset))
  for v = initialvertices
    normalization = length(v)*length(initialvertices)
    L[subspace(v), subspace(v)] = SparseMatrixCSC{ComplexF64}(I, length(v), length(v))/normalization
  end
  L
end

"""
    nm_init(init_states, vertexset)

Create initial state in the case of the nonmoralizing evolution based on `init_states`
of type `Dict{Vertex, <:AbstractMatrix{<:Number}}`. For each given vertex a block
from dictionary is used, otherwise zero matrix is chosen. Each matrix from
dictionary should be nonnegative and sum of all traces should equal one. The
keys of `init_vertices` should be a vertices from `vertexset`.
Note that matrix from `init_states` corresponding to vertex `v` should be of
size `length(v)`×`length(v)`.

*Note:* The function returns sparse matrix with `ComplexF64` field type.

# Examples

```jldoctest
julia> vset = VertexSet([[1], [2, 3, 4], [5, 6, 7], [8, 9]])
VertexSet(Vertex[Vertex([1]), Vertex([2, 3, 4]), Vertex([5, 6, 7]), Vertex([8, 9])])

julia> A1, A2, A3 = ones(ComplexF64, 1, 1)/4, [ 1/5+0im 0 1/5; 0 1/10 0 ; 1/5 0 1/5 ], [0.125 -0.125+0im; -0.125 0.125]
(Complex{Float64}[0.25+0.0im], Complex{Float64}[0.2+0.0im 0.0+0.0im 0.2+0.0im; 0.0+0.0im 0.1+0.0im 0.0+0.0im; 0.2+0.0im 0.0+0.0im 0.2+0.0im], Complex{Float64}[0.125+0.0im -0.125+0.0im; -0.125+0.0im 0.125+0.0im])

julia> nm_init(Dict(vset[1] =>A1, vset[3] =>A2, vset[4] =>A3), vset)
9×9 SparseArrays.SparseMatrixCSC{Complex{Float64},Int64} with 10 stored entries:
  [1, 1]  =  0.25+0.0im
  [5, 5]  =  0.2+0.0im
  [7, 5]  =  0.2+0.0im
  [6, 6]  =  0.1+0.0im
  [5, 7]  =  0.2+0.0im
  [7, 7]  =  0.2+0.0im
  [8, 8]  =  0.125+0.0im
  [9, 8]  =  -0.125+0.0im
  [8, 9]  =  -0.125+0.0im
  [9, 9]  =  0.125+0.0im

```
"""
function nm_init(initial_states::Dict{Vertex, <:AbstractMatrix{<:Number}},
                 vset::VertexSet)
  @assert all([size(state, 1) == length(k) for (k, state) = initial_states]) "The size of initial state and the vertex do not match"
  @assert all([k in vlist(vset) for k = keys(initial_states)]) "keys of initial_states is not a subset of vertexset"

  L = spzeros(ComplexF64, vertexsetsize(vset), vertexsetsize(vset))
  for v = keys(initial_states)
    L[subspace(v), subspace(v)] = initial_states[v]
  end
  L
end
