module OPDS
	class NavigationFeed  < Feed
		def navigation_links
			nav_links=Support::LinkSet.new @browser
			self.links.each do |l|
				nav_links.push_link l if l.type=='application/atom+xml'
			end

			self.entries.each do |entry|
				entry.links.each do |l|
					nav_links.push_link l if l.type=='application/atom+xml'
				end
			end
			nav_links
		end
	end
end
