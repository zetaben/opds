require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe OPDS::Support::LinkSet do 
	before(:each) do 
		subject.push('root','http://feedbooks.com','Racine')
		subject.push('subsection','http://feedbooks.com/publicdomain','Domaine pub')
		subject.push('subsection','http://feedbooks.com/original','Original')
		subject.push('subsection','http://feedbooks.com/feed','feeds')
		subject.push('http://opds-spec.org/shelf','http://feedbooks.com/shelf','shelf')
		subject.push('related','http://feedbooks.com/shelf',nil)
	end

	it do
		subject.size.should be(6)
	end
	
	it do
		subject.map(&:first).size.should be(6)
	end

	it "should find 3 subsection" do
		subject['subsection'].size.should be(3)
		subject.by(:rel)['subsection'].size.should be(3)
	end

	it "should give root url" do
		subject.link_url(:rel => 'root').should == ('http://feedbooks.com')
		subject.by(:rel)['root'].first[1].should == ('http://feedbooks.com')
	end

	it "get all text values" do
		subject.texts.size.should be(6)
	end
end
