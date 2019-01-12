# Decidim::Questions

> Questions module derived from decidim-proposals.

The Questions module adds one of the main components of Decidim: allows users to contribute to a participatory process by creating questions.

## Usage

Questions will be available as a Component for a Participatory Process.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'decidim-questions'
```

And then execute:

```bash
bundle
```

### Configuring Similarity

`pg_trgm` is a PostgreSQL extension providing simple fuzzy string matching used in the Question wizard to find similar published questions (title and the body).

Create config variables in your app's `/config/initializers/decidim-questions.rb`:

```ruby
Decidim::Questions.configure do |config|
  config.similarity_threshold = 0.25 # default value
  config.similarity_limit = 10 # default value
end
```

`similarity_threshold`(real): Sets the current similarity threshold that is used by the % operator. The threshold must be between 0 and 1 (default is 0.3).

`similarity_limit`: number of maximum results.

## Global Search

This module includes the following models to Decidim's Global Search:

- `Questions`

## Participatory Texts

Participatory texts persist each section of the document in a Question.

When importing participatory texts all formats are first transformed into Markdown and is the markdown that is parsed and processed to generate the corresponding Questions.

When processing participatory text documents three kinds of sections are taken into account.

- Section: each "Title 1" in the document becomes a section.
- Subsection: the rest of the titles become subsections.
- Article: paragraphs become articles.

## DevOps

### Create a development_app

In order to start developing you will need what is called a `development_app`. This is nearly the same as a new Decidim app (that you can create with `decidim app_name`) but with a Gemfile pre-configured for local development and some other small config modifications.
You need it in order to have a Rails application configured to lookup Decidim modules from your filesystem. This way changes in your modules will be directly observed by this `development_app`.

You can create a `development_app` from inside the project's root folder with the command:

```console
git clone https://github.com/decidim/decidim.git
cd decidim
bundle install
bundle exec rails development_app
cd development_app
```

A development_app/ entry appears in the .gitignore file, so you don't have to worry about commiting the development app by mistake.

On creation, this steps are automatically invoked by the generator:

- create a `config/database.yml`
- `bundle install`
- `bin/rails decidim:upgrade`
- `bin/rails db:migrate db:seed`

If the default database.yml does not suit your needs you can always configure it at your will and run this steps manually.

Once created you are ready to:

- `bin/rails s`

### I18n

We use i18n-tasks gem to keep translations ordered and without missing/unused keys.

```console
# from the root of the project
bundle exec i18n-tasks normalize --locales en
```

### Tests

You need to create a dummy application to run your tests. Run the following command in the decidim root's folder:

```bash
bundle exec rails test_app
```

And then launch the tests
```bash
bundle exec rails spec
```


## Contributing

See [Decidim](https://github.com/decidim/decidim).

## License

See [Decidim](https://github.com/decidim/decidim).
