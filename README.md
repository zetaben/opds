OPDS Parsing library
====================

This gem provides a parsing library for [OPDS Catalogs](http://opds-spec.org).

It also has the ability to discover catalogs in html feeds.

Installation
------------

	gem install opds


Usage
-----

Parsing a feed is simply done. 

	require "opds"
	OPDS::Feed.parse_url("http://catalog.com/catalog.atom")

This method will return an instance of the Feed or Entry classes. Each Atom element is accessible directly via a dedicated method (ex: `feed.title`). Entry also provides a method to directly access any embeded Dublin Core metadata (`dcmeta`). The `raw_doc` attribute gives access to the Nokogiri parsed source.

### Complete atom entries ###

Complete atom entries are available if detected as another instance of the Entry class. Just call `entry.complete` on the partial entry to access it.

### Links ###

Every links are automatically parsed in feeds and entries. They are made available in a collection called `links`. Relative links should be transformed in their absolute equivalent. On each link there is a `navigate` method which will proxy a call to OPDS::Feed.parse_url.


