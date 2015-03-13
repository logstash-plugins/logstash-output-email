# encoding: utf-8
require "spec_helper"
require "rumbster"
require "message_observers"
require "logstash/outputs/email"

describe "outputs/email" do

  port = 2525
  let (:rumbster) { Rumbster.new(port) }
  let (:message_observer) { MailMessageObserver.new }

  before :each do
    rumbster.add_observer message_observer
    rumbster.start
  end

  after :each do
    rumbster.stop
  end

  describe "mail.to configuration" do
    it "can use a list of email as mail.to (LOGSTASH-827)" do
      subject = LogStash::Outputs::Email.new({
        "to" => "email1@host, email2@host",
        "options" => {"port"=> port}
      })
      subject.register
      subject.receive(LogStash::Event.new())
      insist {message_observer.messages.size} == 1
      insist {message_observer.messages[0].to} == ["email1@host", "email2@host"]
    end

    it "can use an event value as mail.to (LOGSTASH-827)" do
      subject = LogStash::Outputs::Email.new({
        "to" => "%{to_addr}",
          "options" => {"port"=> port}
      })
      subject.register
      subject.receive(LogStash::Event.new("to_addr" => ["email1@host", "email2@host"]))
      insist {message_observer.messages.size} == 1
      insist {message_observer.messages[0].to} == ["email1@host", "email2@host"]
    end
  end

  describe "mail content configuration" do
    it "allows multi-lined text body (LOGSTASH-841)" do
      subject = LogStash::Outputs::Email.new({
        "to" => "me@host",
        "subject" => "Hello World",
        "body" => "Line1\nLine2\nLine3",
        "options" => {"port"=> port}
      })
      subject.register
      subject.receive(LogStash::Event.new())
      insist {message_observer.messages.size} == 1
      insist {message_observer.messages[0].subject} == "Hello World"
      insist {message_observer.messages[0].body.raw_source} == "Line1\r\nLine2\r\nLine3"
    end
  end

  describe "authentication methods" do
    it "allows nil authenticationType (LOGSTASH-559)" do
      subject = LogStash::Outputs::Email.new({
        "to" => "me@host",
        "subject" => "Hello World",
        "body" => "Line1\nLine2\nLine3",
          "options" => {"port"=> port, "authenticationType" => "nil"}
      })
      subject.register
      subject.receive(LogStash::Event.new())
      insist {message_observer.messages.size} == 1
      insist {message_observer.messages[0].subject} == "Hello World"
      insist {message_observer.messages[0].body.raw_source} == "Line1\r\nLine2\r\nLine3"
    end
  end
end


