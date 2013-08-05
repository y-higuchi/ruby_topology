require "forwardable"
require "link"
require "observer"
require "trema-extensions/port"


#
# Topology Event class to pass to observer
#
class TopologyEvent
  attr_reader :action
  attr_reader :subject
  attr_reader :topology

  # @param [Symbol] action One of :add, :delete, :update
  # @param [Number, (Number,Trema::Port), Link] subject Switch dpid, [dpid, Port], or Link
  # @param [Topology] topology
  def initialize action, subject, topology
    @action = action
    @subject = subject
    @topology = topology
  end
end

#
# Topology information containing the list of known switches, ports,
# and links.
#
class Topology
  include Observable
  extend Forwardable


  def_delegator :@ports, :each_pair, :each_switch
  def_delegator :@links, :each, :each_link


  def initialize observer
    # dpid -> [Trema::Port]
    @ports = Hash.new { [].freeze }
    # [Link]
    @links = []
    add_observer observer
  end

  def add_switch dpid
    @ports[ dpid ] = [] if not @ports.include?(dpid)
    changed
    notify_observers TopologyEvent.new(:add, dpid, self)
  end

  def delete_switch dpid
    @ports[ dpid ].each do | each |
      delete_port dpid, each
    end
    @ports.delete dpid
    changed
    notify_observers TopologyEvent.new(:delete, dpid, self)
  end


  def update_port dpid, port
    deleted = @ports[ dpid ].reject! { |e| e.number == port.number }
    @ports[ dpid ] += [ port ]
    if deleted == nil
      # port added event
      changed
      notify_observers TopologyEvent.new(:add, [dpid,port], self)
      # switch update event
      changed
      notify_observers TopologyEvent.new(:update, dpid, self)
    else
      # port update event
      changed
      notify_observers TopologyEvent.new(:update, [dpid,port], self)
    end
  end


  def add_port dpid, port
    update_port dpid, port
  end


  def delete_port dpid, port
    delete_link_by dpid, port
    @ports[ dpid ].delete_if { |e| e.number == port.number }
    # port delete event
    changed
    notify_observers TopologyEvent.new(:delete, [dpid,port], self)
  end


  def add_link_by dpid, packet_in
    raise "Not an LLDP packet!" if not packet_in.lldp?

    link = Link.new( dpid, packet_in )
    if not @links.include?( link )
      @links << link
      @links.sort!
      changed
      # link added event
      notify_observers TopologyEvent.new(:add, link, self)
    end
  end


  ##############################################################################
  private
  ##############################################################################


  def delete_link_by dpid, port
    to_delete = []
    @links.each do | each |
      if each.has?( dpid, port.number )
        to_delete << each
      end
    end
    to_delete.each do |link|
      @links.delete(link)
      changed
      # link deleted event
      notify_observers TopologyEvent.new(:delete, link, self)
    end
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
