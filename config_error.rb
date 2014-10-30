# -*- coding : utf-8 -*-
module ConfigValidation
  module ConfigError
    class InvalidConfig < Exception
    end

    def self.raise_invalid_config(invalid_type, value_hash)
      raise InvalidConfig, [invalid_type, get_error_str(invalid_type, value_hash)]
    end

    def self.get_error_str(invalid_type, value_hash)
      template_value = value_hash[:template_value]
      actual_value = value_hash[:actual_value]
      types = {
        :not_include => "#{actual_value.inspect} not in `#{template_value.inspect}`",
        :type_error => "type of `#{actual_value.inspect}`(#{actual_value.class}) should be `#{template_value}`",
        :invalid_key => "invalid key `#{value_hash[:actual_value_key].inspect}` in `#{actual_value.inspect}`",
        :surplus_element => "surplus element `#{value_hash[:actual_value_element].inspect}` in `#{actual_value.inspect}`",
        :invalid_element => "invalid element in `#{actual_value.inspect}`",
        :not_in_range => "`#{actual_value.inspect}` not in range of `#{template_value}`",
        :not_eq => "`#{actual_value.inspect}` not equal to `#{template_value}`",
        :not_required => "no required key: `#{value_hash[:required_key].inspect}`",
        :self_validate_fail => "`#{value_hash[:template_value_cls].inspect}` custom validate method failed",
      }
      return types[invalid_type] || raise("invalid type error: #{invalid_type}")
    end

  end
end
