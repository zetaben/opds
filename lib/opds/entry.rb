module OPDS
	class Entry
		include Logging
		attr_reader :raw_doc
		attr_reader :title
		attr_reader :id
		attr_reader :updated
		attr_reader :published
		attr_reader :summary
		attr_reader :authors
		attr_reader :links
		attr_reader :dcmetas
		attr_reader :categories
		attr_reader :content
		attr_reader :rights
		attr_reader :subtitle

		def initialize(browser=nil)
			@browser=browser
			@browser||=OPDS::Support::Browser.new
		end


		def self.from_nokogiri(content,namespaces=nil, browser=nil)
			z=self.new browser
			z.instance_variable_set('@raw_doc',content)
			z.instance_variable_set('@namespaces',namespaces)
			z.serialize!
			z
		end


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


		def author
			authors.first
		end

		def partial?
			links.by(:rel)['alternate'].any? do |l|
				l[3]=='application/atom+xml'||l[3]=='application/atom+xml;type=entry'
			end
		end

		def complete_url
			links.by(:rel)['alternate'].find do |l|
				l[3]=='application/atom+xml;type=entry'||l[3]=='application/atom+xml'
			end unless !partial?
		end

		def acquisition_links
			rel_start='http://opds-spec.org/acquisition'
			[*links.by(:rel).reject do |k,_|
				k[0,rel_start.size]!=rel_start unless k.nil?
			end.values]
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
