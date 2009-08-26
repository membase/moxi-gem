require 'rubygems'
require 'rake/rdoctask'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.homepage = "http://www.northscale.com/"
  s.summary = "Moxi installer"
  s.name = "moxi-install"
  s.version = "0.9.6"
  s.author = "NorthScale - http://www.northscale.com/"
  s.email = "info@northscale.com"
  s.require_paths = ["lib"]
  s.files = FileList[
                     'Rakefile',
                     'lib/**/*.rb',
                     'bin/*',
                    ]
  s.executables = ['moxi-install']
  s.has_rdoc = false
  s.description = "moxi-install is a Moxi installer."
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar_gz = true
end
