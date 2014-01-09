#!/usr/bin/env ruby
#
# Dell storage controller physical disk check 
# ===
#
# This plugin checks all physical disks for health.  
#
# Copyright 2014 Contegix http://contegix.com
# Authors:
#   Christopher Geers <christopher.geers@contegix.com>
#
# Depends:
#  omreport
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
# 

require 'sensu-plugin/check/cli'
require 'nokogiri'

class DellPhysicalDisk < Sensu::Plugin::Check::CLI

  option :warn,
    :short => '-w WARN',
    :proc => proc {|a| a.to_i },
    :default => 3

  option :crit,
    :short => '-c CRIT',
    :proc => proc {|a| a.to_i },
    :default => 4

  def run
    omreport_bin = '/opt/dell/srvadmin/bin/omreport'
    msg = "\n"
    physical_disks = []
    disks_ok = true
    physical_disk_attributes = [ :ObjStatus, :EnclosureIndex, :DeviceSerialNumber, :DiskProductVendor, :ProductID, :PartNo]
    unknown message "Dell Utilities not available" unless File.executable? omreport_bin
    Nokogiri::XML( %x{#{omreport_bin} storage pdisk controller=0 -fmt xml} ).xpath('//DCStorageObject').each do |phy_disk|
      physical_disk = {}
      physical_disk_attributes.each do |attrib|
        physical_disk[attrib] = phy_disk.children.at(attrib).text.strip
      end
      physical_disks << physical_disk
    end
    unknown message "No disks detected" if physical_disks.length == 0
    physical_disks.each do |disk|
      status = case disk[:ObjStatus].to_i
        when 1 then "Unknown"
        when 2 then "OK"
        when 3 then "Non-critical"
        when 4 then "Critical"
        when 5 then "Non-recoverable"
        else "Other"
      end
      msg << "Slot:#{disk[:EnclosureIndex]} Status:#{status} Manufacturer:#{disk[:DiskProductVendor]} Model:#{disk[:ProductID]} Serial:#{disk[:DeviceSerialNumber]}\n"
      disks_ok = false if disk[:ObjStatus].to_i >= config[:warn]
    end
    message msg unless disks_ok
    critical if physical_disks.detect { |disk| disk[:ObjStatus].to_i >= config[:crit] }
    warning if physical_disks.detect { |disk| disk[:ObjStatus].to_i >= config[:warn] }
    ok
  end
end
