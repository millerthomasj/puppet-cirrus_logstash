# logstash

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup - Endpoints](#setup)
    * [Inputs](#Inputs)
    * [Filters](#Filters)
    * [Outputs](#Outputs)

## Overview

This module uses the puppetlabs logstash module to install logstash and configure
one of three types of end points.

## Setup

Once logstash is installed we will need to manage logstash endpoints. 

### Inputs
Inputs will generally be from the beats protocol, this is handled by the beats input plugin which
is installed by default. We can also except traffic from any rsyslog client on port 5000.

```javascript
input {
  tcp {
   type => syslog
   port => 5000
  }
  udp {
   type => syslog
   port => 5000
  }
}
input {
  beats {
   port => 5044
  }
}
```

### Filters
Filters will be created as needed and provided by the Openstack community, below is an example of
a simple rsyslog filter:

```javascript
filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
    if !("_grokparsefailure" in [tags]) {
      mutate {
        remove_field => [ "message", "@version" ]
      }
    }
  }
}
```

### Outputs
In most cases outputs for logstash will be elasticsearch. Since all logstash hosts are also
elasticsearch clients we can send most outputs to localhost.

```javascript
output {
  elasticsearch { 
    hosts => ["localhost:9200"] 
    sniffing => true
    manage_template => false
  }
}
```
