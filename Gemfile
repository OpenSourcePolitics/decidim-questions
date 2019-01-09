# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

gem "decidim", git: "https://github.com/decidim/decidim", branch: "0.16-stable"
gem "decidim-questions", path: "."

gem "bootsnap", "~> 1.3"

gem "doc2text", git: "https://github.com/bostko/doc2text.git", branch: "0.4-stable"

gem "puma", "~> 3.0"
gem "uglifier", "~> 4.1"

gem "faker", "~> 1.9"

group :development, :test do
  gem "byebug", "~> 10.0", platform: :mri

  gem "decidim-dev", git: "https://github.com/decidim/decidim", branch: "0.16-stable"
end

group :development do
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 3.5"
end
