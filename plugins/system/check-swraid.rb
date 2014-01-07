#!/usr/bin/env ruby
#
# Linux Software RAID status check
# ===
#
# This plugin checks the software raid state of any arrays found in /proc/mdstat.
# It uses mdadm's monitor option for event declaration.
#
# Copyright 2014 Contegix http://contegix.com
# Authors:
#   Christopher Geers <christopher.geers@contegix.com>
#
# Depends:
#   mdadm
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#

require 'sensu-plugin/check/cli'

class SWRAIDStatus < Sensu::Plugin::Check::CLI
  CRITICAL_EVENTS = ['DegradedArray', 'DeviceDisappeared', 'Fail', 'FailSpare']
  WARNING_EVENTS = ['SparesMissing']
  def run
    if File.executable? '/sbin/mdadm'
      test_stdout = %x{/sbin/mdadm --detail --scan --test}
      unknown message "error scanning for software RAID devices" if $?.exitstatus == 4
      unknown message "no software RAID devices found" if test_stdout.lines.count == 0
      ok if $?.exitstatus == 0
    else
      unknown message "software RAID is not available"
    end
    # There must be a problem
    problem_arrays = []
    array_details = "\n"
    %x{/sbin/mdadm --monitor --oneshot --scan --program=/bin/echo}.each_line do |line|
      problem_arrays << line.split(' ')[1] if CRITICAL_EVENTS.include? line.split(' ')[0]
    end
    problem_arrays.each { |array| array_details << %x{/sbin/mdadm --detail #{array}} }
    critical array_details
    warning
  end
end
