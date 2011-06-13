module OPDS
	# Feed class is used as an ancestor to NavigationFeed and AcquisitionFeed it handles
	# all the parsing
	# @abstract Not really abstract as it's full fledged, but it should not be used directly
	class Feed
		include Logging
		# "Raw" Nokogiri document used while parsing.
		# It might useful to access atom foreign markup
		# @return [Nokogiri::XML::Document] Parsed document
		attr_reader :raw_doc
		# Entry list
		# @see Entry
		# @return [Array<Entry>] list of parsed entries
		attr_reader :entries


		def initialize(browser=nil)
			@browser=browser
			@browser||=OPDS::Support::Browser.new
		end
=begin
		# access root catalog
		def root
			return @root unless root?
			self
		end

		# root catalog predicate
		def root?
		end
=end


		# Parse the given url.
		#
		# If the resource at the give url is not an OPDS Catalog, this method will 
		# try to find a linked catalog.
		# If many are available it will take the first one with a priority given to 
		# nil rel or rel="related" catalogs.
		#
		# @param url [String] url to parse
		# @param browser (see Feed.parse_raw)
		# @param parser_opts parser options (unused at the moment)
		# @see OPDS::Support::Browser
		# @return [AcquisitionFeed,NavigationFeed, Entry, nil] an instance of a parsed feed, entry or nil
		def self.parse_url(url,browser=OPDS::Support::Browser.new,parser_opts={})
			@browser=browser
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

		# Will parse a text stream as an OPDS Catalog, internaly used by #parse_url
		#
		# @param txt [String] text to parse
		# @param opts [Hash] options to pass to the parser
		# @param browser [OPDS::Support::Browser] an optional compatible browser to use
		# @return [AcquisitionFeed,NavigationFeed] an instance of a parsed feed or nil
		def self.parse_raw(txt,opts={},browser=nil)
			parser=OPDSParser.new(opts)
			pfeed=parser.parse(txt,browser)
			type=parser.sniffed_type
			return pfeed unless type.nil?
			nil
		end

		
		# Create a feed from a nokogiri document
		# @param content [Nokogiri::XML::Document] nokogiri document
		# @param browser (see Feed.parse_url)
		# @return [Feed] new feed
		def self.from_nokogiri(content,browser=nil)
			z=self.new browser
			z.instance_variable_set('@raw_doc',content)
			z.serialize!
			z
		end

		# @private
		# read xml entries into the entry list struct
		# @todo really make private
		def serialize!
			@entries=raw_doc.xpath('/xmlns:feed/xmlns:entry',raw_doc.root.namespaces).map do |el|
				OPDS::Entry.from_nokogiri(el,raw_doc.root.namespaces,@browser)
			end
		end

		
		# @return [String] Feed title
		def title
			text(raw_doc.at('/xmlns:feed/xmlns:title',raw_doc.root.namespaces))
		end

		# @return [String] Feed icon definition
		def icon
			text(raw_doc.at('/xmlns:feed/xmlns:icon',raw_doc.root.namespaces))
		end

		# @return [OPDS::Support::LinkSet] Set with atom feed level links
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
							if rel=='http://opds-spec.org/facet'
								group=n.attribute_with_ns('facetGroup','http://opds-spec.org/2010/catalog')
								group=group.value unless group.nil?
								active=n.attribute_with_ns('activeFacet','http://opds-spec.org/2010/catalog')
								active=active.value unless active.nil?
								count=n.attribute_with_ns('count','http://purl.org/syndication/thread/1.0')
								count=count.value unless count.nil?

							@links.push_facet(link,text,type,group,active,count)
							else
							@links.push(rel,link,text,type)
							end
						end
					else
						@links.push(nil,link,text,type)
					end
				end

			end
			@links
		end

		# @return [String] Feed id
		def id
			text(raw_doc.at('/xmlns:feed/xmlns:id',raw_doc.root.namespaces))
		end

		# @return [Hash] Feed author (keys : name,uri,email)
		def author
			{
				:name => text(raw_doc.at('/xmlns:feed/xmlns:author/xmlns:name',raw_doc.root.namespaces)),
				:uri => text(raw_doc.at('/xmlns:feed/xmlns:author/xmlns:uri',raw_doc.root.namespaces)),
				:email => text(raw_doc.at('/xmlns:feed/xmlns:author/xmlns:email',raw_doc.root.namespaces))
			}
		end

		# @return [String] Next page url
		def next_page_url
			links.link_url(:rel => 'next')
		end

		# @return [String] Previous page url
		def prev_page_url
			links.link_url(:rel => 'prev')
		end

		# Is the feed paginated ?
		# @return Boolean
		def paginated?
			!next_page_url.nil?||!prev_page_url.nil?
		end

		# Is it the first page ?
		# @return Boolean
		def first_page?
			!prev_page_url if paginated?
		end

		# Is it the last page ?
		# @return Boolean
		def last_page?
			!next_page_url if paginated?
		end

		# Get next page feed
		# @return (see Feed.parse_url)
		def next_page
			Feed.parse_url(next_page_url,@browser)
		end

		# Get previous page feed
		# @return (see Feed.parse_url)
		def prev_page
			Feed.parse_url(prev_page_url,@browser)
		end

		def inspect
			"#<#{self.class}:0x#{self.object_id.abs.to_s(16)} entries(count):#{@entries.size} #{instance_variables.reject{|e| e=='@raw_doc'||e=='@entries' }.collect{|e| "#{e}=#{instance_variable_get(e).inspect}"}.join(' ')} >"
		end

		protected
		# Convert a nokogiri node to String value if not nil
		def text(t)
			return t.text unless t.nil?
			t
		end

	end
end
