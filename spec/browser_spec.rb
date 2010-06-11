require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe OPDS::Support::Browser do
  it "should be able to access google.com" do
  lambda {  subject.go_to("http://www.google.com") }.should_not raise_error
  subject.should be_ok

  end

  it "should not find an empty body on google.com" do 
	   subject.go_to("http://www.google.com")
	   subject.body.should_not ==""
  end


  it "should not be able to access http://foo.bar" do 
  lambda {  subject.go_to("http://foo.bar") }.should raise_error
  subject.should_not be_ok
  end

end
