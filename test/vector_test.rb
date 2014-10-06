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
require_relative '../src/builders/sparse_vector_builder'
require_relative '../src/contracts/vector_contract'
require_relative '../src/contracts/matrix_contract'

module VectorTestBase
  def setup
    @v1 = vector_factory[1,2,3]
    @v2 = vector_factory[1,2,3]
    @v3 = @v1.clone
    @v4 = vector_factory[1.0, 2.0, 3.0]
    @w1 = vector_factory[2,3,4]
    @c1 = vector_factory[
      Complex.rect(1, -1),
      Complex.rect(2, -2),
      Complex.rect(3, -3)
    ]
    @c2 = vector_factory[
      Complex.rect(1, 1),
      Complex.rect(2, 2),
      Complex.rect(3, 3)
    ]
  end

  def test_identity
    assert_same @v1, @v1
    assert_not_same @v1, @v2
    assert_not_same @v1, @v3
    assert_not_same @v1, @v4
    assert_not_same @v1, @w1
  end

  def test_equality
    assert_equal @v1, @v1
    assert_equal @v1, @v2
    assert_equal @v1, @v3
    assert_equal @v1, @v4
    assert_not_equal @v1, @w1
  end

  def test_hash_equality
    assert @v1.eql?(@v1)
    assert @v1.eql?(@v2)
    assert @v1.eql?(@v3)
    assert !@v1.eql?(@v4)
    assert !@v1.eql?(@w1)

    hash = { @v1 => :value }
    assert hash.key?(@v1)
    assert hash.key?(@v2)
    assert hash.key?(@v3)
    assert !hash.key?(@v4)
    assert !hash.key?(@w1)
  end

  def test_hash
    assert_equal @v1.hash, @v1.hash
    assert_equal @v1.hash, @v2.hash
    assert_equal @v1.hash, @v3.hash
  end

  def test_aref
    assert_equal(1, @v1[0])
    assert_equal(2, @v1[1])
    assert_equal(3, @v1[2])
    assert_equal(3, @v1[-1])
    assert_equal(nil, @v1[3])
  end

  def test_size
    assert_equal(3, @v1.size)
  end

  def test_each2
    a = []
    @v1.each2(@v4) {|x, y| a << [x, y] }
    assert_equal([[1,1.0],[2,2.0],[3,3.0]], a)
  end

  def test_collect
    a = @v1.collect {|x| x + 1 }
    assert_equal(vector_factory[2,3,4], a)
  end

  def test_collect2
    a = @v1.collect2(@v4) {|x, y| x + y }
    assert_equal([2.0,4.0,6.0], a)
  end

  def test_map2
    a = @v1.map2(@v4) {|x, y| x + y }
    assert_equal(vector_factory[2.0,4.0,6.0], a)
  end

  def test_mul
    assert_equal(vector_factory[2,4,6], @v1 * 2)
    assert_equal(Matrix[[1, 4, 9], [2, 8, 18], [3, 12, 27]], @v1 * Matrix[[1,4,9]])
    assert_equal(20, @v1 * @w1)
    o = Object.new
    def o.coerce(x)
      [1, 1]
    end
    assert_equal(1, vector_factory[1, 2, 3] * o)
  end

  def test_add
    assert_equal(vector_factory[2,4,6], @v1 + @v1)
    assert_equal(Matrix[[2],[6],[12]], @v1 + Matrix[[1],[4],[9]])
    o = Object.new
    def o.coerce(x)
      [1, 1]
    end
    assert_equal(2, vector_factory[1, 2, 3] + o)
  end

  def test_sub
    assert_equal(vector_factory[0,0,0], @v1 - @v1)
    assert_equal(Matrix[[0],[-2],[-6]], @v1 - Matrix[[1],[4],[9]])
    o = Object.new
    def o.coerce(x)
      [1, 1]
    end
    assert_equal(0, vector_factory[1, 2, 3] - o)
  end

  def test_unary_plus
    assert_equal(@v1, +@v1)
  end

  def test_unary_minus
    assert_equal(@v1, -(-@v1))
  end

  def test_inner_product
    assert_equal(1+4+9, @v1.inner_product(@v1))
  end

  def test_r
    assert_equal(5, vector_factory[3, 4].r)
  end

  def test_covector
    assert_equal(Matrix[[1,2,3]], @v1.covector)
  end

  def test_to_s
    assert_equal("#{type_name}[1, 2, 3]", @v1.to_s)
  end

  def test_inspect
    assert_equal("#{type_name}[1, 2, 3]", @v1.inspect)
  end

  def test_magnitude
    assert_in_epsilon(3.7416573867739413, @v1.norm)
    assert_in_epsilon(3.7416573867739413, @v4.norm)
  end

  def test_rational_magnitude
    v = vector_factory[Rational(1,2), 0]
    assert_equal(0.5, v.norm)
  end

  def test_conjugate
    assert_equal(@c1, @c2.conjugate)
  end
end

class VectorTest < Test::Unit::TestCase
	include VectorTestBase

	def vector_factory
		Vector
	end

	def type_name
		"Vector"
	end
end

class SparseVectorTest < Test::Unit::TestCase
	include VectorTestBase

	def vector_factory
		SparseVectorBuilder
	end

	def type_name
		"SparseVector"
	end
end

