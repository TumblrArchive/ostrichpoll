module OstrichPoll
  ExitStatus = Struct.new(:message, :code)

  # generics
  EXIT_OK = ExitStatus.new("OK", 0)

  # could not connect to http endpoint
  EXIT_NOHTTP = ExitStatus.new("Ostrichpoll Could not connect to HTTP endpoint", 1)
end
