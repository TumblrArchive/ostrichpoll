#
# implements the actual validators
#

require 'json'
require 'yaml'
require 'net/http'

module OstrichPoll
  class Host
    attr_accessor :url
    attr_accessor :rate_file
    attr_accessor :validations


    def initialize
      validations = []
    end

    attr_accessor :stored_values
    attr_accessor :stored_timestamp

    def validate
      uri = URI.parse url
      response = Net::HTTP.get uri rescue (
        error_msg = "Unable to connect to host #{uri}"
        Log.error error_msg
        return ExitStatus.new(error_msg, 1)
      )

      # parse response
      json = JSON.parse(response) rescue (
        error_msg = "Invalid JSON response: #{response}"
        Log.error error_msg
        return ExitStatus.new(error_msg, 1)
      )

      @stored_values = {}
      if rate_file
        # read in rate-file
        @stored_values = YAML.load_file(rate_file) rescue (
          Log.warn "Could not parse rate file: #{rate_file}"
          {}
        )

        @stored_timestamp = stored_values['ostrichpoll.timestamp']
        unless @stored_timestamp
          Log.warn "No 'ostrichpoll.timestamp' found in rate file: #{rate_file}"
        end

        # write out new rate file
        json['ostrichpoll.timestamp'] = Time.now.to_i
        File.open(rate_file, 'w') do |f|
          f.puts json.to_yaml
        end
      end
      
      retval = nil

      # execute each validation:
      if validations
        matched_validations = []
        validations.each do |v|
          if(v.regex)
            find_validation_names_by_regex(json, v.metric).each do |n|
              matched_validator = v.clone
              matched_validator.metric = n
              matched_validations << matched_validator
            end
          else
            matched_validations << v
          end
        end

        matched_validations.each do |v|
          value = v.check(find_value(json, v.metric))
          retval = value if retval.nil?
        end
      end

      retval
    end

    def previous_reading(key)
      return stored_timestamp, find_value(stored_values, key)
    end

    # split on a slash, unless it's escaped
    def split_on_slash(key, *limit)
      key.split(/(?<!\\)\//, *limit).map do |str|
          str.sub('\\', '')
      end
    end

    def find_validation_names_by_regex(tree, key)
      split_key = split_on_slash(key, 2)
      selector = split_key.first

      stat_name_matches = []
      regexp = /#{selector}/

      tree.each do |k, v|
        if regexp.match(k) do
            if v.kind_of? Hash
              find_validation_names_by_regex(v, split_key.last).each do |s|
                stat_name_matches << "#{k}/#{s}"
              end
            elsif split_key.size == 1 #This is the last match
              stat_name_matches << k
            end
          end
        end
      end
      stat_name_matches
    end

    def find_value(map, key)
      tree = map
      split_on_slash(key).each do |selector|
        return nil unless tree.kind_of? Hash
        tree = tree[selector]
      end

      tree
    end
  end

  # this is a pretty weak and limiting definition of a validator,
  # but it's quick to develop and clear how to extend
  class Validator
    attr_accessor :host_instance

    attr_accessor :metric
    attr_accessor :rate
    attr_accessor :regex
    attr_accessor :normal_range
    attr_accessor :missing
    attr_accessor :exit_code
    attr_accessor :exit_message

    def init
      @rate = false
      @regex = false
      @exit_code = 1
      @exit_message = ""
      @missing = :ignore
    end

    def verify!
      Log.warn "Invalid metric #{metric.inspect}" unless metric.is_a? String
      Log.warn "Invalid exit code: #{exit_code.inspect}" unless exit_code.is_a? Integer

      if exit_message
        Log.warn "Invalid exit message: #{exit_message.inspect}" unless exit_message.is_a? String
      end

      if normal_range
        Log.warn "Invalid normal range: #{normal_range.inspect}" unless normal_range.is_a? Array
      end
    end

    def check (value)
      Log.debug "#{host_instance.url} | Given: #{metric}=#{value}"

      if !value.is_a? Float
        value = Float(value) rescue nil
      end

      # error on missing value unless we ignore missing
      unless value
        unless missing == :ignore
          error_msg = "#{metric}: value missing"
          Log.warn "#{error_msg}, treating as error; exit code #{exit_code}"
          return ExitStatus.new(error_msg, exit_code)
        else
          Log.debug "#{host_instance.url} |   missing value, but set to ignore"
          # not an error, but you can't check anything else
          return nil
        end
      end

      # compute rate
      if rate
        timestamp, previous = host_instance.previous_reading(metric)

        if previous
          Log.debug "#{host_instance.url} |   last seen: #{previous} @ #{timestamp}"

          # change since last measure
          value -= previous

          # divide by seconds elapsed
          value /= Time.now.to_i - timestamp

          Log.debug "#{host_instance.url} |   computed rate: #{value}"

        else
          # let it pass
          Log.info "#{metric}: no previous reading for rate"
          return nil
        end
      end

      # ensure value is within normal range
      if normal_range
        Log.debug "#{host_instance.url} |   normal range: #{normal_range.inspect}"
        case normal_range.size
          when 1 # max
            hi = normal_range.first

          when 2 # min
            lo = normal_range.first
            hi = normal_range.last

          else
            # whatever, ignore
            # the yaml deserializer shouldn't let this happen
        end

        if lo && value < lo
          Log.warn "#{metric}: read value #{value} is below normal range minimum #{lo}; exit code #{exit_code}; exit message '#{exit_message}'"
          return ExitStatus.new(exit_message, exit_code)
        end

        if hi && value > hi
          Log.warn "#{metric}: read value #{value} is above normal range maximum #{hi}; exit code #{exit_code}; exit message '#{exit_message}'"
          return ExitStatus.new(exit_message, exit_code)
        end

        Log.debug "#{host_instance.url} |   within normal range"
      end

      nil
    end
  end
end
