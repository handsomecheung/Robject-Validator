# -*- coding : utf-8 -*-
module ConfigValidation
  class DoValidate

    def initialize(template)
      if Common.template_cls?(template)
        @template_obj = template.new(self)
      else
        @template_obj = BaseTemplate.new(self)
        @template_obj.set_template_value(template)
      end

      @template_value = @template_obj.get_template_value_for_validation
      @validate_method = @template_obj.validate_method

      if @template_value.class == self.class.superclass
        clone_self(@template_value)
      end
    end

    def clone_self(template_obj)
      @template_value = template_obj.get_template_value
      @validate_method = template_obj.get_validate_method
      @template_obj = template_obj.get_template_obj
    end

    def get_template_value
      return @template_value
    end

    def get_validate_method
      return @validate_method
    end

    def get_template_obj
      return @template_obj
    end

    def validate(actual_value)
      status, msg = @validate_method[actual_value]
      if not status
        raise ConfigError::InvalidConfig, msg
      else
        # 调用方法自定义的验证方法
        if not custom_validate(actual_value)
          ConfigError.raise_invalid_config(:self_validate_fail, :template_value_cls => @template_obj.class)
        end
        return true, ""
      end
    end

    def do_validate(actual_value)
      begin
        status, msg = validate(actual_value)
      rescue ConfigError::InvalidConfig => ex
        status = false
        msg = ex.message
      end
      return status, msg
    end

    def custom_validate(actual_value)
      return get_template_obj.do_custom_validate(actual_value)
    end

    def get_option
      return {}
    end

  end
end
