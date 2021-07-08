require "logstash/devutils/rspec/spec_helper"

# use a dummy NOOP filter to test Filters::Base
class LogStash::Filters::NOOP < LogStash::Filters::Base
  config_name "noop"
  milestone 2

  def register; end

  def filter(event)
    filter_matched(event)
  end
end
