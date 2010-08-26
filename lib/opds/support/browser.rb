require "open-uri"
module OPDS
	module Support
		class Browser
			include Logging
			def go_to(uri)
				log(uri)
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

			def current_location
				@current_location
			end

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
