module OstrichPoll

  class ExitStatus
    attr_accessor :message, :code

    def initialize(message, code)
      @message = message
      @code = code
    end
    
    def exit
      puts @message
      Kernel.exit @code
    end
  end


  # generics
  EXIT_OK = ExitStatus.new("OK", 0)
  EXIT_FAIL = ExitStatus.new("", 1)

  # could not connect to http endpoint
  EXIT_NOHTTP = ExitStatus.new("Ostrichpoll Could not connect to HTTP endpoint", 1)
end
