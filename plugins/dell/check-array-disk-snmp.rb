#!/usr/bin/env ruby
#
# Dell storage controller array disk check 
# ===
#
# This plugin checks all array disks for health based the disk rollup status.  
# It queries the snmpd which multiplexes (proxies) the request to the backend dsm_sa_snmpd process.
#
# Copyright 2014 Contegix http://contegix.com
# Authors:
#   Christopher Geers <christopher.geers@contegix.com>
#
# Depends:
#   Dell OMSA dsm_sa_snmpd service
#   ruby-snmp
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
# 
# Relevant MIB details:
#
# -- 1.3.6.1.4.1.674.10893.1.20.130.4.1.23
#               arrayDiskRollUpStatus OBJECT-TYPE
#                       SYNTAX DellStatus
#                       ACCESS read-only
#                       STATUS mandatory
#                       DESCRIPTION
#                               "Severity of the array disk state.
#                               This is the combined status of the array disk and its components.
#                               Possible values:
#                               1: Other
#                               2: Unknown
#                               3: OK 
#                               4: Non-critical 
#                               5: Critical
#                               6: Non-recoverable"
#                       ::= { arrayDiskEntry 23 }

require 'sensu-plugin/check/cli'
require 'snmp'

class DellArrayDiskStatus < Sensu::Plugin::Check::CLI

  option :host,
    :short => '-h HOST',
    :default => '127.0.0.1'

  option :port,
    :short => '-p PORT',
    :default => '161'

  option :community,
    :short => '-c COMMUNITY',
    :default => 'public'

  option :warn,
    :short => '-w WARN',
    :proc => proc {|a| a.to_i },
    :default => 4

  option :crit,
    :short => '-c CRIT',
    :proc => proc {|a| a.to_i },
    :default => 5

  def run

    dell_arraydisk_oid = "1.3.6.1.4.1.674.10893.1.20.130.4.1.23"
    dell_arraydisk_state = []
    begin
      SNMP::Manager.open(:host => config[:host], :port => config[:port], :community => config[:community]) do |manager|
        manager.walk([dell_arraydisk_oid]) do |row|
          row.each do |vb|
            dell_arraydisk_state << vb.value.to_i
          end
        end
      end
    rescue SNMP::RequestTimeout
      message "Can't connect to #{config[:host]}:#{config[:port]}"
    rescue => exception
      message "Unspecified error:\n#{exception.backtrace.join("\n")}"
    end
    unknown if dell_arraydisk_state.length == 0 or dell_arraydisk_state.detect { |status| status == 2 }
    critical if dell_arraydisk_state.detect { |status| status >= config[:crit] }
    warning if dell_arraydisk_state.detect { |status| status >= config[:warn] }
    ok
  end
end
