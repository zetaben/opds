require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def sample(type)
	File.open( File.expand_path(File.dirname(__FILE__) + "/../samples/#{type}.txt"))
end

describe OPDS::OPDSParser do

	[:entry, :acquisition, :navigation].each do |feed_type|
		it "should parse entry without error" do
			lambda { subject.parse(sample(feed_type)) }.should_not raise_error
		end

		it "should should sniff  entry" do
			subject.parse(sample(feed_type))
			subject.sniffed_type.should be(feed_type)
		end
	end
end
