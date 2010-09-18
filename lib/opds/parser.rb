require "nokogiri"
module OPDS
	# Class in charge of discovering the type of the given text stream.
	# It will dispatch the pre-parsed atom content to the desired class
	# @see OPDS::AcquisitionFeed
	# @see OPDS::NavigationFeed
	# @see OPDS::Entry
	class OPDSParser
		include Logging
		# @return [Hash] parsing options
		attr_accessor :options
		# @return [Symbol] last parsed stream sniffed type (:acquisition,:navigation,:entry)
		attr_reader :sniffed_type
		def initialize(opts={})
			@sniffed_type=nil
			self.options=opts.merge({})
		end

		# Parse a text stream
		# @param content [String] text stream
		# @param browser (see Feed.parse_url)
		# @return [NavigationFeed, AcquisitionFeed, Entry] the parsed structure
		def parse(content,browser=nil)
			@ret=Nokogiri::XML(content)
			@sniffed_type=sniff(@ret)
			case @sniffed_type
			when :acquisition then return OPDS::AcquisitionFeed.from_nokogiri(@ret,browser)
			when :navigation then return OPDS::NavigationFeed.from_nokogiri(@ret,browser)
			when :entry then return OPDS::Entry.from_nokogiri(@ret,browser)
			end
		end

		protected 
		# Sniff a provided nokogiri document to detect it's type 
		# @param doc [Nokogiri::XML::Document] Document to sniff
		# @return [:acquisition, :navigation, :entry, nil] sniffed type
		def sniff(doc)
			return :entry if doc.root.name=='entry'
			entries = doc.xpath('/xmlns:feed/xmlns:entry',doc.root.namespaces)
			if entries.size > 0
				return :acquisition if entries.all? do |entry|
					entry.xpath('xmlns:link').any? do |link|  
						l=link.attributes['rel']
						unless l.nil?
							l.value.include?('http://opds-spec.org/acquisition') 
						else
							false
						end
					end
				end
				return :navigation
			end
			return nil
		rescue 
			nil
		end

	end
end
