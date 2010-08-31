require 'open-uri'
module OPDS
	module Support
		class Link < Array
			include Logging
			attr_accessor :browser

			def initialize(array,browser=OPDS::Support::Browser.new) 
				@browser=browser
					unless browser.current_location.nil?
						array[1]=URI.join(browser.current_location,array[1]).to_s
					end
				super array
			end

			def navigate
			Feed.parse_url(self[1],browser)
			end

			def inspect
				"[#{self.map{|e| (e.is_a?(String) && e.size > 100 ? "#{e[0..98]}...".inspect: e.inspect ) }.join(', ')}]"
			end

			def url
				self[1]
			end
			
			def rel
				self[0]
			end
			
			def title
				self[2]
			end
			
			def type
				self[3]
			end
			
			def price
				self[4]
			end
			
			def currency
				self[5]
			end

		end
	

		class LinkSet 
			include Enumerable
			def initialize(browser=OPDS::Support::Browser.new)
				@browser=browser
				@rel_store=Hash.new
				@txt_store=Hash.new
				@lnk_store=Hash.new
				@typ_store=Hash.new
				@store=[]
			end

			def []=(k,v)
				link=Link.new([k]+v,@browser)
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

			def [](k)
				remap(@rel_store[k])
			end

			def each(&block)
				@store.each(&block)
			end

			def push(rel,link,text=nil,type=nil, price=nil, currency=nil)
				tab=[link,text,type]
				tab+=[price.to_f,currency] unless price.nil?
				self[rel]=tab
			end

			def link_url(k)
				ty,v=k.first
				t=remap(collection(ty)[v])
				t.first[1] unless t.nil?
			end
			
			def link_rel(k)
				ty,v=k.first
				t=remap(collection(ty)[v])
				t.first[0] unless t.nil?
			end

			def link_text(k)
				ty,v=k.first
				t=remap(collection(ty)[v])
				t.first[2] unless t.nil?
			end
			
			def link_type(k)
				ty,v=k.first
				t=remap(collection(ty)[v])
				t.first[3] unless t.nil?
			end

			def size
				@store.size
			end

			def by(type)
				Hash[collection(type).map{|k,v| [k,remap(v)]}]
			end

			def links
				@lnk_store.keys
			end
			
			def rels
				@rel_store.keys
			end
			
			def texts
				@txt_store.keys
			end
		
			def inspect
				@store.inspect
			end

			def first 
				@store.first
			end
			
			def last
				@store.last
			end

			protected 
			def collection(type)
				case type.to_s
				when 'link' then @lnk_store
				when 'rel' then @rel_store
				when 'txt' then @txt_store
				when 'type' then @typ_store
				end
			end

			def remap(tab)
				return nil if tab.nil? || tab.size==0
				tab.map{|i| @store[i]}
			end

		end
	end
end
