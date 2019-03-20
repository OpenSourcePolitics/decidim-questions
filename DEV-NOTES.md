# Decidim::Questions

## Cloning `Decidim::Proposals`
Here's the procedure followed for 0.16 iteration.

> _this procedure can be improved for sure. Operations are split and isolated in commits.  Not sure if `git merge` algorithms prefer clean operation series (movement/rename then text remplacement) or aggregated ones (movement/rename/replace in the same commit)._

> **For each steps, assume that you are replacing "Proposal" with "Question" ;) !**

### Step 1 : checking out version

```shell
git clone https://github.com/decidim/decidim -b 0.16-stable decidim-questions
cd decidim-questions
```

### Step 2 : Cleaning directories
- remove all directory **except** decidim-proposals
- remove all files at the root **except** .gitignore

--> see commit [5c80700](https://github.com/OpenSourcePolitics/decidim-questions/commit/5c807001953b7609fbae6cce2caa69177af4d003)

### Step 3 : Renaming files & directories

#### 3.1 : Renaming main module directory
```shell
git mv decidim-proposals decidim-questions
```
--> see commit [295cfce](https://github.com/OpenSourcePolitics/decidim-questions/commit/295cfce56768df379b2abc342c5e638df2a625d6)

#### 3.2 : Creating new directories
```shell
git ls-tree -dr HEAD --name-only | grep proposal
```
--> Use the list to generate commands like  
`mkdir -p <new-directory>`

#### 3.3 : moving files
```shell
git ls-files | grep proposal
```
--> Use the list to generate commands like  
`git mv <source> <destination>`

#### 3.4 : Deleting old directories
```shell
git ls-tree -dr HEAD --name-only | grep proposal
```
--> Use the lists to generate commands like  
`rm -rf <old-directory>`

**--> see the [gist](https://gist.github.com/moustachu/5e37796f4c82858eef890bedca5b1884) with full generated commands list**

--> see commit [ef330ab](https://github.com/OpenSourcePolitics/decidim-questions/commit/ef330ab32fc79ad0b2c2ea0b2b9ea45c63048635)

### Step 4 : Bulk replace text content
with built Search / Replace All from text editor (⚠️Case Sensitive)
- "Proposal" --> "Question"
- "proposal" --> "question"
- "PROPOSAL" --> "QUESTION"

> _if anyone has the sed / awk command for that one :wink:_

--> see commit [c47e068](https://github.com/OpenSourcePolitics/decidim-questions/commit/c47e06804a08fdea0574cf92eea3b89ce13e9a7a)  
_We did have a few misfire ..._  
--> see commit [d2cf521](https://github.com/OpenSourcePolitics/decidim-questions/commit/d2cf521287a86ea94ddde53022a8443b1e4c654b)   
--> see commit [65e1e8f](https://github.com/OpenSourcePolitics/decidim-questions/commit/65e1e8fe14ab1ba7c538c3ac59fc217459e2e057)  
--> see commit [5ce20d5](https://github.com/OpenSourcePolitics/decidim-questions/commit/5ce20d5d091074fce4deb3d819ccd48714f4da4e)  
--> see commit [0d41054](https://github.com/OpenSourcePolitics/decidim-questions/commit/0d4105419bdabd4ef81402c44bc4584efbd78882)  

### Step 5 : Moving files up the module directory
```shell
git mv decidim-questions/* ./
```

--> see commit [5e74e9b](https://github.com/OpenSourcePolitics/decidim-questions/commit/5e74e9b9dd7baf96c5d1906f326880ca55392c70)

### Step 6 : Add missing module files from template

We generated an external module from scratch to compare the Proposals module architecture with the generated one.

```shell
bundle exec decidim --component questions --external --destination_folder ../decidim-questions/
```

Important files to be tweaked for your needs are :
- [`./Gemfile`](https://github.com/OpenSourcePolitics/decidim-questions/blob/6aab9f676f75cfbab765eaa465891ecab30a6803/Gemfile)
- [`./Rakefile`](https://github.com/OpenSourcePolitics/decidim-questions/blob/6aab9f676f75cfbab765eaa465891ecab30a6803/Rakefile)
- [`./decidim-questions.gemspec`](https://github.com/OpenSourcePolitics/decidim-questions/blob/6aab9f676f75cfbab765eaa465891ecab30a6803/decidim-questions.gemspec)
- [`./lib/tasks/decidim_tasks.rake`](https://github.com/OpenSourcePolitics/decidim-questions/blob/6aab9f676f75cfbab765eaa465891ecab30a6803/lib/tasks/decidim_tasks.rake)
- [`./config/i18n-tasks.yml`](https://github.com/OpenSourcePolitics/decidim-questions/blob/6aab9f676f75cfbab765eaa465891ecab30a6803/config/i18n-tasks.yml)
- [`./.circleci/config.yml`](https://github.com/OpenSourcePolitics/decidim-questions/blob/6aab9f676f75cfbab765eaa465891ecab30a6803/.circleci/config.yml)


--> see commit [ff90b17](https://github.com/OpenSourcePolitics/decidim-questions/commit/ff90b178be1c4628480013c07fc87bfc0e5cebc6)  
--> see commit [fcb68c4](https://github.com/OpenSourcePolitics/decidim-questions/commit/fcb68c4d1645e3d41597afd47253186746b977a9)  
--> see commit [9756e00](https://github.com/OpenSourcePolitics/decidim-questions/commit/9756e00bf0eb477638fb4055cce41ae04df1bdaf)  
--> see commit [6700707](https://github.com/OpenSourcePolitics/decidim-questions/commit/6700707b5e2f1d9fcc116555c7e922c4c20eab69)  
--> see commit [22ad6b9](https://github.com/OpenSourcePolitics/decidim-questions/commit/22ad6b9fd767794c0ca08b1b8e1d15672a14d661)  

### Step 7 : Squash migrations
> This step could have been done right after Step 1 to be part of the file renaming processes. Principles remains the same.

#### 7.1 : Generate a dummy test app
```shell
bundle exec rails test_app
```

> ⚠️ At this point, the app generation should crash around the seed part. But we only need to extract the DB schema for now.

#### 7.2 : Get the full schema for Proposals tables
- Locate the Proposals related tables in the generated `./spec/decidim_dummy_app/db/schema.rb` They should be in a single pack of code.  
- Copy the code

#### 7.3 : Create the squashed migration
```shell
rm ./db/migrate/*
bundle exec rails generate migration CreateDecidimQuestions
```

*--> Paste the copied code from 7.2*

--> see [generated migration](https://github.com/OpenSourcePolitics/decidim-questions/blob/106f56d5defe2d9f5d1a6bdd85d25b2ef9015c5e/db/migrate/20190108160127_create_decidim_questions.rb)
--> see whole commit [106f56d](https://github.com/OpenSourcePolitics/decidim-questions/commit/106f56d5defe2d9f5d1a6bdd85d25b2ef9015c5e)

### Step 8 : Bundle & Tests
Recreate the test app and it to fix the last qwirks.
```shell
bundle exec rails test_app
bundle exec rails spec
```

At this point we did fix :
- Force class scope on `ParticipatoryTextsController`  
--> see commit [65dd28e](https://github.com/OpenSourcePolitics/decidim-questions/commit/65dd28e8dddeec75265dee2f585af0ff9fe1279f)  
- Add some helpers method
--> see commit [3f6b7be](https://github.com/OpenSourcePolitics/decidim-questions/commit/3f6b7bef6319e9652b3ac1db87188abcb39c998f)  
--> see commit [1d6dd1b](https://github.com/OpenSourcePolitics/decidim-questions/commit/1d6dd1b94533910d9896cc418bc9b01d1ec3c116)
- Extends for `Amendable` commands to be able to manage other types than `Proposals`
--> see commit [fea5cf6](https://github.com/OpenSourcePolitics/decidim-questions/commit/fea5cf632be587ef85c91e8f485f183b871044fb)
- Extends for `CellsHelper` for `Questions`
--> see commit [d1b3d14](https://github.com/OpenSourcePolitics/decidim-questions/commit/d1b3d14b8b6064904836c621f05d59d9cafa1f3a)
- Extends for `AuthorCell` for `Questions`
--> see commit [e0fb9c2](https://github.com/OpenSourcePolitics/decidim-questions/commit/e0fb9c2c1c10f9afa6ffc6fc56160c88fbfab164)


### Step 9 : Publish

Push your fresh module to your favorite repository :rocket:

```shell
git remote add questions https://github.com/OpenSourcePolitics/decidim-questions
git push --set-upstream questions 0.16-stable
```
