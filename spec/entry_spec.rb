require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def sample(type)
	File.open( File.expand_path(File.dirname(__FILE__) + "/../samples/#{type}.txt"))
end

describe OPDS::Entry do


	subject do 
		 OPDS::Entry.from_nokogiri(Nokogiri::XML(sample(:entry)))
	end

	it "should have a title "do
			subject.title.size.should_not be(0)
	end

	it "should have an id"do
			subject.id.size.should_not be(0)
	end
	
	it "should have a summary "do
			subject.summary.size.should_not be(0)
	end
	
	it "should have a update date "do
			subject.updated.day.should be(13)
	end
	
	it "should have an author "do
			subject.author.size.should_not be(0)
	end
	
	it "should have  links "do
			subject.links.size.should_not be(0)
	end

	it "should have dc:meta" do

			subject.dcmetas.size.should_not be(0)
	end
	
	it "should have categories" do

			subject.categories.size.should_not be(0)
	end
	
	it "should not be partial" do
			subject.should_not be_partial()
	end
end
