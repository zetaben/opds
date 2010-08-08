module OPDS
	def self.access(feed)
		Feed.parse_url(feed)
	end
end
