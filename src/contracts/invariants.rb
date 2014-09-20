require 'test/unit'

module Invariants
	include Test::Unit::Assertions

	def const(*args)
		temp = clone
		yield
		assert_equal(temp, self)
	end
end

