# -*- coding : utf-8 -*-
$KCODE = 'utf8'

require 'test/unit'

require File.expand_path('../../config_error.rb', __FILE__)
require File.expand_path('../../common.rb', __FILE__)
require File.expand_path('../../validate.rb', __FILE__)
require File.expand_path('../../base_template.rb', __FILE__)
require File.expand_path('../../do_validate.rb', __FILE__)

class Hash1 < ConfigValidation::BaseTemplate
  key_list = ["hash_key_1", "hash_key_2", "hash_key_3"]
  @template = {any_of(key_list.map{|s| s.to_sym}) => instance_of(Fixnum)}
end

class List1 < ConfigValidation::BaseTemplate
  list = [:element_1, :element_2, :element_3]
  @template = [any_of(list), :extra_element]
  @required = [:element_1]

  def validate(actual_value)
    actual_value.count > 1
  end
end

class OrderedList1 < ConfigValidation::BaseTemplate
  list = [:element_1, :element_2, :element_3]
  @template = [any_of(list), :extra_element]
  @required = [:element_1]
  @ordered = true

  def validate(actual_value)
    actual_value.count > 1
  end
end

class AnyofTemplate < ConfigValidation::BaseTemplate
  @template = any_of([List1, Hash1])
end

class AnyofInstance < ConfigValidation::BaseTemplate
  @template = any_of([kind_of(String), kind_of(Fixnum)])
end

class TopKls < ConfigValidation::BaseTemplate
  @template = {
    :in_range => in_range(20..90),
    :hash => Hash1,
    :string => 'test string',
    :list => List1,
    :start => instance_of(Fixnum),
    :end => instance_of(Fixnum),
    :number => any_of([1, 2, 3]),
    :list_container => [List1],
    :symbol => :test_symbol,
    :symbol_class => instance_of(Symbol),
  }
  @required = [:string]

  def validate(actual_value)
    actual_value[:end].to_i > actual_value[:start].to_i
  end
end

class TestBug < Test::Unit::TestCase
  def expect_validate(results, status, invalid_type=nil)
    actual_status, actual_msg = results

    p actual_msg if actual_status != status

    assert_equal(status, actual_status)
    if not status
      p actual_msg[1]
      assert_equal(invalid_type, actual_msg[0])
    end
  end

  def test_corret_object
    d = ConfigValidation::Validate.new(TopKls)
    [
     {
       :in_range => 20,
       :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
       :list => [:element_3, :element_1, :element_2],
       :string => "test string",
       :start => 2,
       :end => 11,
     },
     {
       :in_range => 20,
       :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
       :list => [:element_3, :element_1, :element_2],
       :string => "test string",
       :number => 3,
       :start => 2,
       :end => 11,
     },
     {
       :string => "test string",
       :start => 2,
       :end => 11,
     },
     {
       :string => "test string",
       :start => 2,
       :end => 11,
       :symbol_class => :abcd,
     },
     {
       :string => "test string",
       :start => 2,
       :end => 11,
       :symbol => :test_symbol,
     },
    ].each do |test_obj|
      expect_validate(d.do_validate(test_obj), true)
    end
  end

  def test_corret_object_json
    d = ConfigValidation::Validate.new(TopKls)
    [
     {
       "symbol_class" => "abcd",
       "string" => "test string",
       "start" => 2,
       "end" => 11,
     },
    ].each do |test_obj|
      expect_validate(d.do_validate(test_obj, :json => true), true)
    end
  end

  def test_self_validate_fail_on_base_node
    d = ConfigValidation::Validate.new(TopKls)
    [
     {
       :in_range => 20,
       :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
       :list => [:element_3, :element_1, :element_2],
       :string => "test string",
       :start => 11,
       :end => 11,
     },
     {
       :in_range => 20,
       :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
       :list => [:element_3, :element_1, :element_2],
       :string => "test string",
       :start => 11,
       :end => 1,
     },
    ].each do |test_obj|
      expect_validate(d.do_validate(test_obj), false, :self_validate_fail)
    end
  end

  def test_self_validate_fail_on_child_node
    d = ConfigValidation::Validate.new(TopKls)
    test_obj = {
      :in_range => 20,
      :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
      :list => [:element_1],
      :string => "test string",
      :start => 2,
      :end => 11,
    }
    expect_validate(d.do_validate(test_obj), false, :self_validate_fail)
  end

  def test_not_include_1
    d = ConfigValidation::Validate.new(TopKls)
    test_obj = {
      :in_range => 20,
      :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
      :list => [:element_3, :element_1, :element_2],
      :string => "test string",
      :start => 2,
      :end => 11,
      :number => 4,
    }

    expect_validate(d.do_validate(test_obj), false, :not_include)
  end

  def test_type_error_1
    d = ConfigValidation::Validate.new(TopKls)
    test_obj = {
      :in_range => 20,
      :hash => {:hash_key_1 => "3", :hash_key_2 => 23},
      :list => [:element_3, :element_1, :element_2],
      :string => "test string",
      :start => 2,
      :end => 11,
    }

    expect_validate(d.do_validate(test_obj), false, :type_error)
  end

  def test_type_error_2
    d = ConfigValidation::Validate.new(TopKls)
    test_obj = {
      :in_range => 20,
      :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
      :list => [:element_3, :element_1, :element_2],
      :string => "test string",
      :start => 2,
      :end => "76",
    }
    expect_validate(d.do_validate(test_obj), false, :type_error)
  end

  def test_invalid_key_1
    d = ConfigValidation::Validate.new(TopKls)
    test_obj = {
      :in_range => 20,
      :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
      :list => [:element_3, :element_1, :element_2],
      :string => "test string",
      :numbers => 3,
      :start => 2,
      :end => 11,
    }
    expect_validate(d.do_validate(test_obj), false, :invalid_key)
  end

  def test_invalid_key_2
    d = ConfigValidation::Validate.new(TopKls)
    test_obj = {
      :in_range => 20,
      :hash => {:hash_key_1s => 3, :hash_key_2 => 23},
      :list => [:element_3, :element_1, :element_2],
      :string => "test string",
      :number => 3,
      :start => 2,
      :end => 11,
    }
    expect_validate(d.do_validate(test_obj), false, :invalid_key)
  end

  def test_invalid_element_1
    d = ConfigValidation::Validate.new(TopKls)
    test_obj = {
      :in_range => 20,
      :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
      :list => [:element_3, :element_1, :element_2, :element_4],
      :string => "test string",
      :number => 3,
      :start => 2,
      :end => 11,
    }
    expect_validate(d.do_validate(test_obj), false, :invalid_element)
  end

  def test_not_in_range_1
    d = ConfigValidation::Validate.new(TopKls)
    [
     {
       :in_range => 19,
       :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
       :list => [:element_3, :element_1, :element_2],
       :string => "test string",
       :number => 3,
       :start => 2,
       :end => 11,
     },
     {
       :in_range => 100,
       :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
       :list => [:element_3, :element_1, :element_2],
       :string => "test string",
       :number => 3,
       :start => 2,
       :end => 11,
     },
    ].each do |test_obj|
      expect_validate(d.do_validate(test_obj), false, :not_in_range)
    end
  end

  def test_not_eq_1
    d = ConfigValidation::Validate.new(TopKls)
    test_obj = {
      :in_range => 20,
      :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
      :list => [:element_3, :element_1, :element_2],
      :string => "test strings",
      :number => 3,
      :start => 2,
      :end => 11,
    }
    expect_validate(d.do_validate(test_obj), false, :not_eq)
  end

  def test_not_required_1
    d = ConfigValidation::Validate.new(TopKls)
    test_obj = {
      :in_range => 20,
      :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
      :list => [:element_3, :element_1, :element_2],
      :number => 3,
      :start => 2,
      :end => 11,
    }
    expect_validate(d.do_validate(test_obj), false, :not_required)
  end

  def test_surplus_element_1
    d = ConfigValidation::Validate.new(OrderedList1)

    list = [:element_3, :extra_element, :element_2]
    expect_validate(d.do_validate(list), false, :surplus_element)
  end

  def test_nest_object_correct
    d = ConfigValidation::Validate.new(TopKls)
    test_obj = {
      :in_range => 20,
      :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
      :list => [:element_1, :extra_element],
      :string => "test string",
      :number => 3,
      :start => 2,
      :end => 11,
      :list_container => [
                           [:element_1, :extra_element],
                           [:element_1, :element_2],
                           [:element_1, :element_3],
                          ]
    }
    expect_validate(d.do_validate(test_obj), true)
  end

  def test_nest_object_2
    d = ConfigValidation::Validate.new(TopKls)
    test_obj = {
      :in_range => 20,
      :hash => {:hash_key_1 => 3, :hash_key_2 => 23},
      :list => [:element_1, :extra_element],
      :string => "test string",
      :number => 3,
      :start => 2,
      :end => 11,
      :list_container => [
                           [:element_1, :extra_element],
                           [:element_3, :element_2],
                           [:element_1, :element_3],
                          ]
    }
    expect_validate(d.do_validate(test_obj), false, :invalid_element)
  end

  def test_any_of_instance_1
    validator = ConfigValidation::Validate.new(AnyofInstance)
    [1, 3, 5, 123, "abcd", " df ", "\n"].each do |test_obj|
      expect_validate(validator.do_validate(test_obj), true)
    end
  end

  def test_any_of_instance_2
    validator = ConfigValidation::Validate.new(AnyofInstance)
    [1.0, 3.4, 10..99, :abcd].each do |test_obj|
      expect_validate(validator.do_validate(test_obj), false, :not_include)
    end
  end

  def test_any_of_template_1
    validator = ConfigValidation::Validate.new(AnyofTemplate)
    [
     [:element_3, :element_1, :element_2],
     [:element_1, :extra_element],
     {:hash_key_1 => 3, :hash_key_2 => 23},
     {:hash_key_1 => 1, :hash_key_2 => 2, :hash_key_3 => 3},
    ].each do |test_obj|
      expect_validate(validator.do_validate(test_obj), true)
    end
  end

  def test_changing_template_value
    change_string = "test changing string"
    old_string = TopKls.template[:string]
    old_range = (20..90)
    TopKls.template[:string] = change_string
    TopKls.template[:in_range] = ConfigValidation::BaseTemplate.in_range(200..300)
    validator = ConfigValidation::Validate.new(TopKls)

    test_obj = {
      :string => old_string,
      :start => 2,
      :end => 11,
    }
    expect_validate(validator.do_validate(test_obj), false, :not_eq)

    test_obj = {
      :string => change_string,
      :start => 2,
      :end => 11,
    }
    expect_validate(validator.do_validate(test_obj), true)

    test_obj = {
      :in_range => old_range.to_a.choice,
      :string => change_string,
      :start => 2,
      :end => 11,
    }
    expect_validate(validator.do_validate(test_obj), false, :not_in_range)

    test_obj = {
      :in_range => 230,
      :string => change_string,
      :start => 2,
      :end => 11,
    }
    expect_validate(validator.do_validate(test_obj), true)

    TopKls.template[:string] = old_string
    TopKls.template[:in_range] = ConfigValidation::BaseTemplate.in_range(old_range)
  end

  def test_changing_template
    AnyofInstance.template = ConfigValidation::BaseTemplate.any_of([1.0, 1.1])
    validator = ConfigValidation::Validate.new(AnyofInstance.template)

    expect_validate(validator.do_validate(1.0), true)
    expect_validate(validator.do_validate(1.1), true)

    expect_validate(validator.do_validate(1.2), false, :not_include)
    expect_validate(validator.do_validate("1"), false, :not_include)

    AnyofInstance.template = ConfigValidation::BaseTemplate.any_of([
                                                                    ConfigValidation::BaseTemplate.kind_of(String),
                                                                    ConfigValidation::BaseTemplate.kind_of(Fixnum),
                                                                   ])
  end

end
