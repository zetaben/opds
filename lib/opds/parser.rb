require "nokogiri"
module OPDS
	class OPDSParser
		include Logging
		attr_accessor :options
		attr_reader :sniffed_type
		def initialize(opts={})
			@sniffed_type=nil
			self.options=opts.merge({})
		end

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
