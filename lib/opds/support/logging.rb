module OPDS
	module Logging
		def log(txt)
			STDERR.puts("LOGGING : #{txt}")
		end

		def self.log(txt)
			STDERR.puts("LOGGING : #{txt}")
		end
	end
end
