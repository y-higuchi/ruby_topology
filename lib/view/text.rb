require "trema"


module View
  class Text
    include Trema::Logger


    def update event
      topology = event.topology
      topology.each_link do | each |
        info each.to_s
      end
      info "topology updated"
    end
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
