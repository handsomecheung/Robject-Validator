# -*- coding : utf-8 -*-
module Rov
  module RaiseError
    class InvalidConfig < StandardError
    end

    def raise_validation_error(error_type)
      raise InvalidConfig, [error_type, get_error_str(error_type)]
    end

    def get_error_str(error_type)
      template_value = @value_hash[:template_value]
      actual_value = @value_hash[:actual_value]

      types = {
        :not_include => "#{actual_value.inspect} not in `#{template_value.inspect}`",
        :type_error => "type of `#{actual_value.inspect}`(#{actual_value.class}) should be #{template_value.class}",
        :invalid_key => "invalid key `#{@value_hash[:actual_hash_key].inspect}` in `#{actual_value.inspect}`",
        :surplus_element => "surplus element `#{@value_hash[:actual_array_element].inspect}` in `#{actual_value.inspect}`",
        :invalid_element => "invalid element in `#{actual_value.inspect}`",
        :not_in_range => "`#{actual_value.inspect}` not in range of `#{template_value}`",
        :not_eq => "`#{actual_value.inspect}` not equal to `#{template_value}`",
        :not_required => "no required key: `#{@value_hash[:required_key].inspect}` in `#{actual_value.inspect}`",
        :self_validate_fail => "`#{@value_hash[:template_value_cls].inspect}` custom validate method failed",
      }
      return types[error_type] || "#{error_type}: #{actual_value.inspect}"
    end

  end
end
