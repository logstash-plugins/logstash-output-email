# encoding: utf-8
require "spec_helper"
require "rumbster"
require "message_observers"

describe "outputs/email" do

  let (:port)             { rand(1024..65535) }
  let (:rumbster)         { Rumbster.new(port) }
  let (:message_observer) { MailMessageObserver.new }
  let(:plugin)            { LogStash::Plugin.lookup("output", "email") }


  before :each do
    rumbster.add_observer message_observer
    rumbster.start
  end

  after :each do
    rumbster.stop
    sleep 0.01 until rumbster.stopped?
  end

  describe "send email" do

    context  "use a list of email as mail.to (LOGSTASH-827)" do

      it "supports list of emails in to field" do
        subject = plugin.new("to" => ["email1@host, email2@host"],
                             "options" => ["port", port])
        subject.register
        subject.receive(LogStash::Event.new("message" => "hello", "dummy_match" => "ok"))
        expect(message_observer.messages.size).to eq(1)
        expect(message_observer.messages[0].to).to eq(["email1@host", "email2@host"])
      end

      it "multiple *to* addresses in a field" do
        subject = plugin.new("to" => "%{to_addr}",
                             "options" => ["port", port])
        subject.register
        subject.receive(LogStash::Event.new("message" => "hello",
                                            "to_addr" => ["email1@host", "email2@host"]))
        expect(message_observer.messages.size).to eq(1)
        expect(message_observer.messages[0].to).to eq(["email1@host", "email2@host"])
      end
    end

    context  "multi-lined text body (LOGSTASH-841)" do
      it "handles multiline messages" do
        subject = plugin.new("to" => "me@host",
                             "subject" => "Hello World",
                             "body" => "Line1\\nLine2\\nLine3",
                             "options" => ["port", port])
        subject.register
        subject.receive(LogStash::Event.new("message" => "hello"))
        expect(message_observer.messages.size).to eq(1)
        expect(message_observer.messages[0].subject).to eq("Hello World")
        expect(message_observer.messages[0].body.raw_source).to eq("Line1\r\nLine2\r\nLine3\r\n")
      end

      context  "use nil authenticationType (LOGSTASH-559)" do
        it "reads messages correctly" do
          subject = plugin.new("to" => "me@host",
                               "subject" => "Hello World",
                               "body" => "Line1\\nLine2\\nLine3",
                               "options" => ["port", port, "authenticationType", "nil"])
          subject.register
          subject.receive(LogStash::Event.new("message" => "hello"))
          expect(message_observer.messages.size).to eq(1)
          expect(message_observer.messages[0].subject).to eq("Hello World")
          expect(message_observer.messages[0].body.raw_source).to eq("Line1\r\nLine2\r\nLine3\r\n")
        end


        context "having no connection to the email server" do

          subject     { plugin.new("to" => "me@host") }
          let(:event) { LogStash::Event.new("message" => "hello world") }

          before(:each) do
            subject.register
          end

          it "should send without throwing an error" do
            expect { subject.receive(event) }.not_to raise_error
          end
        end

      end
    end
  end
end
