# -*- coding : utf-8 -*-
module Rov
  class DoValidate

    include ConfigError

    def initialize(template)
      if Common.template_cls?(template)
        @template_obj = template.new(self)
      else
        @template_obj = Template.new(self)
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
      set_value_hash({
                       :actual_value => actual_value,
                       :template_value => @template_obj.get_template_value,
                       :template_value_cls => @template_obj.class,
                     })
      status, msg = @validate_method[actual_value]
      if not status
        raise ConfigError::InvalidConfig, msg
      else
        if not custom_validate(actual_value)
          raise_invalid_config(:self_validate_fail)
        end
        return true, ""
      end
    end

    def do_validate(actual_value)
      begin
        status, msg = validate(actual_value)
      rescue ConfigError::InvalidConfig => ex
        status = false

        # it can `raise` a array when ruby version less 1.9.3. # or the array will be inspected.
        # so, pass the message to eval() when it is a string.
        if ex.message.is_a?(String)
          msg = eval(ex.message)
        else
          msg = ex.message
        end
      end
      return status, msg
    end

    def custom_validate(actual_value)
      return get_template_obj.do_custom_validate(actual_value)
    end

    def get_option
      return {}
    end

    def set_value_hash(hash={})
      @value_hash ||= {}
      @value_hash.merge!(hash)
    end

  end
end
