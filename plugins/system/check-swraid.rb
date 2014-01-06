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
  def run
    unknown
    critical
    warning
    ok
  end
end
