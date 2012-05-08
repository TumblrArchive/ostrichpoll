#
# implements the actual validators
#

require 'json'
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

    def validate
      uri = URI.parse url
      response = Net::HTTP.get uri

      # parse response
      json = JSON.parse(response) rescue (
        Log.error "Invalid JSON response: #{response}"
        exit EXIT_ERROR
      )

      stored_values = {}
      if rate_file
        # read in rate-file
        stored_text = File.read(rate_file) rescue (
          Log.warn "Could not read rate file: #{rate_file}"
          "{}"
        )

        stored_values = JSON.parse(stored_text) rescue (
          Log.warn "Could not parse rate file content: #{stored_text}"
          {}
        )
      end

      # execute each validations:
      validations.each do |v|
        v.check(find_value(json, v.metric))
      end
    end

    def previous_reading(key)
      return find_value(stored_values, key)
    end

    def find_value(map, key)
      tree = map
      key.split('/').each do |selector|
        return nil unless tree
        tree = tree[selector]
      end

      # final "tree" is the actual node
      tree
    end
  end

  # this is a pretty weak and limiting definition of a validator,
  # but it's quick to develop and clear how to extend
  class Validator
    attr_accessor :host_instance

    attr_accessor :metric
    attr_accessor :rate
    attr_accessor :normal_range
    attr_accessor :missing
    attr_accessor :exit_code

    def init
      rate = false
      exit_code = 1
      missing = :ignore
    end

    def verify!
      Log.warn "Invalid metric #{metric.inspect}" unless metric.is_a? String
      Log.warn "Invalid exit code: #{exit_code.inspect}" unless exit_code.is_a? Integer

      if normal_range
        Log.warn "Invalid normal range: #{normal_range.inspect}" unless normal_range.is_a? Array
      end
    end

    def check (value)
      # error on missing value unless we ignore missing
      unless value || missing == :ignore
        Log.warn "#{metric}: value missing, treating as error"
        return exit_code
      end

      # compute rate
      if rate
        timestamp, previous = host_instance.previous_reading(metric)

        if previous
          # change since last measure
          value -= previous

          # divide by seconds elapsed
          value /= Time.now.to_i - timestamp

        else
          # let it pass
          Log.info "#{metric}: no previous reading for rate"
          return true
        end
      end

      # ensure value is within normal range
      if normal_range
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
          Log.warn "#{metric}: read value #{value} is below normal range #{lo}"
          return exit_code
        end

        if hi && value > hi
          Log.warn "#{metric}: read value #{value} is above normal range #{hi}"
          return exit_code
        end
      end

      true
    end
  end
end