require 'lib/rov/version'

Gem::Specification.new do |s|
  s.name = 'rov'
  s.license = 'GPL-3.0'
  s.summary = "Robject Validator"
  s.description = "Ruby Object validator"
  s.version = Rov::VERSION
  s.authors = ['Handsome Cheung']
  s.email = ['handsomecheung@gmail.com']
  s.homepage = %q{https://github.com/handsomecheung/Robject-Validator}
  s.files = Dir.glob("lib/**/*") + ["README.md"]
  s.require_path = 'lib'
  s.required_ruby_version = '>= 1.8.7'
end
