# Ostrichpoll

Ostrichpoll is a tiny utility for monitoring Twitter Ostrich services.
Effectively it can monitor any service which exposes internal metrics in JSON
over HTTP.

Features:

* not a daemon: Ostrichpoll is intended to used by `monit` or a similar tool
  as part of a health check for a proper service
* validate multiple endpoints in a single execution
* specify normal ranges for metrics and gauges through YAML configuration
* support for "rate" measurements, specifying acceptable change per second for
  a metric. (useful for counters and other monotonic metrics)


## Installation

    $ gem install ostrichpoll

## Execution

Ostrichpoll may be executed with a simple `ostrichpoll` which will ensure a 200 response
is given from `127.0.0.1:9900/stats.json`.

You may change the endpoint:

    ostrichpoll -u devbox:9999/stats.json

The interesting part of Ostrichpoll is when you give a configuration file
that specifies normal ranges for individual metrics:

    ostrichpoll -c pollconfig.yml

Use `-d` to enable extra logging for debugging.

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

### Options

* `url` - an endpoint which exposes JSON stats. If this endpoint is not available, Ostrichpoll will exit with `-1` (really `255`).
* `rate_file` - where to store rate measurements between executions of Ostrichpoll.
* `validations` - a list of validations to execute with the following options:
    * the key is the name of the metric. Nested metrics are supported through the `/` notation.
    * `rate` when set to true, compute the change per second since this value was last seen. You must specify a `rate_file` for this to work. Obviously, on the first execution of Ostrichpoll this validation will be ignored.
    * `normal_range` an array specifying the minimum and maximum (inclusive) values which are acceptable for this metric
    * `missing` behavior if the metric is not seen in the output at all. (error by default)
    * `exit_code` what value Ostrichpoll should exit with if this error is seen.
    
### Notes
Ostrichpoll is setup to execute all validations on each execution, even if one of the early validations fails, the output from all validations is logged to stderr. However, the exit code is the exit code from the first erroring validation.


## License

Copyright 2012, Tumblr Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
