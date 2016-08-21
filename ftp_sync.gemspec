$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require "ftp_sync/version"

Gem::Specification.new do |spec|
  spec.name = "ftp_sync"
  spec.version = FTPSync::VERSION
  spec.authors = ["Will Fleming"]
  spec.email = ["will@flemi.ng"]

  spec.summary = "Sync local folder over FTP"
  spec.description = "Sync local folder over FTP"
  spec.homepage = "https://github.com/wfleming/ftp_sync"

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.5.0"
end
