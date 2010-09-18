module OPDS
	# Represents a navigation feed 
	# @see http://opds-spec.org/specs/opds-catalog-1-0-20100830/#Navigation_Feeds
	class NavigationFeed  < Feed
		# Collection of all Navigation feeds found in this feed
		# @return [OPDS::Support::LinkSet] found links
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
