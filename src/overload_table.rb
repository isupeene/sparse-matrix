# Table to allow delegation to methods based on argument type
class OverloadTable
	# Create table of overload functions and types to call based on type
	def initialize(overloads)
		@overloads = overloads
	end

	# Select method to call based on type of value
	def select(value)
		@overloads.find{ |type, _| type === value }[1]
	end

	# Check if there is a method to call for current type of value
	def include?(value)
		@overloads.any?{ |k, _| k === value }
	end
end
