module Enumerable
	# Iterator to assist in taking power of a matrix
	def unfold(seed)
		drop(1).reduce([seed]) { |result|
			result << (yield result[-1])
		}
	end
end
