require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def sample(type)
	File.open( File.expand_path(File.dirname(__FILE__) + "/../samples/#{type}.txt"))
end

describe OPDS::OPDSParser do

	feed_type=:acquisition_opds1_1

	it "should parse OPDS 1.1 entry without error" do
		lambda { subject.parse(sample(feed_type)) }.should_not raise_error
	end

	it "should sniff entry" do
		subject.parse(sample(feed_type))
		subject.sniffed_type.should be(:acquisition)
	end

	it "should return an instance of the correct class " do
		subject.parse(sample(feed_type)).class.should be(OPDS::AcquisitionFeed)
	end

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

	it do
		subject.parse(sample(feed_type)).should be_paginated()
	end

	it do
		subject.parse(sample(feed_type)).should be_first_page()
	end

	it "should have partial entries" do 
		subject.parse(sample(feed_type)).entries.any?(&:partial?).should be()
	end
	
	it do
		subject.parse(sample(feed_type)).should have_at_least(1).facets
	end

	it "should have 5 sorting facets" do 
		subject.parse(sample(feed_type)).facets['Sort'].size.should ==5
	end
	
	it  do 
		subject.parse(sample(feed_type)).should have_at_least(1).active_facets
	end
	
	it "should have indirect acquisition types" do
		subject.parse(sample(feed_type)).entries.last.acquisition_links.last.type.size.should == 3
	end
		

end
