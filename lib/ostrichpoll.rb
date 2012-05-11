#
#  Copyright 2012, Tumblr Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require 'yaml'
require 'trollop'
require 'pp'
require 'net/http'
require 'logger'

require 'ostrichpoll/string'
require 'ostrichpoll/version'
require 'ostrichpoll/exit_codes'
require 'ostrichpoll/config_parser'

module OstrichPoll
  Log = Logger.new(STDERR)
  Log.formatter = lambda do |severity, datetime, progname, msg|
    "#{severity} #{msg}\n"
  end

  @opts = Trollop::options do
    version = "ostrichpoll #{VERSION}"
    banner_text = <<-EOS
      A ruby utility for monitoring JSON endpoints (Twitter Ostrich, specifically)
      for normal ranges of values.
    EOS
    banner(banner_text.strip_heredoc)

    opt :configfile, "YAML configuration",
        type: :string

    opt :url, "url",
        type: :string,
        default: 'http://127.0.0.1:9900/stats.json'

    opt :debug, "debug",
        :default => false
  end

  if @opts[:configfile] and not File.readable_real?(@opts[:configfile])
    Trollop::die "configuration file #{@opts[:configfile]} cannot be read"
  end

  if @opts[:debug]
    Log.level = Logger::DEBUG
  else
    Log.level = Logger::WARN
  end

  # TODO rewrite the basic check in terms of a hard-coded validator, much cleaner
  # check that the host+port respond to http
  if @opts[:configfile]
    yaml = YAML.load_file @opts[:configfile]
    hosts = ConfigParser.parse(yaml)

    retval = false
    hosts.each do |h|
      retval = h.validate unless retval
    end

    # use the exitcode, unless none is given
    exit retval if retval

  else
    # if we don't have a config file, simply check that the host and port respond to http
    begin
      uri = URI.parse @opts[:url]
      @response = Net::HTTP.get uri
    rescue Exception => e
      Log.warn e
      exit EXIT_NOHTTP
    end
  end

rescue SystemExit => e
  exit e.status

rescue Exception => e
  Log.error e
  exit EXIT_ERROR # exit with error
end

exit OstrichPoll::EXIT_OK