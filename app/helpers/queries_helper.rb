module QueriesHelper
	# Function that checks if a string is a number
	def is_number? string
	  true if Float(string) rescue false
	end
end
