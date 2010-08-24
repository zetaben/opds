require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def sample(type)
	File.open( File.expand_path(File.dirname(__FILE__) + "/../samples/#{type}.txt"))
end

describe OPDS::OPDSParser do

	[:entry, :acquisition, :navigation].each do |feed_type|
		it "should parse entry without error" do
			lambda { subject.parse(sample(feed_type)) }.should_not raise_error
		end

		it "should sniff entry" do
			subject.parse(sample(feed_type))
			subject.sniffed_type.should be(feed_type)
		end
		
		it "should return an instance of the correct class " do
			subject.parse(sample(feed_type)).class.should be({:entry => OPDS::Entry, :navigation => OPDS::NavigationFeed,:acquisition => OPDS::AcquisitionFeed}[feed_type])
		end
	end
	
	[ :acquisition, :navigation].each do |feed_type|
		it "should have a feed title" do 
			subject.parse(sample(feed_type)).title.size.should_not be(0)
		end

		it "should have a feed icon" do 
			subject.parse(sample(feed_type)).icon.size.should_not be(0)
		end
		
		it "should have feed links" do 
			subject.parse(sample(feed_type)).links.size.should_not be(0)
		end
		
		it "should have feed id" do 
			subject.parse(sample(feed_type)).id.size.should_not be(0)
		end
		it "should have a feed author" do 
			auth=subject.parse(sample(feed_type)).author
			auth[:name].should == ('Feedbooks')
			auth[:uri].should == ('http://www.feedbooks.com')
			auth[:email].should == ('support@feedbooks.com')
		end
		
		it "should have entries" do 
			subject.parse(sample(feed_type)).entries.size.should_not be(0)
		end
		

		
	end
		
		it do
			subject.parse(sample(:acquisition)).should be_paginated()
		end
		
		it do
			subject.parse(sample(:acquisition)).should be_first_page()
		end
		
		it "should have partial entries" do 
			subject.parse(sample(:acquisition)).entries.any?(&:partial?).should be()
		end
		
		it do
			feed=nil
			lambda { feed=subject.parse(sample(:acquisition)).next_page  }.should_not raise_error

			feed.class.should be(OPDS::AcquisitionFeed)
		end
end
