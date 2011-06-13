require 'open-uri'
module OPDS
	module Support
		# A link is actually an array composed as :
		#   [rel, url , title, mimetype, opds:price, opds:currency]
		class Link < Array
			include Logging
			# @return [OPDS::Support::Browser] Browser to use with this link
			attr_accessor :browser

			def initialize(array,browser=OPDS::Support::Browser.new) 
				@browser=browser
					unless browser.current_location.nil?
						array[1]=URI.join(browser.current_location,array[1]).to_s
					end
				super array
			end

			# Will go parsing the resource at this url.
			# Proxy to Feed.parse_url
			# @see Feed.parse_url
			# @return (see Feed.parse_url)
			def navigate
			Feed.parse_url(self[1],browser)
			end

			def inspect
				"[#{self.map{|e| (e.is_a?(String) && e.size > 100 ? "#{e[0..98]}...".inspect: e.inspect ) }.join(', ')}]"
			end

			#@return [String] link url
			def url 
				self[1]
			end
			
			#@return [String] link rel value
			def rel
				self[0]
			end
			
			#@return [String] link title
			def title
				self[2]
			end
			
			#@return [String] link mimetype
			def type
				self[3]
			end
			
			#@return [String] link opds price
			def price
				self[4]
			end
			
			#@return [String] link opds curreny
			def currency
				self[5]
			end

		end

		class Facet < Link
			def initialize(array,browser=OPDS::Support::Browser.new) 
				super(array,browser)				
			end

			def facet_group
				self[6]
			end
			
			def active_facet
				!self[7].nil?
			end

			alias :active_facet?  :active_facet
			
			def count
				self[8].to_i
			end

		end
	
		# Set of links.
		#
		# It provides ways to query and filter the set
		# @todo use a true Set to provide storage
		class LinkSet 
			include Enumerable
			# @param browser (see Feed.parse_url) 
			def initialize(browser=OPDS::Support::Browser.new)
				@browser=browser
				@rel_store=Hash.new
				@txt_store=Hash.new
				@lnk_store=Hash.new
				@typ_store=Hash.new
				@store=[]
			end

			# Add a link to the set 
			# @param k [String] rel value where to add the link
			# @param v [Array] remainder of link structure
			def []=(k,v)
				link=nil
				if v.size > 6 
				link=Facet.new([k]+v,@browser)
				else
				link=Link.new([k]+v,@browser)
				end
				@store.push link
				i=@store.size-1
				@rel_store[k]=[] unless @rel_store[k]
				@rel_store[k].push i
				@txt_store[v[1]]=[] unless @txt_store[v[1]]
				@txt_store[v[1]].push i
				@lnk_store[v.first]=[] unless @lnk_store[v.first]
				@lnk_store[v.first].push i
				@typ_store[v.last]=[] unless @typ_store[v.last]
				@typ_store[v.last].push i
				
			end

			# Query the set by rel value
			def [](k)
				remap(@rel_store[k])
			end
			
			#iterate through the set
			def each(&block)
				@store.each(&block)
			end

			# Push a link to the set 
			# @param rel (see Link#rel)
			# @param link (see Link#url)
			# @param text (see Link#title)
			# @param price (see Link#price)
			# @param currency (see Link#currency)
			def push(rel,link,text=nil,type=nil, price=nil, currency=nil)
				tab=[link,text,type]
				tab+=[price.to_f,currency] unless price.nil?
				self[rel]=tab
			end

			def push_facet(link,text=nil,type=nil,facet_group=nil,active_facet=nil,count=nil)
				self['http://opds-spec.org/facet']=[link,text,type,nil,nil,facet_group,active_facet,count]
			end

			# Push an existing link to the set 
			# @param [Link] kink to add 
			def push_link(link)
				@store.push link if link.is_a?Link
			end

			# Find first link url corresponding to the query
			# @example Query : 
			#    {:rel => "related" }
			def link_url(k)
				ty,v=k.first
				t=remap(collection(ty)[v])
				t.first[1] unless t.nil?
			end
			
			# Find first link rel corresponding to the query
			# @example Query : 
			#    {:rel => "related" }
			def link_rel(k)
				ty,v=k.first
				t=remap(collection(ty)[v])
				t.first[0] unless t.nil?
			end

			# Find first link text corresponding to the query
			# @example Query : 
			#    {:rel => "related" }
			def link_text(k)
				ty,v=k.first
				t=remap(collection(ty)[v])
				t.first[2] unless t.nil?
			end
			
			# Find first link type corresponding to the query
			# @example Query : 
			#    {:rel => "related" }
			def link_type(k)
				ty,v=k.first
				t=remap(collection(ty)[v])
				t.first[3] unless t.nil?
			end

			# Size of the set 
			# @return [Integer]
			def size
				@store.size
			end

			# Collection indexed by given type
			# @param [Symbol] in (:link,:rel,:txt,:type)
			def by(type)
				Hash[collection(type).map{|k,v| [k,remap(v)]}]
			end

			#@return [Array] all links
			def links
				@lnk_store.keys
			end
			
			#@return [Array] all rels
			def rels
				@rel_store.keys
			end
		
			#@return [Array] all titles
			def texts
				@txt_store.keys
			end
		
			def inspect
				@store.inspect
			end

			#@return [Link] First link in store
			def first 
				@store.first
			end
			
			#@return [Link] Last link in store
			def last
				@store.last
			end

			def to_yaml
				@store.to_yaml
			end

			protected 
			#Collection by type.
			# Will only give the keymap 
			# @param type (see LinkSet#by)
			# @see LinkSet#by
			def collection(type)
				case type.to_s
				when 'link' then @lnk_store
				when 'rel' then @rel_store
				when 'txt' then @txt_store
				when 'type' then @typ_store
				end
			end
			# recover links for an index table
			# @return [Array] Corresponding links
			# @param [Array] Indexes
			def remap(tab)
				return nil if tab.nil? || tab.size==0
				tab.map{|i| @store[i]}
			end

		end
	end
end
