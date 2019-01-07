# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

gem "decidim", git: "https://github.com/OpenSourcePolitics/decidim.git", branch: "0.12-questions"
gem "decidim-questions", path: "."

gem "puma", "~> 3.0"
gem "uglifier", "~> 4.1"

gem "rubyzip", "~> 1.2.2"

gem "loofah", ">= 2.2.3"
gem "loofah", ">= 2.2.3"

group :development, :test do
  gem "byebug", "~> 10.0", platform: :mri

  gem "decidim-dev", git: "https://github.com/OpenSourcePolitics/decidim.git", branch: "0.12-questions"
end

group :development do
  gem "faker", "~> 1.8"
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 3.5"
end
