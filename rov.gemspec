require 'lib/rov/version'

Gem::Specification.new do |s|
  s.name = 'rov'
  s.license = 'GPLv3'
  s.summary = "Robject Validator"
  s.description = "Ruby Object validator"
  s.version = Rov::VERSION
  s.authors = ['Handsome Cheung']
  s.email = ['handsomecheung@gmail.com']
  s.homepage = %q{https://github.com/handsomecheung/Robject-Validator}
  s.files = Dir.glob("lib/**/*") + ["README.md"]
  s.require_path = 'lib'
end
