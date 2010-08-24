module OPDS
	class Feed
		include Logging
		attr_reader :raw_doc
		attr_reader :entries


		def initialize(browser=nil)
			@browser=browser
			@browser||=OPDS::Support::Browser.new
		end

		# access root catalog
		def root
			return @root unless root?
			self
		end

		# root catalog predicate
		def root?
		end

		def self.parse_url(url,browser=nil,parser_opts={})
			@browser=browser
			@browser||=OPDS::Support::Browser.new
			@browser.go_to(url)
			if @browser.ok?
				return self.parse_raw(@browser.body,parser_opts)
			else
				return false
			end
		end

		def self.parse_raw(txt,opts={})
			parser=OPDSParser.new(opts)
			pfeed=parser.parse(txt)
			type=parser.sniffed_type
			return pfeed
		end

		def self.from_nokogiri(content)
			z=self.new
			z.instance_variable_set('@raw_doc',content)
			z.serialize!
			z
		end

		#read xml entries into entry struct
		def serialize!
			@entries=raw_doc.xpath('/xmlns:feed/xmlns:entry',raw_doc.root.namespaces).map do |el|
				OPDS::Entry.from_nokogiri(el)
			end
		end

		def title
			raw_doc.at('/xmlns:feed/xmlns:title',raw_doc.root.namespaces).text
		end

		def icon
			raw_doc.at('/xmlns:feed/xmlns:icon',raw_doc.root.namespaces).text
		end

		def links
			if !@links || @links.size ==0
				@links=OPDS::Support::LinkSet.new
				raw_doc.xpath('/xmlns:feed/xmlns:link',raw_doc.root.namespaces).each do |n|
					text=nil
					text=n.attributes['title'].value unless n.attributes['title'].nil?
					link=n.attributes['href'].value
					unless n.attributes['rel'].nil?
						n.attributes['rel'].value.split.each do |rel|
							@links.push(rel,link,text)
						end
					else
						@links.push(nil,link,text)
					end
				end

			end
			@links
		end

		def id
			raw_doc.at('/xmlns:feed/xmlns:id',raw_doc.root.namespaces).text
		end
		
		def author
			{
			:name => raw_doc.at('/xmlns:feed/xmlns:author/xmlns:name',raw_doc.root.namespaces).text,
			:uri => raw_doc.at('/xmlns:feed/xmlns:author/xmlns:uri',raw_doc.root.namespaces).text,
			:email => raw_doc.at('/xmlns:feed/xmlns:author/xmlns:email',raw_doc.root.namespaces).text
			}
		end

			
		def next_page_url
			links.link_url(:rel => 'next')
		end
		
		def prev_page_url
			links.link_url(:rel => 'prev')
		end

		def paginated?
			!next_page_url.nil?||!prev_page_url.nil?
		end

		def first_page?
			!prev_page_url if paginated?
		end

		def last_page?
			!next_page_url if paginated?
		end

		def next_page
			Feed.parse_url(next_page_url,@browser)
		end
		
		def prev_page
			Feed.parse_url(prev_page_url,@browser)
		end

	end
end
