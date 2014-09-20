require 'test/unit'

module Contract
	def included(type)
		require_method_invariants(type)
		require_preconditions(type)
		require_postconditions(type)
	end

	def require_preconditions(type)
		override_matching_instance_methods(type, "_precondition") \
		do |instance, contract, method, *args|
			instance.invariant
			contract.bind(instance).call(*args)
			method.bind(instance).call(*args)
		end
	end

	def require_postconditions(type)
		override_matching_instance_methods(type, "_postcondition") \
		do |instance, contract, method, *args|
			result = method.bind(instance).call(*args)
			contract.bind(instance).call(*args, result)
			instance.invariant
			result
		end
	end

	def require_method_invariants(type)
		override_matching_instance_methods(type, "_invariant") \
		do |instance, contract, method, *args|
			result = nil
			contract.bind(instance).call(*args) {
				result = method.bind(instance).call(*args)
			}
			result
		end
	end

	def override_matching_instance_methods(type, primary_suffix)
		["", "?", "!", "="].each do |secondary_suffix|
			matching_instance_methods(
				type,
				primary_suffix,
				secondary_suffix
			) \
			do |contract, method|
				type.send(:define_method, method.name) \
				do |*args|
					yield self, contract, method, *args
				end
			end
		end
	end

	def matching_instance_methods(type, primary_suffix, secondary_suffix)
		contract_suffix = primary_suffix + secondary_suffix
		puts "checking #{contract_suffix}"
		type.instance_methods.select {
			|m| m.to_s.end_with?(contract_suffix)
		}.each \
		do |contract|
			puts "found #{contract}"
			method = type.instance_method(convert_method_name(
				contract.to_s[0...-contract_suffix.length] +
				secondary_suffix
			))
			puts "found #{method.name}"
			yield type.instance_method(contract), method
		end
	end

	def convert_method_name(name)
		case name
		when "op_add"
			"+"
		when "op_subtract"
			"-"
		when "op_multiply"
			"*"
		when "op_divide"
			"/"
		when "op_modulo"
			"%"
		when "op_power"
			"**"
		when "op_equal"
			"=="
		when "op_greater_than"
			">"
		when "op_less_than"
			"<"
		when "op_greater_than_or_equal"
			">="
		when "op_less_than_or_equal"
			"<="
		when "op_compare"
			"<=>"
		when "op_subsumption"
			"==="
		when "op_match"
			"=~"
		when "op_not_match"
			"!~"
		when "op_element_access"
			"[]"
		when "op_element_mutation"
			"[]="
		when "op_not"
			"!"
		when "op_complement"
			"~"
		when "op_unary_plus"
			"+@"
		when "op_unary_minus"
			"-@"
		when "op_and"
			"&"
		when "op_or"
			"|"
		when "op_exclusive_or"
			"^"
		when "op_shift_left"
			"<<"
		when "op_shift_right"
			">>"
		else
			name
		end
	end
end

module Invariants
	def const(*args)
		temp = clone
		yield
		assert_equal(temp, self)
	end
end

module SquarerContract
	include Test::Unit::Assertions
	include Invariants
	extend Contract

	def square_precondition(x)
		puts self
		puts "hello from precondition!"
	end

	def square_postcondition(x, result)
		assert_equal(x ** 2, result)
		puts "hello from postcondition!"
	end

	def square_root_precondition(x)
		assert(x >= 0)
	end

	def square_root_postcondition(x, result)
		assert_equal(Math::sqrt(x), result)
	end

	def square_precondition?(x, y)
	end

	def square_postcondition?(x, y, result)
		assert_equal(x ** 2 == y, result)
	end

	def op_add_precondition(x)
		puts "add precondition"
	end

	def op_add_postcondition(x, result)
		puts "add postcondition"
	end

	def square_invariant(x)
		puts "hello from square invariant before function"
		yield
		puts "hello from square invariant after function"
	end

	def invariant
		puts "hello from class invariant"
	end

	alias square_root_invariant const
end

class Squarer
	include Math

	def square(x)
		x ** 2
	end

	def square_root(x)
		sqrt(x)
	end

	def square?(x, y)
		square(x) == y
	end

	def +(r)
		self
	end

	def ==(other)
		return other.is_a?(Squarer)
	end

	include SquarerContract
end

