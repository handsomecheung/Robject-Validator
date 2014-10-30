# -*- coding : utf-8 -*-
module ConfigValidation
  class BaseTemplate
    @required = []
    @check_order = false

    def self.get_raw_template_value_from_cls
      return @template
    end

    def self.required
      return @required.to_a
    end

    def self.check_order
      return @check_order
    end

    def initialize(validate_obj)
      @validate_obj = validate_obj
      @raw_template_value = self.class.get_raw_template_value_from_cls
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

      # 检查是否以 json 参数来验证，是的话，转换 hash 的所有 key 和 symbol 为字符串
      if validate_option[:json]
        if value.is_a?(Hash)
          value = Common.string_hash_key(value)
          value = value.with_symbol_access
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
          ConfigError.raise_invalid_config(:not_required, :required_key => key)
        end
      end
    end

    def validate_hash(actual_hash)
      _template_value = get_template_value_for_validation
      if actual_hash.class != _template_value.class
        ConfigError.raise_invalid_config(:type_error, :actual_hash => actual_hash, :template_value => _template_value)
      end
      actual_hash.each_pair do |k, v|
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
            ConfigError.raise_invalid_config(:invalid_key, :actual_value => actual_hash, :actual_value_key => k)
          end
        end
      end

      self.validate_required(actual_hash.keys)

      return [true, ""]
    end

    def validate_array(actual_array)
      _template_value = get_template_value_for_validation
      if actual_array.class != _template_value.class
        ConfigError.raise_invalid_config(:type_error, :actual_value => actual_array, :template_value => _template_value)
      end

      if self.check_order
        actual_array.zip(_template_value).each do |real_element, template_element|
          if template_element.nil?
            ConfigError.raise_invalid_config(:surplus_element, :actual_value => actual_array, :actual_value_element => real_element)
          end
          template_element.validate(real_element)
        end
      else
        actual_array.each do |re|
          if _template_value.map {|te| te.do_validate(re)[0]}.none?
            ConfigError.raise_invalid_config(:invalid_element, :actual_value => actual_array)
          end
        end
        self.validate_required(actual_array)
      end

      return [true, ""]
    end

    def validate_other(actual_value)
      _template_value = get_template_value_for_validation
      if not _template_value == actual_value
        ConfigError.raise_invalid_config(:not_eq, :actual_value => actual_value, :template_value => _template_value)
      end
      return [true, ""]
    end

    def required
      _required = @required
      if get_validate_option[:json]
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

    def check_order
      return self.class.check_order
    end

    def do_custom_validate(actual_value)
      if get_validate_option[:json]
        case
        when actual_value.is_a?(Hash)
          actual_value = actual_value.with_symbol_access
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

    # ---------------------------------------------------
    def self.any_of(lst)
      any_of_cls = Class.new(ConfigValidation::BaseTemplate) do
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
              ConfigValidation::ConfigError.raise_invalid_config(:not_include, :actual_value => actual_value, :template_value => self.get_template_value)
            end
            [true, ""]
          end
          return m
        end
      end
      return any_of_cls
    end

    def self.instance_of(cls)
      instance_of_cls = Class.new(ConfigValidation::BaseTemplate) do
        @template = cls

        def validate_method
          m = lambda do |actual_value|
            if not actual_value.instance_of?(self.get_template_value)
              ConfigValidation::ConfigError.raise_invalid_config(:type_error, :actual_value => actual_value, :template_value => self.get_template_value)
            end
            [true, ""]
          end
          return m
        end
      end
      return instance_of_cls
    end

    def self.kind_of(cls)
      kind_of_cls = Class.new(ConfigValidation::BaseTemplate) do
        @template = cls

        def validate_method
          m = lambda do |actual_value|
            if not actual_value.is_a?(self.get_template_value)
              ConfigValidation::ConfigError.raise_invalid_config(:type_error, :actual_value => actual_value, :template_value => self.get_template_value)
            end
            [true, ""]
          end
          return m
        end
      end
      return kind_of_cls
    end

    def self.in_range(_range)
      in_range_cls = Class.new(ConfigValidation::BaseTemplate) do
        @template = _range

        def validate_method
          m = lambda do |actual_value|
            if not self.get_template_value.include?(actual_value)
              ConfigValidation::ConfigError.raise_invalid_config(:not_in_range, :actual_value => actual_value, :template_value => self.get_template_value)
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
