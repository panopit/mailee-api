require File.expand_path(File.dirname(__FILE__) + '/ar_spec_helper')

describe "Mailee" do

  before(:each) do
    @moment = Time.now.strftime('%Y%m%d%H%M%S')
  end

  it "should respond to sync_with_mailee" do
    ActiveRecord::Base.should respond_to(:sync_with_mailee)
  end

  it "should create if news is checked" do
    foo = Foo.create :name => "rest_test_foo_#{@moment}", :email => "rest_test_foo_#{@moment}@test.com", :news => true
    found = Mailee::Contact.find_by_email("rest_test_foo_#{@moment}@test.com")
    found.internal_id.to_i.should be foo.id
    # ==
    bar = Bar.create :other_name => "rest_test_bar_#{@moment}", :other_email => "rest_test_bar_#{@moment}@test.com", :other_news => true
    found = Mailee::Contact.find_by_email("rest_test_bar_#{@moment}@test.com")
    found.internal_id.to_i.should be bar.id
  end

  it "should not create if news is not checked" do
    foo = Foo.create :name => "rest_test_foo_#{@moment}", :email => "rest_test_foo_#{@moment}@test.com", :news => false
    found = Mailee::Contact.find_by_email("rest_test_foo_#{@moment}@test.com")
    found.should be nil
    # ==
    bar = Bar.create :other_name => "rest_test_bar_#{@moment}", :other_email => "rest_test_bar_#{@moment}@test.com", :other_news => false
    found = Mailee::Contact.find_by_email("rest_test_bar_#{@moment}@test.com")
    found.should be nil
  end

  it "should create if news is updated" do
    foo = Foo.create :name => "rest_test_foo_#{@moment}", :email => "rest_test_foo_#{@moment}@test.com", :news => false
    foo.update_attribute :news, true
    found = Mailee::Contact.find_by_email("rest_test_foo_#{@moment}@test.com")
    found.internal_id.to_i.should be foo.id
    # ==
    bar = Bar.create :other_name => "rest_test_bar_#{@moment}", :other_email => "rest_test_bar_#{@moment}@test.com", :other_news => false
    bar.update_attribute :other_news, true
    found = Mailee::Contact.find_by_email("rest_test_bar_#{@moment}@test.com")
    found.internal_id.to_i.should be bar.id
  end
  
  it "should subscribe to a list if :list is set" do
    foo = FooList.create :name => "rest_test_foo_#{@moment}", :email => "rest_test_foo_#{@moment}@test.com", :news => true
    # TODO I really cannot know if the email was subscribed successfully :S
  end

end