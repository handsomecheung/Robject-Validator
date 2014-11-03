# -*- coding : utf-8 -*-
module Rov
  class Template
    @required = []
    @ordered = false

    def self.create_template(template_value)
      template_cls = Class.new(self) do
        @template = template_value
      end
      return template_cls
    end

    def self.template
      return @template
    end

    def self.template=(value)
      @template = value
    end

    def self.required
      return @required.to_a
    end

    def self.ordered?
      return @ordered
    end

    def initialize(validate_obj)
      @validate_obj = validate_obj
      @raw_template_value = self.class.template
      @required = self.class.required
    end

    def get_validate_option
      return @validate_obj.get_option()
    end

    def set_template_value(value)
      @raw_template_value = value
    end

    def get_template_value
      if @template_value
        return @template_value
      end
      value = @raw_template_value
      validate_option = get_validate_option()

      if validate_option[:stringlized]
        if value.is_a?(Hash)
          value = Common.string_hash_key(value)
          value = Common.with_symbol_access(value)
        elsif value.is_a?(Array)
          value = Common.string_array_element(value)
        elsif value.is_a?(Symbol)
          value = value.to_s
        elsif value == Symbol
          value = String
        end
      end

      @template_value = value
      return @template_value
    end

    def get_template_value_for_validation
      if @template_value_for_validation
        return @template_value_for_validation
      end
      value = get_template_value()
      case
      when value.is_a?(Hash)
        value = Hash[
                     value.map do |k, v|
                       if Common.template_cls?(k)
                         k = @validate_obj.class.new(k)
                       end
                       [k, @validate_obj.class.new(v)]
                     end
                    ]
      when value.is_a?(Array)
        value = value.map {|a| @validate_obj.class.new(a)}
      # else
      #   if value.class == @validate_obj.class.superclass
      #     # clone_self(value)
      #     value = value
      #   else
      #     # @template_value = value
      #     value = value
      #   end
      end
      @template_value_for_validation = value
      return @template_value_for_validation
    end

    def validate_method
      value = get_template_value_for_validation
      case
      when value.is_a?(Hash)
        m = method(:validate_hash)
      when value.is_a?(Array)
        m = method(:validate_array)
      else
        if value.is_a?(Class) and value.superclass == self.class.superclass
          m = value.new(@validate_obj).validate_method
        else
          m = method(:validate_other)
        end
      end

      return m
    end

    def validate_required(array)
      self.required.each do |key|
        if not @validate_obj.class.new(array).do_validate([key])[0]
          @validate_obj.set_value_hash(:required_key => key)
          @validate_obj.raise_validation_error(:not_required)
        end
      end
    end

    def validate_hash(actual_hash)
      _template_value = get_template_value_for_validation
      if actual_hash.class != _template_value.class
        @validate_obj.raise_validation_error(:type_error)
      end
      actual_hash.each_pair do |k, v|
        @validate_obj.set_value_hash(:actual_hash_key => k)
        if _template_value.keys.include?(k)
          _template_value[k].validate(v)
        else
          is_exist = false
          (_template_value.keys.find_all {|p| p.class == @validate_obj.class.superclass or p.class == @validate_obj.class}).each do |d|
            if d.do_validate(k)[0]
              _template_value[d].validate(v)
              is_exist = true
            end
          end
          if not is_exist
            @validate_obj.raise_validation_error(:invalid_key)
          end
        end
      end

      self.validate_required(actual_hash.keys)

      return [true, ""]
    end

    def validate_array(actual_array)
      _template_value = get_template_value_for_validation
      if actual_array.class != _template_value.class
        @validate_obj.raise_validation_error(:type_error)
      end

      if self.ordered?
        actual_array.zip(_template_value).each do |real_element, template_element|
          if template_element.nil?
            @validate_obj.set_value_hash(:actual_array_element => real_element)
            @validate_obj.raise_validation_error(:surplus_element)
          end
          template_element.validate(real_element)
        end
      else
        actual_array.each do |re|
          if _template_value.map {|te| te.do_validate(re)[0]}.none?
            @validate_obj.raise_validation_error(:invalid_element)
          end
        end
        self.validate_required(actual_array)
      end

      return [true, ""]
    end

    def validate_other(actual_value)
      _template_value = get_template_value_for_validation
      if not _template_value == actual_value
        @validate_obj.raise_validation_error(:not_eq)
      end
      return [true, ""]
    end

    def required
      _required = @required
      if get_validate_option[:stringlized]
        case
        when _required.is_a?(Hash)
          _required = Common.string_hash_key(_required)
        when _required.is_a?(Array)
          _required = Common.string_array_element(_required)
        when _required.is_a?(Symbol)
          _required = _required.to_s
        end
      end
      return _required
    end

    def ordered?
      return self.class.ordered?
    end

    def do_custom_validate(actual_value)
      if get_validate_option[:stringlized]
        case
        when actual_value.is_a?(Hash)
          actual_value = Common.with_symbol_access(actual_value)
        when actual_value.is_a?(Array)
          actual_value = Common.string_array_element(actual_value)
        when actual_value.is_a?(Symbol)
          actual_value = actual_value.to_s
        end
      end

      return self.validate(actual_value)
    end

    def validate(actual_value)
      return true
    end

    def raise_validation_error(error_type)
      return @validate_obj.raise_validation_error(error_type)
    end

    # ---------------------------------------------------
    def self.any_of(lst)
      any_of_cls = Class.new(Rov::Template) do
        @template = AnyOfArray.new(lst)
        def validate_method
          m = lambda do |actual_value|
            is_exist = false
            self.get_template_value_for_validation.each do |_template_value|
              if _template_value.do_validate(actual_value)[0]
                is_exist = true
                break
              end
            end
            if not is_exist
              @validate_obj.raise_validation_error(:not_include)
            end
            [true, ""]
          end
          return m
        end
      end
      return any_of_cls
    end

    def self.instance_of(cls)
      instance_of_cls = Class.new(Rov::Template) do
        @template = cls

        def validate_method
          m = lambda do |actual_value|
            if not actual_value.instance_of?(self.get_template_value)
              @validate_obj.raise_validation_error(:type_error)
            end
            [true, ""]
          end
          return m
        end
      end
      return instance_of_cls
    end

    def self.kind_of(cls)
      kind_of_cls = Class.new(Rov::Template) do
        @template = cls

        def validate_method
          m = lambda do |actual_value|
            if not actual_value.is_a?(self.get_template_value)
              @validate_obj.raise_validation_error(:type_error)
            end
            [true, ""]
          end
          return m
        end
      end
      return kind_of_cls
    end

    def self.in_range(_range)
      in_range_cls = Class.new(Rov::Template) do
        @template = _range

        def validate_method
          m = lambda do |actual_value|
            if not self.get_template_value.include?(actual_value)
              @validate_obj.raise_validation_error(:not_in_range)
            end
            [true, ""]
          end
          return m
        end
      end
      return in_range_cls
    end

    def self.anything
      return kind_of(Object)
    end

    # ---------------------------------------------------
  end
end

class AnyOfArray < Array
end
