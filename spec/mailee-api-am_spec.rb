require File.expand_path(File.dirname(__FILE__) + '/am_spec_helper')
  
describe "Mailee" do

  it "should respond to send_with_mailee" do
    ActionMailer::Base.should respond_to(:send_with_mailee)
  end

  it "should use Mailee::Mailer as the delivery method" do
    FooMailer.delivery_method.should be(Mailee::Mailer)
  end

  it "should deliver" do
    result = FooMailer.bar.deliver
    result.should_not be(false)
    result.class.should be(Mail::Message)
    result.delivery_method.class.should be(Mailee::Mailer)
    result.mailee_message.class.should be(Mailee::Message)
    result.mailee_message.id.should_not be(nil)
    result.mailee_message.status.should_not be(4)
    result.mailee_message.title.should_not be('Foo')
    result.mailee_message.subject.should_not be('Foo')
    result.mailee_message.from_name.should_not be('Maiz')
    result.mailee_message.from_email.should_not be('maiz@softa.com.br')
  end

end