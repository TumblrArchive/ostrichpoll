# OstrichPoll

OstrichPoll is a tiny utility for monitoring Twitter Ostrich services.

* poll multiple endpoints
* specify normal ranges for metrics and gauges through YAML configuration


## Installation

    $ gem install ostrichPoll

## Execution

OstrichPoll may be executed with a simple `ostrichpoll` which will ensure a 200 response
is given from `127.0.0.1:9900/stats.json`.

You may change the endpoint:

    ostrichpoll -u devbox:9999/stats.json

The interesting part of ostrichpoll is when you give a configuration file
that specifies normal ranges for metrics:

    ostrichpoll -c pollconfig.yml

## Configuration

Configuration is specified in the format:

    ---
    - url: 127.0.0.1:9900/stats.txt?period=10
      rate_file: /tmp/parmesan-http-ostrich-rate.yml
      validations:
        counters/KafkaEventSink_messageDropped:
          rate: true
          normal_range: [0, 5]
          missing: ignore
          exit_code: 2
        metrics/KafkaEventSink_append_msec/p99:
          normal_range: [0, 10]
          missing: error
          exit_code: 3
    - url: 127.0.0.1:9901/stats.txt
    ...

Command line options may fill in