# Ruby doesn't handle cyclic dependencies well.
# We need to forward-declare our contract types,
# since they are co-dependent on initial interpretation.
module MatrixContract
end

module VectorContract
end
