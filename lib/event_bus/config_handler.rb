require 'ostruct'
require 'active_support/core_ext/hash/indifferent_access'
require 'hashie'

module EventBus
  class ConfigHandler < OpenStruct

  def initialize(hash = nil)
    @table = {}.with_indifferent_access
    @hash_table = {}.with_indifferent_access

      if hash
        _merge(hash)
      end
    end

    def _merge(hash)
      hash.each do |k, v|
        @table[k.to_sym]      = (v.is_a?(Hash) ? self.class.new(v) : v)
        @hash_table[k.to_sym] = v

        new_ostruct_member(k)
      end
    end

    protected :_merge

    def to_h
      @hash_table
    end

    alias :h :to_h

    # redefine original method
    # for support DeepOpenStruct.new.freeze
    def new_ostruct_member(name)
      name = name.to_sym
      unless singleton_class.method_defined?(name)
        define_singleton_method(name) { @table[name] }
        define_singleton_method("#{name}=") do |x|
          raise TypeError, "can't modify frozen #{self.class}", caller(10) if self.frozen?
          modifiable[name] = x
        end
      end
      name
    end

    protected :new_ostruct_member

    def method_missing(method, *args, &block)
      super if super.respond_to?(method) rescue nil #ToDo respond_to? should not raise here
      @hash_table.send(method, *args, &block) if @hash_table.respond_to?(method)
    end

  end

  MsgHash = ConfigHandler
end
