#The class has the methods for parsing and keeping parameters of resource type(Like vlan, portchannel etc) values  
require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/generic_value'
require 'puppet/util/monkey_patches_ftos'

class Puppet::Util::NetworkDevice::Dell_ftos::Model::ScopedValue < Puppet::Util::NetworkDevice::Dell_ftos::Model::GenericValue
  attr_accessor :scope, :scope_name
  def scope(*args, &block)
    return @scope if args.empty? && block.nil?
    @scope = (block.nil? ? args.first : block)
  end

  def scope_name(*args, &block)
    return @scope_name if args.empty? && block.nil?
    @scope_name = (block.nil? ? args.first : block)
  end

  # pass a block if a single scope can match multiple names
  # the block must split up the given content and matched name
  # and return a list of new content and name pairs
  def scope_match(&block)
    return @scope_match if block.nil?
    @scope_match = block
  end

  def munge_scope(content, name)
    if self.scope_match.is_a? Proc
      self.scope_match.call(content, name)
    else
      [[content, name]]
    end
  end

  def extract_scope(txt)
    raise "No scope_name configured" if @scope_name.nil?
    return if txt.nil? || txt.empty?
    munged = txt.scan(scope).collect do |content,name|
      munge_scope(content,name)
    end.reduce(:+) || []

    munged.collect do |pair|
      (content,name) = pair
      content if name == @scope_name
    end.reject { |val| val.nil? }.first
  end

  def parse(txt)
    result = extract_scope(txt)
    if result.nil? || result.empty?
      Puppet.debug("Scope #{scope} not found for Param #{name}")
      return
    end
    if self.match.is_a?(Proc)
      self.value = self.match.call(result)
    else
      self.value = result.scan(self.match).flatten[self.idx]
    end
    self.evaluated = true
  end

  def parseforerror(outtxt,placestr)
    if outtxt =~/Error:\s*(.*)/
      Puppet.info "ERROR:#{$1}"
      raise "Unable to "+placestr+".Reason:#{$1}"
    end
  end
end
