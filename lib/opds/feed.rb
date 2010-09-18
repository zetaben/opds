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
				parsed = self.parse_raw(@browser.body,parser_opts,browser) 
				if parsed.nil?
					disco=@browser.discover(@browser.current_location)
					if disco.size > 0
						d=disco[nil]
						d||=disco['related']
						d||=disco
						Logging.log("Discovered : #{d.first.url}")
						return d.first.navigate
					end
					return false
				else
					return  parsed
				end
			else
				return false
			end
		end

		def self.parse_raw(txt,opts={},browser=nil)
			parser=OPDSParser.new(opts)
			pfeed=parser.parse(txt,browser)
			type=parser.sniffed_type
			return pfeed unless type.nil?
			nil
		end

		def self.from_nokogiri(content,browser=nil)
			z=self.new browser
			z.instance_variable_set('@raw_doc',content)
			z.serialize!
			z
		end

		#read xml entries into entry struct
		def serialize!
			@entries=raw_doc.xpath('/xmlns:feed/xmlns:entry',raw_doc.root.namespaces).map do |el|
				OPDS::Entry.from_nokogiri(el,raw_doc.root.namespaces,@browser)
			end
		end

		def title
			text(raw_doc.at('/xmlns:feed/xmlns:title',raw_doc.root.namespaces))
		end

		def icon
			text(raw_doc.at('/xmlns:feed/xmlns:icon',raw_doc.root.namespaces))
		end

		def links
			if !@links || @links.size ==0
				@links=OPDS::Support::LinkSet.new @browser
				raw_doc.xpath('/xmlns:feed/xmlns:link',raw_doc.root.namespaces).each do |n|
					text=nil
					text=n.attributes['title'].value unless n.attributes['title'].nil?
					type=n.attributes['type'].value unless n.attributes['type'].nil?
					link=n.attributes['href'].value
					unless n.attributes['rel'].nil?
						n.attributes['rel'].value.split.each do |rel|
							@links.push(rel,link,text,type)
						end
					else
						@links.push(nil,link,text,type)
					end
				end

			end
			@links
		end

		def id
			text(raw_doc.at('/xmlns:feed/xmlns:id',raw_doc.root.namespaces))
		end

		def author
			{
				:name => text(raw_doc.at('/xmlns:feed/xmlns:author/xmlns:name',raw_doc.root.namespaces)),
				:uri => text(raw_doc.at('/xmlns:feed/xmlns:author/xmlns:uri',raw_doc.root.namespaces)),
				:email => text(raw_doc.at('/xmlns:feed/xmlns:author/xmlns:email',raw_doc.root.namespaces))
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

		def inspect
			"#<#{self.class}:0x#{self.object_id.abs.to_s(16)} entries(count):#{@entries.size} #{instance_variables.reject{|e| e=='@raw_doc'||e=='@entries' }.collect{|e| "#{e}=#{instance_variable_get(e).inspect}"}.join(' ')} >"
		end

		protected
		def text(t)
			return t.text unless t.nil?
			t
		end

	end
end
