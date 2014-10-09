# Copyright (C) 1993-2013 Yukihiro Matsumoto. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# Modified by Isaac Supeene, Sept. 2014

require 'test/unit'
require_relative '../src/matrix'
require_relative '../src/vector'
require_relative '../src/contracts/matrix_contract'
require_relative '../src/builders/sparse_vector_builder'
require_relative '../src/builders/complete_vector_builder'
require_relative '../src/builders/sparse_matrix_builder'
require_relative '../src/builders/complete_matrix_builder'
require_relative '../src/builders/dumb_matrix_builder'

module MatrixTestBase

  def setup
    @m1 = matrix_factory[[1,2,3], [4,5,6]]
    @m2 = matrix_factory[[1,2,3], [4,5,6]]
    @m3 = @m1.clone
    @m4 = matrix_factory[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]
    @n1 = matrix_factory[[2,3,4], [5,6,7]]
    @c1 = matrix_factory[[Complex(1,2), Complex(0,1), 0], [1, 2, 3]]
  end

  def test_matrix
    assert_equal(1, @m1[0, 0])
    assert_equal(2, @m1[0, 1])
    assert_equal(3, @m1[0, 2])
    assert_equal(4, @m1[1, 0])
    assert_equal(5, @m1[1, 1])
    assert_equal(6, @m1[1, 2])
  end

  def test_identity
    assert_same @m1, @m1
    assert_not_same @m1, @m2
    assert_not_same @m1, @m3
    assert_not_same @m1, @m4
    assert_not_same @m1, @n1
  end

  def test_equality
    assert_equal @m1, @m1
    assert_equal @m1, @m2
    assert_equal @m1, @m3
    assert_equal @m1, @m4
    assert_not_equal @m1, @n1
  end

  def test_hash_equality
    assert @m1.eql?(@m1)
    assert @m1.eql?(@m2)
    assert @m1.eql?(@m3)
    assert !@m1.eql?(@m4)
    assert !@m1.eql?(@n1)

    hash = { @m1 => :value }
    assert hash.key?(@m1)
    assert hash.key?(@m2)
    assert hash.key?(@m3)
    assert !hash.key?(@m4)
    assert !hash.key?(@n1)
  end

  def test_hash
    assert_equal @m1.hash, @m1.hash
    assert_equal @m1.hash, @m2.hash
    assert_equal @m1.hash, @m3.hash
  end

  def test_rank
    [
      [[0]],
      [[0], [0]],
      [[0, 0], [0, 0]],
      [[0, 0], [0, 0], [0, 0]],
      [[0, 0, 0]],
      [[0, 0, 0], [0, 0, 0]],
      [[0, 0, 0], [0, 0, 0], [0, 0, 0]],
      [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]],
    ].each do |rows|
      assert_equal 0, matrix_factory[*rows].rank
    end

    [
      [[1], [0]],
      [[1, 0], [0, 0]],
      [[1, 0], [1, 0]],
      [[0, 0], [1, 0]],
      [[1, 0], [0, 0], [0, 0]],
      [[0, 0], [1, 0], [0, 0]],
      [[0, 0], [0, 0], [1, 0]],
      [[1, 0], [1, 0], [0, 0]],
      [[0, 0], [1, 0], [1, 0]],
      [[1, 0], [1, 0], [1, 0]],
      [[1, 0, 0]],
      [[1, 0, 0], [0, 0, 0]],
      [[0, 0, 0], [1, 0, 0]],
      [[1, 0, 0], [1, 0, 0]],
      [[1, 0, 0], [1, 0, 0]],
      [[1, 0, 0], [0, 0, 0], [0, 0, 0]],
      [[0, 0, 0], [1, 0, 0], [0, 0, 0]],
      [[0, 0, 0], [0, 0, 0], [1, 0, 0]],
      [[1, 0, 0], [1, 0, 0], [0, 0, 0]],
      [[0, 0, 0], [1, 0, 0], [1, 0, 0]],
      [[1, 0, 0], [0, 0, 0], [1, 0, 0]],
      [[1, 0, 0], [1, 0, 0], [1, 0, 0]],
      [[1, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]],
      [[1, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]],
      [[1, 0, 0], [1, 0, 0], [0, 0, 0], [0, 0, 0]],
      [[1, 0, 0], [0, 0, 0], [1, 0, 0], [0, 0, 0]],
      [[1, 0, 0], [0, 0, 0], [0, 0, 0], [1, 0, 0]],
      [[1, 0, 0], [1, 0, 0], [1, 0, 0], [0, 0, 0]],
      [[1, 0, 0], [0, 0, 0], [1, 0, 0], [1, 0, 0]],
      [[1, 0, 0], [1, 0, 0], [0, 0, 0], [1, 0, 0]],
      [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]],

      [[1]],
      [[1], [1]],
      [[1, 1]],
      [[1, 1], [1, 1]],
      [[1, 1], [1, 1], [1, 1]],
      [[1, 1, 1]],
      [[1, 1, 1], [1, 1, 1]],
      [[1, 1, 1], [1, 1, 1], [1, 1, 1]],
      [[1, 1, 1], [1, 1, 1], [1, 1, 1], [1, 1, 1]],
    ].each do |rows|
      matrix = matrix_factory[*rows]
      assert_equal 1, matrix.rank
      assert_equal 1, matrix.transpose.rank
    end

    [
      [[1, 0], [0, 1]],
      [[1, 0], [0, 1], [0, 0]],
      [[1, 0], [0, 1], [0, 1]],
      [[1, 0], [0, 1], [1, 1]],
      [[1, 0, 0], [0, 1, 0]],
      [[1, 0, 0], [0, 0, 1]],
      [[1, 0, 0], [0, 1, 0], [0, 0, 0]],
      [[1, 0, 0], [0, 0, 1], [0, 0, 0]],

      [[1, 0, 0], [0, 0, 0], [0, 1, 0]],
      [[1, 0, 0], [0, 0, 0], [0, 0, 1]],

      [[1, 0], [1, 1]],
      [[1, 2], [1, 1]],
      [[1, 2], [0, 1], [1, 1]],
    ].each do |rows|
      m = matrix_factory[*rows]
      assert_equal 2, m.rank
      assert_equal 2, m.transpose.rank
    end

    [
      [[1, 0, 0], [0, 1, 0], [0, 0, 1]],
      [[1, 1, 0], [0, 1, 1], [1, 0, 1]],
      [[1, 1, 0], [0, 1, 1], [1, 0, 1]],
      [[1, 1, 0], [0, 1, 1], [1, 0, 1], [0, 0, 0]],
      [[1, 1, 0], [0, 1, 1], [1, 0, 1], [1, 1, 1]],
      [[1, 1, 1], [1, 1, 2], [1, 3, 1], [4, 1, 1]],
    ].each do |rows|
      m = matrix_factory[*rows]
      assert_equal 3, m.rank
      assert_equal 3, m.transpose.rank
    end
  end

  def test_inverse
    assert_equal(matrix_factory[[-1, 1], [0, -1]], matrix_factory[[-1, -1], [0, -1]].inverse)
  end

  def test_determinant
    assert_equal(45, matrix_factory[[7,6], [3,9]].determinant)
    assert_equal(-18, matrix_factory[[2,0,1],[0,-2,2],[1,2,3]].determinant)
  end

  def test_new_matrix
    #assert_raise(MiniTest::Assertion) { matrix_factory[Object.new] }
    o = Object.new
    def o.to_ary; [1,2,3]; end
    assert_equal(@m1, matrix_factory[o, [4,5,6]])
  end

  def test_rows
    assert_equal(@m1, matrix_factory.rows([[1, 2, 3], [4, 5, 6]]))
  end

  def test_columns
    assert_equal(@m1, matrix_factory.columns([[1, 4], [2, 5], [3, 6]]))
  end

  def test_diagonal
    assert_equal(matrix_factory[[3,0,0],[0,2,0],[0,0,1]], matrix_factory.diagonal(3, 2, 1))
    assert_equal(matrix_factory[[4,0,0,0],[0,3,0,0],[0,0,2,0],[0,0,0,1]], matrix_factory.diagonal(4, 3, 2, 1))
  end

  def test_scalar
    assert_equal(matrix_factory[[2,0,0],[0,2,0],[0,0,2]], matrix_factory.scalar(3, 2))
    assert_equal(matrix_factory[[2,0,0,0],[0,2,0,0],[0,0,2,0],[0,0,0,2]], matrix_factory.scalar(4, 2))
  end

  def test_identity2
    assert_equal(matrix_factory[[1,0,0],[0,1,0],[0,0,1]], matrix_factory.identity(3))
    assert_equal(matrix_factory[[1,0,0],[0,1,0],[0,0,1]], matrix_factory.unit(3))
    assert_equal(matrix_factory[[1,0,0],[0,1,0],[0,0,1]], matrix_factory.I(3))
    assert_equal(matrix_factory[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]], matrix_factory.identity(4))
  end

  def test_zero
    assert_equal(matrix_factory[[0,0,0],[0,0,0],[0,0,0]], matrix_factory.zero(3))
    assert_equal(matrix_factory[[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], matrix_factory.zero(4))
    assert_equal(matrix_factory[[0]], matrix_factory.zero(1))
  end

  def test_row_vector
    assert_equal(matrix_factory[[1,2,3,4]], matrix_factory.row_vector([1,2,3,4]))
  end

  def test_column_vector
    assert_equal(matrix_factory[[1],[2],[3],[4]], matrix_factory.column_vector([1,2,3,4]))
  end

  def test_row
    assert_equal(Vector[1, 2, 3], @m1.row(0))
    assert_equal(Vector[4, 5, 6], @m1.row(1))
    a = []; @m1.row(0) {|x| a << x }
    assert_equal([1, 2, 3], a)
  end

  def test_column
    assert_equal(Vector[1, 4], @m1.column(0))
    assert_equal(Vector[2, 5], @m1.column(1))
    assert_equal(Vector[3, 6], @m1.column(2))
    a = []; @m1.column(0) {|x| a << x }
    assert_equal([1, 4], a)
  end

  def test_collect
    assert_equal(matrix_factory[[1, 4, 9], [16, 25, 36]], @m1.collect {|x| x ** 2 })
  end

  def test_minor
    assert_equal(matrix_factory[[1, 2], [4, 5]], @m1.minor(0..1, 0..1))
    assert_equal(matrix_factory[[2], [5]], @m1.minor(0..1, 1..1))
    assert_equal(matrix_factory[[4, 5]], @m1.minor(1..1, 0..1))
    assert_equal(matrix_factory[[1, 2], [4, 5]], @m1.minor(0, 2, 0, 2))
    assert_equal(matrix_factory[[4, 5]], @m1.minor(1, 1, 0, 2))
    assert_equal(matrix_factory[[2], [5]], @m1.minor(0, 2, 1, 1))
    #assert_raise(MiniTest::Assertion) { @m1.minor(0) }
  end

  def test_regular?
    assert(matrix_factory[[1, 0], [0, 1]].regular?)
    assert(matrix_factory[[1, 0, 0], [0, 1, 0], [0, 0, 1]].regular?)
    assert(!matrix_factory[[1, 0, 0], [0, 0, 1], [0, 0, 1]].regular?)
  end

  def test_singular?
    assert(!matrix_factory[[1, 0], [0, 1]].singular?)
    assert(!matrix_factory[[1, 0, 0], [0, 1, 0], [0, 0, 1]].singular?)
    assert(matrix_factory[[1, 0, 0], [0, 0, 1], [0, 0, 1]].singular?)
  end

  def test_square?
    assert(matrix_factory[[1, 0], [0, 1]].square?)
    assert(matrix_factory[[1, 0, 0], [0, 1, 0], [0, 0, 1]].square?)
    assert(matrix_factory[[1, 0, 0], [0, 0, 1], [0, 0, 1]].square?)
    assert(!matrix_factory[[1, 0, 0], [0, 1, 0]].square?)
  end

  def test_mul
    assert_equal(matrix_factory[[2,4],[6,8]], matrix_factory[[2,4],[6,8]] * matrix_factory.I(2))
    assert_equal(matrix_factory[[4,8],[12,16]], matrix_factory[[2,4],[6,8]] * 2)
    assert_equal(matrix_factory[[4,8],[12,16]], 2 * matrix_factory[[2,4],[6,8]])
    assert_equal(matrix_factory[[14,32],[32,77]], @m1 * @m1.transpose)
    assert_equal(matrix_factory[[17,22,27],[22,29,36],[27,36,45]], @m1.transpose * @m1)
    #assert_equal(Vector[14,32], @m1 * Vector[1,2,3])
    o = Object.new
    def o.coerce(m)
      [m, m.transpose]
    end
    assert_equal(matrix_factory[[14,32],[32,77]], @m1 * o)
  end

  def test_add
    assert_equal(matrix_factory[[6,0],[-4,12]], matrix_factory.scalar(2,5) + matrix_factory[[1,0],[-4,7]])
    assert_equal(matrix_factory[[3,5,7],[9,11,13]], @m1 + @n1)
    assert_equal(matrix_factory[[3,5,7],[9,11,13]], @n1 + @m1)
    assert_equal(matrix_factory[[2],[4],[6]], matrix_factory[[1],[2],[3]] + Vector[1,2,3])
    #assert_raise(MiniTest::Assertion) { @m1 + 1 }
    o = Object.new
    def o.coerce(m)
      [m, m]
    end
    assert_equal(matrix_factory[[2,4,6],[8,10,12]], @m1 + o)
  end

  def test_sub
    assert_equal(matrix_factory[[4,0],[4,-2]], matrix_factory.scalar(2,5) - matrix_factory[[1,0],[-4,7]])
    assert_equal(matrix_factory[[-1,-1,-1],[-1,-1,-1]], @m1 - @n1)
    assert_equal(matrix_factory[[1,1,1],[1,1,1]], @n1 - @m1)
    assert_equal(matrix_factory[[0],[0],[0]], matrix_factory[[1],[2],[3]] - Vector[1,2,3])
    #assert_raise(MiniTest::Assertion) { @m1 - 1 }
    o = Object.new
    def o.coerce(m)
      [m, m]
    end
    assert_equal(matrix_factory[[0,0,0],[0,0,0]], @m1 - o)
  end

  def test_unary_plus
    assert_equal(@m1, +@m1)
  end

  def test_unary_minus
    assert_equal(@m1, -(-@m1))
  end

  def test_div
    assert_equal(matrix_factory[[0,1,1],[2,2,3]], @m1 / 2)
    assert_equal(matrix_factory[[1,1],[1,1]], matrix_factory[[2,2],[2,2]] / matrix_factory.scalar(2,2))

    o = Object.new
    matrix_fact = matrix_factory # For some reason, matrix_factory is not visible in the closure.
    o.define_singleton_method(:coerce) { |m| [m, matrix_fact.scalar(2, 2)] }

    assert_equal(matrix_factory[[1,1],[1,1]], matrix_factory[[2,2],[2,2]] / o)
  end

  def test_exp
    assert_equal(matrix_factory[[67,96],[48,99]], matrix_factory[[7,6],[3,9]] ** 2)
    assert_equal(matrix_factory.I(5), matrix_factory.I(5) ** -1)
    #assert_raise { matrix_factory.I(5) ** Object.new }
  end

  def test_det
    assert_equal(45, matrix_factory[[7,6],[3,9]].det)
    assert_equal(0, matrix_factory[[0,0],[0,0]].det)
    assert_equal(-7, matrix_factory[[0,0,1],[0,7,6],[1,3,9]].det)
    assert_equal(42, matrix_factory[[7,0,1,0,12],[8,1,1,9,1],[4,0,0,-7,17],[-1,0,0,-4,8],[10,1,1,8,6]].det)
  end

  def test_rank2
    assert_equal(2, matrix_factory[[7,6],[3,9]].rank)
    assert_equal(0, matrix_factory[[0,0],[0,0]].rank)
    assert_equal(3, matrix_factory[[0,0,1],[0,7,6],[1,3,9]].rank)
    assert_equal(1, matrix_factory[[0,1],[0,1],[0,1]].rank)
    assert_equal(2, @m1.rank)
  end

  def test_trace
    assert_equal(1+5+9, matrix_factory[[1,2,3],[4,5,6],[7,8,9]].trace)
  end

  def test_transpose
    assert_equal(matrix_factory[[1,4],[2,5],[3,6]], @m1.transpose)
  end

  def test_conjugate
    assert_equal(matrix_factory[[Complex(1,-2), Complex(0,-1), 0], [1, 2, 3]], @c1.conjugate)
  end

  def test_eigensystem
    m = matrix_factory[[1, 2], [3, 4]]
    v, d, v_inv = m.eigensystem
    assert(d.diagonal?)
    assert_equal(v.inv, v_inv)
    assert_equal((v * d * v_inv).round(5), m)
  end

  def test_imaginary
    assert_equal(matrix_factory[[2, 1, 0], [0, 0, 0]], @c1.imaginary)
  end

  def test_lup
    m = matrix_factory[[1, 2], [3, 4]]
    l, u, p = m.lup
    assert(l.lower_triangular?)
    assert(u.upper_triangular?)
    assert(p.permutation?)
    assert_equal(l * u, p * m)
    assert_equal(m.lup.solve([2, 5]), Vector[1, Rational(1,2)])
  end

  def test_real
    assert_equal(matrix_factory[[1, 0, 0], [1, 2, 3]], @c1.real)
  end

  def test_rect
    assert_equal([matrix_factory[[1, 0, 0], [1, 2, 3]], matrix_factory[[2, 1, 0], [0, 0, 0]]], @c1.rect)
  end

  def test_row_vectors
    assert_equal([Vector[1,2,3], Vector[4,5,6]], @m1.row_vectors)
  end

  def test_column_vectors
    assert_equal([Vector[1,4], Vector[2,5], Vector[3,6]], @m1.column_vectors)
  end

#  def test_to_s
#    assert_equal("#{matrix_factory}[[1, 2, 3], [4, 5, 6]]", @m1.to_s)
#    assert_equal("#{matrix_factory}.empty(0, 0)", matrix_factory[].to_s)
#    assert_equal("#{matrix_factory}.empty(1, 0)", matrix_factory[[]].to_s)
#  end

#  def test_inspect
#    assert_equal("#{matrix_factory}[[1, 2, 3], [4, 5, 6]]", @m1.inspect)
#    assert_equal("#{matrix_factory}.empty(0, 0)", matrix_factory[].inspect)
#    assert_equal("#{matrix_factory}.empty(1, 0)", matrix_factory[[]].inspect)
#  end

  def test_scalar_add
    s1 = @m1.coerce(1).first
    assert_equal(matrix_factory[[1]], (s1 + 0) * matrix_factory[[1]])
    #assert_raise { s1 + Vector[0] }
    #assert_raise { s1 + matrix_factory[[0]] }
    o = Object.new
    def o.coerce(x)
      [1, 1]
    end
    assert_equal(2, s1 + o)
  end

  def test_scalar_sub
    s1 = @m1.coerce(1).first
    assert_equal(matrix_factory[[1]], (s1 - 0) * matrix_factory[[1]])
    #assert_raise { s1 - Vector[0] }
    #assert_raise { s1 - matrix_factory[[0]] }
    o = Object.new
    def o.coerce(x)
      [1, 1]
    end
    assert_equal(0, s1 - o)
  end

  def test_scalar_mul
    s1 = @m1.coerce(1).first
    assert_equal(matrix_factory[[1]], (s1 * 1) * matrix_factory[[1]])
    assert_equal(Vector[2], s1 * Vector[2])
    assert_equal(matrix_factory[[2]], s1 * matrix_factory[[2]])
    o = Object.new
    def o.coerce(x)
      [1, 1]
    end
    assert_equal(1, s1 * o)
  end

  def test_scalar_div
    s1 = @m1.coerce(1).first
    assert_equal(matrix_factory[[1]], (s1 / 1) * matrix_factory[[1]])
    #assert_raise { s1 / Vector[0] }
    assert_equal(matrix_factory[[Rational(1,2)]], s1 / matrix_factory[[2]])
    o = Object.new
    def o.coerce(x)
      [1, 1]
    end
    assert_equal(1, s1 / o)
  end

  def test_scalar_pow
    s1 = @m1.coerce(1).first
    assert_equal(matrix_factory[[1]], (s1 ** 1) * matrix_factory[[1]])
    #assert_raise { s1 ** Vector[0] }
    #assert_raise { s1 ** matrix_factory[[1]] }
    o = Object.new
    def o.coerce(x)
      [1, 1]
    end
    assert_equal(1, s1 ** o)
  end
end

class MatrixTest < Test::Unit::TestCase
	include MatrixTestBase

	def matrix_factory
		CompleteMatrixBuilder
	end
end

class SparseMatrixTest < Test::Unit::TestCase
	include MatrixTestBase

	def matrix_factory
		SparseMatrixBuilder
	end
end

class DumbMatrixTest < Test::Unit::TestCase
	include MatrixTestBase

	def matrix_factory
		DumbMatrixBuilder
	end
end
