require 'rubygems'
require 'rubygems/package_task'

spec = Gem::Specification.new do |gem|
    gem.name = "lookup_http"
    gem.version = "1.0.0"
    gem.summary = "HTTP library for data lookup tools"
    gem.email = "craig@craigdunn.org"
    gem.author = "Craig Dunn"
    gem.homepage = "http://github.com/crayfishx/lookup_http"
    gem.description = "Library for data lookup tools (eg: hiera/jerakia) for looking up data over HTTP APIs"
    gem.require_path = "lib"
    gem.files = FileList["lib/**/*"].to_a
    gem.add_dependency('json', '>=1.1.1')
end

Gem::PackageTask.new(spec) do |pkg|
    pkg.need_tar = true
    pkg.gem_spec = spec
end
