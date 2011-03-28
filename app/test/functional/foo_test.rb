require 'test_helper'

class FooTest < ActionMailer::TestCase
  test "bar" do
    mail = Foo.bar
    assert_equal "Bar", mail.subject
    assert_equal ["juanmaiz@gmail.com"], mail.to
    assert_equal ["maiz@softa.com.br"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
