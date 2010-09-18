module OPDS
	# Convinience call to Feed.parse_url
	# @see Feed.parse_url
	# @return (see Feed.parse_url)
	def self.access(feed)
		Feed.parse_url(feed)
	end
end
