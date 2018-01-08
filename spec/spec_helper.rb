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

def craft_multi_part_email(body, htmlbody, content_type)
  charset = "charset=UTF-8"
  content_encoding = "Content-Transfer-Encoding: 7bit"
 
  # Have to get the generated part of the header, eg:
  # --==_mimepart_5a462a1fda04b_efe7d032127
  mimetype = content_type.split('; ')[1][10..-2]

  plain_header = "\n--#{mimetype}\nContent-Type: text/plain;\n #{charset}\n#{content_encoding}\n\n"
  html_header = "\n--#{mimetype}\nContent-Type: text/html;\n #{charset}\n#{content_encoding}\n\n"

  "#{plain_header}#{body}#{html_header}#{htmlbody}\n\n--#{mimetype}--\n"
end
