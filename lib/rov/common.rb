# -*- coding : utf-8 -*-

module Rov
  module Common
    def self.template_cls?(template)
      return (template.class == Class and template.superclass == Template)
    end

    def self.string_hash_key(hash)
      r = hash.map do |k, v|
        if k.is_a?(Symbol)
          [k.to_s, v]
        else
          [k, v]
        end
      end
      return Hash[r]
    end

    def self.string_array_element(array)
      r = array.map do |e|
        if e.is_a?(Symbol)
          e.to_s
        else
          e
        end
      end
      return r
    end

    def self.with_symbol_access(hash)
      return HashWithSymbolAccess[hash.entries]
    end

  end
end

class HashWithSymbolAccess < Hash
  def [](key)
    if self.keys.include?(key)
      return super(key)
    elsif key.is_a?(Symbol) and self.keys.include?(key.to_s)
      return super(key.to_s)
    end
  end

  def []=(key, value)
    if self.keys.include?(key)
      super(key, value)
    elsif key.is_a?(Symbol) and self.keys.include?(key.to_s)
      super(key.to_s, value)
    end
  end
end
