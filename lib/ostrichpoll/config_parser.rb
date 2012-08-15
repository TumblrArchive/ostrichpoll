require 'ostrichpoll/ostrich_validator'

module OstrichPoll
  # traverses a nested hashmap (the parsed config YAML)
  # returning a set of hosts and validators
  class ConfigParser
    def self.parse(map)
      hosts = []

      map.each do |host_config|
        host = Host.new
        host_config.each do |key,value|
          case key
            when 'url'
              host.url = value

            when 'rate_file'
              host.rate_file = value

            when 'validations'
              validations = parse_validations(value)

              validations.each do |v|
                v.host_instance = host
              end

              host.validations = validations

            else
              Log.warn "Unknown key: #{key}. Ignoring."
          end
        end
        hosts << host
      end

      hosts
    end

    def self.parse_validations(validations)
      return [] unless validations

      validations.map do |name, v|
        self.parse_validation name, v
      end
    end

    def self.parse_validation(name, map)
      validator = Validator.new
      validator.metric = name
      map.each do |key,value|
        case key
          when 'rate'
            validator.rate = value

          when 'normal_range'
            # FIXME validate normal range (min <= max, etc.)
            validator.normal_range = value

          when 'missing'
            validator.missing = value.to_sym

          when 'exit_code'
            validator.exit_code = value

          when 'exit_message'
            validator.exit_message = value

          else
            Log.warn "Unknown key for validation: #{key}. Ignoring."
        end
      end

      validator.verify!
      validator
    end
  end
end
