#!/usr/bin/env ruby
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'
require 'xmpp4r/client'
require 'xmpp4r/muc'
require 'rickshaw'
include Jabber

class XmppHandler < Sensu::Handler

  def event_name
    @event['client']['name'] + '/' + @event['check']['name']
  end

def uid
    "#{@event['client']['name']}/#{@event['check']['name']}".to_sha1[0,8]
end

  def handle
    xmpp_jid = settings['xmpp']['jid']
    xmpp_password = settings['xmpp']['password']
    xmpp_target = settings['xmpp']['target']
    xmpp_target_type = settings['xmpp']['target_type']
    xmpp_server = settings['xmpp']['server']

    if @event['action'].eql?("resolve")
        action_word = "RESOLVED"
    elseif @event['action'].eql?("create")
        action_word = "CREATED"
    else
        action_word = "NOTIFICATION"
    end

    notification = "#{action_word}\t[#{event_name}]: #{@event['check']['notification']}\n\t#{@event['check']['output']}"

    body = "[#{@uid}] #{@notification}"
    
    jid = JID.new(xmpp_jid)
    cl = Client.new(jid)
    cl.connect(xmpp_server)
    cl.auth(xmpp_password)
    if xmpp_target_type == 'conference'
      m = Message.new(xmpp_target, body)
      room = MUC::MUCClient.new(cl)
      room.join(Jabber::JID.new(xmpp_target+'/'+cl.jid.node))
      room.send m
      room.exit
    else
      m = Message.new(xmpp_target, body).set_type(:normal).set_id('1').set_subject("SENSU ALERT!")
      cl.send m
    end
    cl.close
  end

end

