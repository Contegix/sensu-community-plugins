#!/usr/bin/env ruby
#
# Dell storage controller virtual disk check 
# ===
#
# This plugin checks all defined virtual disks for health based on the array state.  
# It queries the snmpd which multiplexes (proxies) the request to the backend dsm_sa_snmpd process.
#
# Copyright 2013 Contegix http://contegix.com
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
#-- 1.3.6.1.4.1.674.10893.1.20.140.1.1.4
#               virtualDiskState OBJECT-TYPE
#                       SYNTAX INTEGER
#                               {
#                               ready(1),
#                               failed(2),
#                               online(3),
#                               offline(4),
#                               degraded(6),
#                               verifying(7),
#                               resynching(15),
#                               regenerating(16),
#                               failedRedundancy(18),
#                               rebuilding(24),
#                               formatting(26),
#                               reconstructing(32),
#                               initializing(35),
#                               backgroundInit(36),
#                               permanentlyDegraded(52)
#                               }
#                       ACCESS read-only
#                       STATUS mandatory
#                       DESCRIPTION
#                               "The current condition of this virtual disk
#                               (which includes any member array disks.)
#                               Possible states:
#                                0: Unknown
#                                1: Ready - The disk is accessible and has no known problems. 
#                                2: Failed - Access has been lost to the data or is about to be lost.
#                                3: Online
#                                4: Offline - The disk is not accessible. The disk may be corrupted or intermittently unavailable. 
#                                6: Degraded - The data on the virtual disk is no longer fault tolerant because one of the underlying disks is not online.
#                               15: Resynching
#                               16: Regenerating
#                               24: Rebuilding
#                               26: Formatting
#                               32: Reconstructing
#                               35: Initializing
#                               36: Background Initialization
#                               38: Resynching Paused
#                               52: Permanently Degraded
#                               54: Degraded Redundancy"
#                       ::= { virtualDiskEntry 4 }

require 'sensu-plugin/check/cli'
require 'snmp'

class DellVirtualDiskStatus < Sensu::Plugin::Check::CLI

  option :host,
    :short => '-h HOST',
    :default => '127.0.0.1'

  option :port,
    :short => '-p PORT',
    :default => '161'

  option :community,
    :short => '-c COMMUNITY',
    :default => 'public'

  def run

    dell_virtualdisk_oid = "1.3.6.1.4.1.674.10893.1.20.140.1.1.4"
    dell_virtualdisk_state = []
    begin
      SNMP::Manager.open(:host => config[:host], :port => config[:port], :community => config[:community]) do |manager|
        manager.walk([dell_virtualdisk_oid]) do |row|
          row.each do |vb|
            dell_virtualdisk_state << vb.value.to_i
          end
        end
      end
    rescue SNMP::RequestTimeout
      message "Can't connect to #{config[:host]}:#{config[:port]}"
    rescue => exception
      message "Unspecified error:\n#{exception.backtrace.join("\n")}"
    end
    unknown if dell_virtualdisk_state.length == 0 or dell_virtualdisk_state.detect { |status| status == 0 }
    critical if dell_virtualdisk_state.detect { |status| [2, 4, 6].include? status }
    ok if dell_virtualdisk_state.detect { |status| [1, 3].include? status }
    warning
  end
end
