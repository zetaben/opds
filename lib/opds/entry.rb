module OPDS
	# Represents a catalog entry
	class Entry
		include Logging

		# "Raw" Nokogiri document used while parsing.
		# It might useful to access atom foreign markup
		# @return [Nokogiri::XML::Document] Parsed document
		attr_reader :raw_doc
		# @return [String] entry title
		attr_reader :title
		# @return [String] entry id
		attr_reader :id
		# @return [Date] entry updated date
		attr_reader :updated
		# @return [Date] entry published date
		attr_reader :published
		# @return [String] entry summary
		attr_reader :summary
		# @return [Array] entry parsed authors
		attr_reader :authors
		# @return [Array] entry parsed contributors
		attr_reader :contributors
		# @return [OPDS::Support::LinkSet] Set of links found in the entry
		attr_reader :links
		# @return [Hash] Hash of found dublin core metadata found in the entry
		# @see http://dublincore.org/documents/dcmi-terms/
		attr_reader :dcmetas
		# @return [Array] Categories found 
		attr_reader :categories
		# @return [String] content found 
		attr_reader :content
		# @return [String] entry right
		attr_reader :rights
		# @return [String] entry subtitle
		attr_reader :subtitle

		# @param browser (see Feed.parse_url)
		def initialize(browser=OPDS::Support::Browser.new)
			@browser=browser
		end

		# Create an entry from a nokogiri fragment 
		# @param content [Nokogiri::XML::Element] Nokogiri fragment (should be <entry>)
		# @param namespaces Associated document namespaces
		# @param browser (see Feed.parse_url)
		# @return [Entry]
		def self.from_nokogiri(content,namespaces=nil, browser=OPDS::Support::Browser.new)
			z=self.new browser
			z.instance_variable_set('@raw_doc',content)
			z.instance_variable_set('@namespaces',namespaces)
			z.serialize!
			z
		end

		# Read the provided document into the entry struct 
		# @private
		# @todo really make private
		def serialize!
			@namespaces=raw_doc.root.namespaces if @namespaces.nil?
			@authors=[]
			@raw_doc=raw_doc.at('./xmlns:entry',@namespaces) if raw_doc.at('./xmlns:entry',@namespaces)
			@title=text(raw_doc.at('./xmlns:title',@namespaces))
			@id=text(raw_doc.at('./xmlns:id',@namespaces))
			@summary=text(raw_doc.at('./xmlns:summary',@namespaces))
			d=text(raw_doc.at('./xmlns:updated',@namespaces))
			@updated=DateTime.parse(d) unless d.nil?
			d=text(raw_doc.at('./xmlns:published',@namespaces))
			@published=DateTime.parse(d) unless d.nil?

			@authors=raw_doc.xpath('./xmlns:author',@namespaces).collect do |auth|
				{
					:name => text(raw_doc.at('./xmlns:author/xmlns:name',@namespaces)),
					:uri => text(raw_doc.at('./xmlns:author/xmlns:uri',@namespaces)),
					:email => text(raw_doc.at('./xmlns:author/xmlns:email',@namespaces))
				}
			end

			@links=OPDS::Support::LinkSet.new @browser
			raw_doc.xpath('./xmlns:link',@namespaces).each do |n|
				text=nil
				text=n.attributes['title'].value unless n.attributes['title'].nil?
				link=n.attributes['href'].value
				type=n.attributes['type'].value unless n.attributes['type'].nil?
				price=nil
				currency=nil
				@namespaces['opds']||='http://opds-spec.org/2010/catalog'
				types=n.search('.//opds:indirectAcquisition',@namespaces).map{|b| b['type']}
				type=[type,types].flatten.compact unless types.nil? || types.empty?
				oprice=n.at('./opds:price',@namespaces)
				if oprice
					price=text(oprice)
					currency=oprice.attributes['currencycode'].value unless oprice.attributes['currencycode'].nil?
				end

				unless n.attributes['rel'].nil?
					n.attributes['rel'].value.split.each do |rel|
						@links.push(rel,link,text,type,price,currency)
					end
				else
					@links.push(nil,link,text,type,price,currency)
				end
			end
			@dcmetas=Hash.new
			prefs=@namespaces.reject{|_,v| !%W[http://purl.org/dc/terms/ http://purl.org/dc/elements/1.1/].include?v}
			prefs.keys.map{|p| p.split(':').last}.each do |pref|
				raw_doc.xpath('./'+pref+':*',@namespaces).each do |n|
					@dcmetas[n.name]=[] unless  @dcmetas[n.name]
					@dcmetas[n.name].push [n.text, n]
				end
			end

			@categories=raw_doc.xpath('./xmlns:category',@namespaces).collect do |n|
				[text(n.attributes['label']),text(n.attributes['term'])]
			end

			@content=raw_doc.at('./xmlns:content',@namespaces).to_s
			
			@contributors=raw_doc.xpath('./xmlns:contributor',@namespaces).collect do |auth|
				{
					:name => text(raw_doc.at('./xmlns:contributor/xmlns:name',@namespaces)),
					:uri => text(raw_doc.at('./xmlns:contributor/xmlns:uri',@namespaces)),
					:email => text(raw_doc.at('./xmlns:contributor/xmlns:email',@namespaces))
				}
			end

			@rights=text(raw_doc.at('./xmlns:rights',@namespaces))
			@subtitle=text(raw_doc.at('./xmlns:rights',@namespaces))

		end

		#First Author
		# @return [Hash]
		def author
			authors.first
		end
		
		# Is it a partial atom entry ?
		# @return [boolean]
		def partial?
			links.by(:rel)['alternate'].any? do |l|
				l[3]=='application/atom+xml'||l[3]=='application/atom+xml;type=entry'
			end
		end
		
		# @return [String] URL to the complete entry
		# @todo accessor to the complete entry
		def complete_url
			links.by(:rel)['alternate'].find do |l|
				l[3]=='application/atom+xml;type=entry'||l[3]=='application/atom+xml'
			end unless !partial?
		end
		
		# @return [Array] acquisition link subset
		def acquisition_links
			acq=[]
			rel_start='http://opds-spec.org/acquisition'
			links.by(:rel).each do |k,lnk|
				if !k.nil? && k[0,rel_start.size]==rel_start 
					lnk.each {|l| acq.push l}
				end
			end
			acq
		end
		
		def inspect
			"#<#{self.class}:0x#{self.object_id.abs.to_s(16)} #{instance_variables.reject{|e| e=='@raw_doc' }.collect{|e| "#{e}=#{instance_variable_get(e).inspect}"}.join(' ')} >"
		end

		protected 
		def text(t)
			return t.text unless t.nil?
			t
		end
	end
end
