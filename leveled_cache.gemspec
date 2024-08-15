# frozen_string_literal: true

require_relative "lib/leveled_cache/version"

Gem::Specification.new do |spec|
  spec.name = "leveled_cache"
  spec.version = LeveledCache::VERSION
  spec.authors = ["Dave Pirotte"]
  spec.email = ["dpirotte@gmail.com"]

  spec.summary = "ActiveSupport::Cache that wraps multiple levels of caches"
  spec.homepage = "https://github.com/dpirotte/leveled_cache"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 6.1", "< 8.0"
end
