# -*- coding : utf-8 -*-

require File.expand_path("../base_template", __FILE__)
require File.expand_path("../lib/hash_with_symbol_access", __FILE__)

module ConfigValidation
  module Common
    def self.template_cls?(template)
      return (template.class == Class and template.superclass == BaseTemplate)
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

  end
end
