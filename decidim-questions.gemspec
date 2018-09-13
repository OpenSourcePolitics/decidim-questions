# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/questions/version"

Gem::Specification.new do |s|
  s.version = Decidim::Questions.version
  s.authors = ["moustachu"]
  s.email = ["git@moustachu.net"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/decidim/decidim-module-questions"
  s.required_ruby_version = ">= 2.3.1"

  s.name = "decidim-questions"
  s.summary = "A decidim questions module"
  s.description = "Questions / Opinion / Contribution based on decidim-proposals."

  s.files = Dir["{app,config,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "cells-erb", "~> 0.1.0"
  s.add_dependency "cells-rails", "~> 0.0.9"
  s.add_dependency "decidim-comments", Decidim::Questions.version
  s.add_dependency "decidim-core", Decidim::Questions.version
  s.add_dependency "kaminari", "~> 1.0"
  s.add_dependency "ransack", "~> 2.0"
  s.add_dependency "social-share-button", "~> 1.0"

  s.add_development_dependency "decidim-admin", Decidim::Questions.version
  s.add_development_dependency "decidim-assemblies", Decidim::Questions.version
  s.add_development_dependency "decidim-budgets", Decidim::Questions.version
  s.add_development_dependency "decidim-dev", Decidim::Questions.version
  s.add_development_dependency "decidim-meetings", Decidim::Questions.version
  s.add_development_dependency "decidim-participatory_processes", Decidim::Questions.version
  s.add_development_dependency "decidim-proposals", Decidim::Questions.version
end
