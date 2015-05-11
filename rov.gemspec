require './lib/rov/version'

Gem::Specification.new do |s|
  s.name = 'rov'
  s.license = 'GPL-3.0'
  s.summary = "rov(Robject Validator) is a object validator for Ruby"
  s.description = "rov provides a general mechanism to validate all objects. All you need is defining template for each object, and then rov will validate them."
  s.version = Rov::VERSION
  s.authors = ['Handsome Cheung']
  s.email = ['handsomecheung@gmail.com']
  s.homepage = %q{https://github.com/handsomecheung/Robject-Validator}
  s.files = Dir.glob("lib/**/*") + ["README.md"]
  s.require_path = 'lib'
  s.required_ruby_version = '>= 1.8.7'
end
