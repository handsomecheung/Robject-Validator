# -*- encoding : utf-8 -*-
module ConfigValidation
  class Validate
    def self.validate(template, actual_value, option={})
      v = self.new(template)
      return v.do_validate(actual_value, option)
    end

    def initialize(template)
      @template = template
    end

    def do_validate(actual_value, option={})
      validate_cls = Class.new(DoValidate) do
        @option = option

        def self.get_option
          return @option
        end

        def get_option
          return self.class.get_option
        end
      end

      validate_obj = validate_cls.new(@template)
      validate_obj.do_validate(actual_value)
    end
  end
end
