require "open-uri"
module OPDS
	module Support
		class Browser
			include Logging
			def go_to(uri)
				url=URI.parse(uri)
				@last_response=nil
				Net::HTTP.start(url.host,url.port) {|http|
					path="/"
					path=url.path unless url.path==''
					req = Net::HTTP::Get.new(path)
#					req.basic_auth user,pass  unless user.nil?
					@last_response = http.request(req)
				}
			if status/10==30 && headers['location']
			   log("Following redirection (code: #{status}) to #{headers['location']}")
			   go_to(headers['location'].first)
			end
			end

			def ok?
				status==200
			end

			
			def status
			@last_response.code.to_i if @last_response
			end

			def headers
			@last_response.to_hash if @last_response
			end

			def body
			 @last_response.body if @last_response
			end

		end
	end
end
