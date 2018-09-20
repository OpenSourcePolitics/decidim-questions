
## Enhancements in `decidim` core modules

> --> see https://github.com/OpenSourcePolitics/decidim/tree/0.12-questions

### Add a new config accessor in **decidim-core** :
`participatory_process_user_roles`
with default roles `admin`,`collaborator`,`moderator`

New Roles can be append in config initializer like :
`config/initializers/decidim.rb`

```ruby
Decidim.configure do |config|
  config.participatory_process_user_roles += %w(service committee)
end
```

### `ParticipatoryProcess` permissions enhancement :
- extends the permissions chain for PP
- add a permission layer for new roles
- extends the `ParticipatoryProcess` model with helper methods

### Module administration
- Edit answer form with new states and recipient
- Add 3 tabs on main list to manage workflow
- :construction: Prepare AnswerQuestion commands calls for workflow
