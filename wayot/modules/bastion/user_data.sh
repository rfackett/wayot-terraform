#!/bin/bash

# To install the Stackdriver monitoring agent:
curl -sSO https://dl.google.com/cloudagents/install-monitoring-agent.sh
bash install-monitoring-agent.sh

# To install the Stackdriver logging agent:
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
bash install-logging-agent.sh
