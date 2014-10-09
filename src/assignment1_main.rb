#
# Group 4 members: Isaac Supeene, Braeden Soetaert
#

# Below are some examples of what out code does. 
# In order to run our code you will need a script file in the src directory
# that contains the following require_relative lines. The code below can not be directly
# put into the irb interpreter because our code uses require_relative instead of require and
# the irb interpreter has a known issue with this.
#
# To run in the irb interpreter go to the src directory and run the following commands:
# >irb
# >require "./sparse_matrix_require"
# >
#
# Tests can be run if test unit is installed by requiring the test files located in the test directory

# This file requires all the files necessary to run our code. Done this way for symmetry with
# an irb version as require_relative will not work in irb.
require_relative "sparse_matrix_require"

# Contracts are enabled by default. To disable them, do the following:
# ContractDecorator.enable_contracts(false)
# And to check if they are currently enabled:
ContractDecorator.enable_contracts?

# To create a new matrix use the matrix builder class
# Can create a sparse matrix or a complete matrix through the first argument to MatrixBuilder.create
# Possible arguments: :sparse, :complete
# More matrix builders can be added to the design later if necessary.
row_size = 10
column_size = 10
sparse_builder = MatrixBuilder.create(:sparse, row_size, column_size ){ |builder|
	row_size.times.select{ |i| i % 3 == 0}.each{ |i| 
		column_size.times.select{ |j| j % 4 == 0 }.each{ |j|
			builder[i, j] = i + j + 1
		}
	}
}
sparse_matrix = sparse_builder.to_mat

# SparseMatrixBuilder will generate a TridiagonalMatrix if the matrix is in fact Tridiagonal
tri_builder = MatrixBuilder.create(:sparse, row_size, column_size ){ |builder|
	row_size.times.select{ |i| i % 3 == 0}.each{ |i| 
		column_size.times.select{ |j| (j - i).abs <= 1 }.each{ |j|
			builder[i, j] = i + j + 1
		}
	}
}
tri_matrix = tri_builder.to_mat

# Complete is actually just ruby's Matrix class itself
complete_builder = MatrixBuilder.create(:complete, row_size, column_size){ |builder|
	row_size.times.each{ |i|
		column_size.times.each{ |j|
			builder[i, j] = i + j + 1
		}
	}
}
complete_matrix = complete_builder.to_mat

# The matrices returned from to_mat are immutable. To alter the matrix, the builder must be used.
sparse_builder.each_with_index.select{ |x, i, j| x != 0}.each{ |x, i, j|
	sparse_builder[i, j] = x + 5 
}

sparse_matrix2 = sparse_builder.to_mat

# The abstract builder can also be bypassed for the sparse matrix builder to create sparse matrices
# in other ways.
sparse_matrix3 = SparseMatrixBuilder.identity(10)

# SparseMatrices and Tridiagonal matrices can be iterated over with the each_with_index, each, map
# and collect functions.
# These iterator functions take arguments for these classes that determine how they iterate. 
# Possible arguments: 
# :all - (Default) iterates over all row_size by column_size elements
# :diagonal - iterates over just the diagonal of the matrix
# :off_diagonal - iterates over just the elements not on the diagonal of the matrix
# :lower - iterates over just the elements on or below the diagonal
# :strict_lower - like lower but only those elements below the diagonal
# :upper - iterates over just the elements on or above the diagonal
# :strict_upper - like upper but only those elements above the diagonal
# :non_zero - iterates over all non-zero elements of the matrix

# All matrices produced by the builders respond to the same functions that Ruby's Matrix class responds to
# The matrix classes do not respond to the different constructors though. That is the builders' job.

####################
# Matrix Accessors #
####################
# [](i, j)
sparse_matrix[0,0]
# row_size
sparse_matrix.row_size
# column_size
sparse_matrix.column_size
# row(i)
sparse_matrix.row(0)
# column(j)
sparse_matrix.column(0)
# collect
sparse_matrix.collect{|x| x * 2}
# map
sparse_matrix.map{|x| x * 2}
# each
sparse_matrix.each{|x| puts x}
# each_with_index
sparse_matrix.each_with_index{|x,i,j| puts "[#{i},#{j}] = #{x}" }
# find_index(*args, &block) args == selector or value, selector
sparse_matrix.find_index(:all){ |x| x == 1}
sparse_matrix.find_index(1,:all)
# minor(*param)
sparse_matrix.minor(1..2,1..2)
sparse_matrix.minor(1,2,1,2)

#####################
# Matrix Properties #
#####################
# diagonal?
sparse_matrix.diagonal?
# empty?
sparse_matrix.empty?
# hermitian?
sparse_matrix.hermitian?
# lower_triangular?
sparse_matrix.lower_triangular?
# normal?
sparse_matrix.normal?
# orthogonal?
sparse_matrix3.orthogonal?
# permutation?
sparse_matrix.permutation?
# real?
sparse_matrix.real?
# regular?
sparse_matrix.regular?
# singular?
sparse_matrix.singular?
# square?
sparse_matrix.square?
# symmetric?
sparse_matrix.symmetric?
# unitary?
sparse_matrix3.unitary?
# upper_triangular?
sparse_matrix.upper_triangular?
# zero?
sparse_matrix.zero?

#####################
# Matrix Arithmetic #
#####################
# *(m)
sparse_matrix * sparse_matrix2
# +(m)
sparse_matrix + sparse_matrix2
# -(m)
sparse_matrix - sparse_matrix2
# /(m)
sparse_matrix / sparse_matrix3
# inverse
sparse_matrix3.inverse
# inv
sparse_matrix3.inv
# **
sparse_matrix2 ** 2

####################
# Matrix Functions #
####################
# determinant
sparse_matrix.determinant
# det
sparse_matrix.det
# rank
sparse_matrix.rank
# round
sparse_matrix.round(5)
# trace
sparse_matrix.trace
# tr
sparse_matrix.tr
# transpose
sparse_matrix.transpose
# t
sparse_matrix.t

#########################
# Matrix Decompositions #
#########################
# eigen This function is not working currently
# sparse_matrix.eigen
# eigensystem This function is not working currently
# sparse_matrix.eigensystem
# lup
sparse_matrix.lup
# lup_decomposition
sparse_matrix.lup_decomposition

######################
# Complex Arithmetic #
######################
# conj
sparse_matrix.conj
# conjugate
sparse_matrix.conjugate
# imag
sparse_matrix.imag
# imaginary
sparse_matrix.imaginary
# real
sparse_matrix.real
# rect
sparse_matrix.rect
# rectangular
sparse_matrix.rectangular

##############
# Conversion #
##############
# coerce(other)
# row_vectors
sparse_matrix.row_vectors
# column_vectors
sparse_matrix.column_vectors
# to_a
sparse_matrix.to_a

##########################
# String Representations #
##########################
# to_s
sparse_matrix.to_s
# inspect
sparse_matrix.inspect


# Vectors can also be built through the VectorBuilder class in a way similar to matrices.
sparse_vector = VectorBuilder.create(:sparse, row_size){ |builder| 
	row_size.times.select{|i| i % 3 == 0}.each{ |i| builder[i] = i}
}.to_vec
sparse_vector2 = VectorBuilder.create(:sparse, row_size){ |builder| 
	row_size.times.select{|i| i % 3 == 0}.each{ |i| builder[i] = i+1}
}.to_vec

# Complete Vectors are the Ruby Matrix class' Vectors so they respond to those functions
# The non-complete Vectors respond to the following functions:
#############
# Iterators #
#############
# NOTE: selector is either :all or :non_zero
# each(selector=:all)
sparse_vector.each{|x| puts x}
# each_with_index(selector=:all)
sparse_vector.each_with_index{|x,i| puts "{[#{i}] = #{x}"}
# map(selector=:all)
sparse_vector.map{|x| x == 3}
# collect(selector=:all)
sparse_vector.collect{|x| x == 3}
# each2(v)
sparse_vector.each2(sparse_vector2){|x,y| puts "#{x},#{y}"}
# each2_with_index(v)
sparse_vector.each2_with_index(sparse_vector2){|x,y,i| "{[#{i}] = #{x},#{y}"}
# map2(v)
sparse_vector.map2(sparse_vector2){|x,y| x == y}
# collect2(v) Does not work
#sparse_vector.collect2(sparse_vector2){|x,y| x == y}

##############
# Properties #
##############
# size
sparse_vector.size
# length
sparse_vector.length
# magnitude does not work
#sparse_vector.magnitude
# norm
sparse_vector.norm
# r
sparse_vector.r

##############
# Arithmetic #
##############
# *(x)
sparse_vector * sparse_vector2
# /(x) does not work
#sparse_vector / 2
# +(x)
sparse_vector + sparse_vector2
# -(x)
sparse_vector - sparse_vector2
# +@
sparse_vector.+@
# -@
sparse_vector.-@
# normalize
sparse_vector.normalize
# conjugate
sparse_vector.conjugate

############
# Equality #
############
# ==(x)
sparse_vector == sparse_vector2
# eql?(x)
sparse_vector.eql?(sparse_vector2)
# hash

###############
# Conversions #
###############
# covector
# coerce
# to_a
# to_s