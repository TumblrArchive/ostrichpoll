require 'yaml'
require 'trollop'
require 'pp'
require 'net/http'
require 'logger'

require 'ostrichpoll/string'
require 'ostrichpoll/version'
require 'ostrichpoll/exit_status'
require 'ostrichpoll/config_parser'

module OstrichPoll
  Log = Logger.new(STDERR)

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
    retval = nil

    hosts.each do |h|
      retval = h.validate if retval.nil?
    end

    # use the exitcode, unless none is given
    retval.exit unless retval.nil?

  else
    # if we don't have a config file, simply check that the host and port respond to http
    begin
      uri = URI.parse @opts[:url]
      @response = Net::HTTP.get uri
    rescue Exception => e
      Log.warn e
      EXIT_NOHTTP.exit
    end
  end

rescue SystemExit => e
  exit e.status

rescue Exception => e
  Log.error e
  ExitStatus.new(e.message, 1).exit # exit with error
end

OstrichPoll::EXIT_OK.exit
