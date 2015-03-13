# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# Send email when an output is received. Alternatively, you may include or
# exclude the email output execution using conditionals. 
class LogStash::Outputs::Email < LogStash::Outputs::Base

  config_name "email"

  # The fully-qualified email address to send the email to.
  #
  # This field also accepts a comma-separated string of addresses, for example: 
  # `"me@host.com, you@host.com"`
  #
  # You can also use dynamic fields from the event with the `%{fieldname}` syntax.
  config :to, :validate => :string, :required => true

  # The fully-qualified email address for the From: field in the email.
  config :from, :validate => :string, :default => "logstash.alert@nowhere.com"

  # The fully qualified email address for the Reply-To: field.
  config :replyto, :validate => :string

  # The fully-qualified email address(es) to include as cc: address(es).
  #
  # This field also accepts a comma-separated string of addresses, for example: 
  # `"me@host.com, you@host.com"`
  config :cc, :validate => :string

  # How Logstash should send the email, either via SMTP or by invoking sendmail.
  config :via, :validate => :string, :default => "smtp"

  # Specify the options to use:
  #
  # Via SMTP: `smtpIporHost`, `port`, `domain`, `userName`, `password`, `authenticationType`, `starttls`
  #
  # Via sendmail: `location`, `arguments`
  #
  # If you do not specify any `options`, you will get the following equivalent code set in
  # every new mail object:
  # [source,ruby]
  #     Mail.defaults do
  #       delivery_method :smtp, { :smtpIporHost         => "localhost",
  #                                :port                 => 25,
  #                                :domain               => 'localhost.localdomain',
  #                                :userName             => nil,
  #                                :password             => nil,
  #                                :authenticationType   => nil,(plain, login and cram_md5)
  #                                :starttls             => true  }
  #
  #       retriever_method :pop3, { :address             => "localhost",
  #                                 :port                => 995,
  #                                 :user_name           => nil,
  #                                 :password            => nil,
  #                                 :enable_ssl          => true }
  #
  #       Mail.delivery_method.new  #=> Mail::SMTP instance
  #       Mail.retriever_method.new #=> Mail::POP3 instance
  #     end
  #
  # Each mail object inherits the defaults set in Mail.delivery_method. However, on
  # a per email basis, you can override the method:
  # [source,ruby]
  #     mail.delivery_method :sendmail
  #
  # Or you can override the method and pass in settings:
  # [source,ruby]
  #     mail.delivery_method :sendmail, { :address => 'some.host' }
  #
  # You can also just modify the settings:
  # [source,ruby]
  #     mail.delivery_settings = { :address => 'some.host' }
  #
  # The hash you supply is just merged against the defaults with "merge!" and the result
  # assigned to the mail object.  For instance, the above example will change only the
  # `:address` value of the global `smtp_settings` to be 'some.host', retaining all other values.
  config :options, :validate => :hash, :default => {}

  # Subject: for the email.
  config :subject, :validate => :string, :default => ""

  # Body for the email - plain text only.
  config :body, :validate => :string, :default => ""

  # HTML Body for the email, which may contain HTML markup.
  config :htmlbody, :validate => :string, :default => ""

  # Attachments - specify the name(s) and location(s) of the files.
  config :attachments, :validate => :array, :default => []

  # contenttype : for multipart messages, set the content-type and/or charset of the HTML part.
  # NOTE: this may not be functional (KH)
  config :contenttype, :validate => :string, :default => "text/html; charset=UTF-8"

  public
  def register
    require "mail"

    # Mail uses instance_eval which changes the scope of self so @options is
    # inaccessible from inside 'Mail.defaults'. So set a local variable instead.
    options = @options

    if @via == "smtp"
      Mail.defaults do
        delivery_method :smtp, {
          :address              => options.fetch("smtpIporHost", "localhost"),
          :port                 => options.fetch("port", 25),
          :domain               => options.fetch("domain", "localhost"),
          :user_name            => options.fetch("userName", nil),
          :password             => options.fetch("password", nil),
          :authentication       => options.fetch("authenticationType", nil),
          :enable_starttls_auto => options.fetch("starttls", false),
          :debug                => options.fetch("debug", false)
        }
      end
    elsif @via == 'sendmail'
      Mail.defaults do
        delivery_method :sendmail
      end
    else
      Mail.defaults do
        delivery_method :@via, options
      end
    end # @via tests
    @logger.debug("Email Output Registered!", :config => @config)
  end # def register

  public
  def receive(event)
    return unless output?(event)

      @logger.debug? and @logger.debug("Creating mail with these settings : ", :via => @via, :options => @options, :from => @from, :to => @to, :cc => @cc, :subject => @subject, :body => @body, :content_type => @contenttype, :htmlbody => @htmlbody, :attachments => @attachments, :to => to, :to => to)
      formatedSubject = event.sprintf(@subject)
      formattedBody = event.sprintf(@body)
      formattedHtmlBody = event.sprintf(@htmlbody)
      mail = Mail.new
      mail.from = event.sprintf(@from)
      mail.to = event.sprintf(@to)
      if @replyto
        mail.reply_to = event.sprintf(@replyto)
      end
      mail.cc = event.sprintf(@cc)
      mail.subject = formatedSubject
      if @htmlbody.empty?
        formattedBody.gsub!(/\\n/, "\n") # Take new line in the email
        mail.body = formattedBody
      else
        mail.text_part = Mail::Part.new do
          content_type "text/plain; charset=UTF-8"
          formattedBody.gsub!(/\\n/, "\n") # Take new line in the email
          body formattedBody
        end
        mail.html_part = Mail::Part.new do
          content_type "text/html; charset=UTF-8"
          body formattedHtmlBody
        end
      end
      @attachments.each do |fileLocation|
        mail.add_file(fileLocation)
      end # end @attachments.each
      @logger.debug? and @logger.debug("Sending mail with these values : ", :from => mail.from, :to => mail.to, :cc => mail.cc, :subject => mail.subject)
      mail.deliver!
  end # def receive
end # class LogStash::Outputs::Email
