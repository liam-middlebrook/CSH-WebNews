module Ancestry
  # Allow for text IDs in the definition of a well-formatted ancestry column
  send :remove_const, :ANCESTRY_PATTERN
  const_set :ANCESTRY_PATTERN, /\A[^\/]+(\/[^\/]+)*\Z/

  module InstanceMethods
    private

    # Add `:text` to the array of column types that should not be cast
    def cast_primary_key(key)
      if [:string, :text, :uuid].include? primary_key_type
        key
      else
        key.to_i
      end
    end
  end
end
