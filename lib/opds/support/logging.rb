module OPDS
	#Handles logging from the library 
	module Logging
		#log text to stderr
		def log(txt)
			STDERR.puts("LOGGING : #{txt}")
		end

		#log text to stderr
		def self.log(txt)
			STDERR.puts("LOGGING : #{txt}")
		end
	end
end
