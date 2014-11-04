Robject-Validator
=================

## Description
Robject-Validator(Rov) is a object validator for Ruby. Usually there are many
different data objetcts in your system, and you have to ensure the
accuracy of the data objects. It's terrible to write validation code for
each object. It will confuse your system and has high risk for bug.

Rov provides a general mechanism to validate all data objects. All you need is
defining template for each object, and then Rov will validate them.


## Requires
Rov has no dependencies, unless your objects need other gem packages.

However, your Ruby version can not be less than 1.8.7.

## Install
From rubygems.org:

    $ gem install rov

Or install Rov from the git repo:

    $ gem build rov.gemspec
    $ gem install rov-{version}.gem

## Basic Usage
First all, you need to define a template for object. The template is a class
inherited from `Rov::Template`, and your object is defined in the instance variable
`@template` of the template class.

For example, a hash object that contains several properties, name, sex, age and email:

```ruby
  class Person < Rov::Template
    @template = {
      :name => kind_of(String),
      :age => kind_of(Fixnum),
      :sex => any_of([:male, :female]),
      :email => kind_of(String),
    }
  end
```

`kind_of` and `any_of` are class methods of Rov::Template.

`kind_of()` takes one argument which is a class. It means the data must be a object
of String(or its child class).

`any_of()` aslo takes one argument which is an array. It means the data must be a
element of the array. The element of the array can be any type, symbol, string,
class, or event a template class(yes, templates can be nested with each other).

After defined, Rov could validate the specific data. Suppose the specific data
`data`:

```ruby
  data = {
    :name => "Scarlet",
    :age => 30,
    :sex => :female,
    :email => "scarlet@email.com",
  }
  validator = Rov::Validate.new(Person)
  status, error_msg = validator.do_validate(data)
  end
```

`do_validate` method return two value: the first is the result if validated or not, and
the second one is error massage if validation fails.

## Advanced Usage

### Required Keys
If your hash object must contain several specified keys, you can use instance variable
`@required`. `@required` must be given an array, element in which must present in
specific data, or validation will fail. By default, `@required` is an empty array. that
is, the specific data can an empty hash.

For Example:

```ruby
  class Person < Rov::Template
    @template = {
      :name => kind_of(String),
      :age => kind_of(Fixnum),
      :sex => any_of([:male, :female]),
      :email => kind_of(String),
    }
    @required = [:name, :age]
  end
```

As definition, the specific `Person` data must contain `:name` and `:age`.


### Ordered Array
If the template is given an array, then the specific data must be included in the array.
By default, there is no restriction on the order of the elements. But you can want to
do it, there is a instance variable `@ordered`. If `@ordered` will be set `true`, Rov
will validate the specific array with the order which defined in template.


### List of Template Methods
There are five available template methods:

+ `any_of()`

As you known, `any_of()` means the specific data should be included in the given
array. `any_of()` can be used anywhere, such as hash's key:

```ruby
  class People < Rov::Template
    @template = {
      any_of(names) => Person,
    }
  end
```

Suppose the argument of `any_of()` `names` is an array which contains many names.

Besides, this example shows how to nested template in other template.

+ `kind_of()`

+ `instance_of()`

The difference with `kind_of()` is that `instance_of()` can not be an instance of
the class's child class.

+ `in_range()`

This method takes an object of `Range`, and the specific data should be included
in it.

+ `anything()`

This function does not accept any arguments. Any specific data will be validated
if the template data is defined with `anything()`.


### Custom Template Method
You can define new template method. Template method should return a class inherited
from Rov::Template, like defining template class. In the class, two things must be
presented, `@template` and `validate_method()`.

`@template` is same as `@template` in the template class. And `validate_method()`
returns a method by which Rov validates the specific data.

For example, it defines a method `email()` to validate specific data must be a
email address.

```ruby
  def email()
    email_cls = Class.new(Rov::Template) do
      # @template =
      def validate_method
        m = lambda do |actual_value|
          if actual_value.is_a?(String) and
              (actual_value =~ /^[a-zA-Z0-9_.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-.]+$/) == 0
            [true, ""]
          else
            raise_validation_error(:invalid_email)
          end
        end
        return m
      end
    end
    return email_cls
  end
```

Because the format of email address is unchanged, the template should be a constant(
the regex), so there is only `validate_method()` in `email()`. The method that returned
by `validate_method()` return two value(status and an empty string) if validation succeed.
If validation fails, just call `raise_validation_error()` with a symbol.


### Custom Validation Method
Sometimes, you may have some special requirements. Rov provides you a way to define
your custom validation method.

```ruby
  class Person < Rov::Template
    @template = {
      # ...
      :email => kind_of(String),
      :address => kind_of(String),
      :zip_code => kind_of(Fixnum),
    }

    def validate(actual_value)
      r = [actual_value[:address], actual_value[:zip_code]]
      return ((not r.any?) or r.all?)
    end
  end
```

You can define `Rov::Template#validate` method to implement your custom method.

`Rov::Template#validate()` takes one argument `actual_value` which is specific
data. The example above means the keys `:address` and `:zip_code` are either both
presented, or both not.


### Simple Way Defining Template
Rov provides a simple way to define a templete, if the template is not complicated.
With `Rov::Template.create_template()`, you don't need to define a class for each
template.

```ruby
  person_cls = Rov::Template.create_template({:name => kind_of(String), :age => kind_of(Fixnum)})
  validator = Rov::Validate.new(person_cls)
  validator.do_validate(specific_data)
```

### Stringlized Object
When object is returned by http server, the validation will fails if the object
contains symbol object. All symbol objects are changed to string object.

Rov provides a validation argument `:json`, which will change symbol to
string in template, even the Symbol class.

```ruby
  data = {
    "name" => "Scarlet",
    "age" => 30,
    "sex" => "female",
    "email" => "scarlet@email.com",
  }
  validator = Rov::Validate.new(Person)
  status, error_msg = validator.do_validate(data, :json => true)
```

The `data` above is correct as expected.

If `kind_of(Symbol)` was defined in template, `:json` will change it to
`kind_of(String)`.

In the example Custom Validate Method we use the term `actual_value[:address]`,
`:json` will make actual_value `with_symbol_access` hash, whose string
key can be accessed by the symbol value.

So don't worry if the difference between string and symbol.


### Changing Template
After defined, temlate can still be changed. Just as follows:

```ruby
  # change valude of key :name
  Person.template[:name] = Rov::Template.anything

  # change the whole template
  Person.template = new_template
```
