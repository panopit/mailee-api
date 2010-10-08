require 'test_helper'

class FooTest < ActionMailer::TestCase
  test "bar" do
    mail = Foo.bar
    assert_equal "Bar", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "baz" do
    mail = Foo.baz
    assert_equal "Baz", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
