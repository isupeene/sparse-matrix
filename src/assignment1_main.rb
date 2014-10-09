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
# row_size
# column_size
# row(i)
# column(j)
# collect
# map
# each
# each_with_index
# find_index
# minor(*param)

#####################
# Matrix Properties #
#####################
# diagonal?
# empty?
# hermitian?
# lower_triangular?
# normal?
# orthogonal?
# permutation?
# real?
# regular?
# singular?
# square?
# symmetric?
# unitary?
# upper_triangular?
# zero?

#####################
# Matrix Arithmetic #
#####################
# *(m)
# +(m)
# -(m)
# /(m)
# inverse
# inv
# **

####################
# Matrix Functions #
####################
# determinant
# det
# rank
# round
# trace
# tr
# transpose
# t

#########################
# Matrix Decompositions #
#########################
# eigen
# eigensystem
# lup
# lup_decomposition

######################
# Complex Arithmetic #
######################
# conj
# conjugate
# imag
# imaginary
# real
# rect
# rectangular

##############
# Conversion #
##############
# coerce(other)
# row_vectors
# column_vectors
# to_a

##########################
# String Representations #
##########################
# to_s
# inspect


# Vectors can also be built through the VectorBuilder class in a way similar to matrices.
sparse_vector = VectorBuilder.create(:sparse, row_size){ |builder| 
	row_size.times.select{|i| i % 3 == 0}.each{ |i| builder[i] = i}
}

# Complete Vectors are the Ruby Matrix class' Vectors so they respond to those functions
# The non-complete Vectors respond to the following functions:
#############
# Iterators #
#############
# NOTE: selector is either :all or :non_zero
# each(selector=:all)
# each_with_index(selector=:all)
# map(elector=:all)
# collect(selector=:all)
# each2(v)
# each2_with_index(v)
# map2(v)
# collect2(v)

##############
# Properties #
##############
# size
# length
# magnitude
# norm
# r

##############
# Arithmetic #
##############
# *(x)
# /(x)
# +(x)
# -(x)
# +@
# -@
# normalize
# conjugate

############
# Equality #
############
# ==(x)
# eql?(x)
# hash

###############
# Conversions #
###############
# covector
# coerce
# to_a
# to_s