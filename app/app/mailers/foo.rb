class Foo < ActionMailer::Base

  send_with_mailee # easy peasy

  default :from => "Maiz <maiz@softa.com.br>"

  def bar(date=Time.now)
    @greeting = "Hi"
    mail :date => date, :to => ["juanmaiz@gmail.com"], :subject => "Bar"
  end

end