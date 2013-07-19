require "open-uri"
require 'net/http'

module OPDS
	# Supporting classes 
	module Support
		# Browser class, it will be used to access the Internet.
		# Currently based on open-uri only
		class Browser
			include Logging
			# Navigate to the provided uri
			# @param uri [String] uri to go to
			def go_to(uri)
				log("Accessing #{uri}")
				url=URI.parse(uri)
				@last_response=nil
				Net::HTTP.start(url.host,url.port) {|http|
					path="/"
					path=url.path unless url.path==''
					req = Net::HTTP::Get.new(path)
					#					req.basic_auth user,pass  unless user.nil?
					@last_response = http.request(req)
				}
				@current_location=url.to_s
				if status/10==30 && headers['location']
					log("Following redirection (code: #{status}) to #{headers['location']}")
					go_to(headers['location'].first)
				end
			end

			# Last page load was ok ?
			# @return [boolean]
			def ok?
				status==200
			end

			# @return [integer] Last page load return code
			def status
				@last_response.code.to_i if @last_response
			end

			# @return [Hash] Last page HTTP headers
			def headers
				@last_response.to_hash if @last_response
			end

			# @return [String] Last page body
			def body
				@last_response.body if @last_response
			end

			# @return [String] current uri
			def current_location
				@current_location
			end

			# Try to discover catalog links at the given url
			# @param [String] url to search
			# @return [OPDS::Support::LinkSet, false] discovered links
			def discover(url)
				go_to(url)
				if ok?
					doc=Nokogiri::HTML(body)
					tab=OPDS::Support::LinkSet.new(self)
					extract_links(tab,doc,'//*[@type="application/atom+xml;type=entry;profile=opds-catalog"]')		
					extract_links(tab,doc,'//*[@type="application/atom+xml;profile=opds-catalog"]')

					return false if tab.size == 0
					tab
				else
					return false
				end

			end

			private 
			# extracts linkset from doc + xpath expression
			def extract_links(tab,doc, expr)
				doc.xpath(expr).each do |n|
					text=nil
					text=n.attributes['title'].value unless n.attributes['title'].nil?
					if n.name=='a' && text.nil?
						text=n.text
					end

					link=n.attributes['href'].value
					type=n.attributes['type'].value unless n.attributes['type'].nil?
					unless n.attributes['rel'].nil?
						n.attributes['rel'].value.split.each do |rel|
							tab.push(rel,link,text,type)
						end
					else
						tab.push(nil,link,text,type)
					end
				end
				tab
			end

		end
	end
end
