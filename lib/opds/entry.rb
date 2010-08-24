module OPDS
	class Entry
		include Logging
		attr_reader :raw_doc
		attr_reader :title
		attr_reader :id
		attr_reader :updated_at
		attr_reader :summary
		attr_reader :authors
		attr_reader :links
		attr_reader :dcmetas
		def self.from_nokogiri(content,namespaces=nil)
			z=self.new
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
			@updated_at=DateTime.parse(d) unless d.nil?

			@authors=raw_doc.xpath('./xmlns:author',@namespaces).collect do |auth|
				{
					:name => text(raw_doc.at('./xmlns:author/xmlns:name',@namespaces)),
					:uri => text(raw_doc.at('./xmlns:author/xmlns:uri',@namespaces)),
					:email => text(raw_doc.at('./xmlns:author/xmlns:email',@namespaces))
				}
			end

			@links=OPDS::Support::LinkSet.new
			raw_doc.xpath('./xmlns:link',@namespaces).each do |n|
				text=nil
				text=n.attributes['title'].value unless n.attributes['title'].nil?
				link=n.attributes['href'].value
				type=n.attributes['type'].value unless n.attributes['type'].nil?
				unless n.attributes['rel'].nil?
					n.attributes['rel'].value.split.each do |rel|
						@links.push(rel,link,text,type)
					end
				else
					@links.push(nil,link,text,type)
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
			links.by(:rel)['alternate'].any? do |l|
				l[3]=='application/atom+xml'
			end unless !partial?
		end

		protected 
		def text(t)
			return t.text unless t.nil?
			t
		end
	end
end
