# Overcade Website

Built with Jekyll, Tailwind CSS and Hyper UI.

## Setup

1. [Install Ruby and Jekyll](https://jekyllrb.com/docs/installation/windows/)

2. [Install ImageMagick-6.9.13-21-Q16-HDRI-x64-dll.exe](https://imagemagick.org/archive/binaries/ImageMagick-6.9.13-21-Q16-HDRI-x64-dll.exe) (
   the version that
   `jekyll-responsive-image`
   needs) to a path **without spaces** and check:
    - `Install development headers and libraries for C and C++`:
    - `Install legacy utilities (e.g. identify)`
    - `Add application directory to your system path`

2. Install rmagick gem (replace the path)

```shell
gem install rmagick -- --with-opt-dir=S:\ProgramFiles\ImageMagick-6.9.13-Q16-HDRI
```

2. Install Jekyll gems

```shell
bundle install
```

3. Install node modules:

```shell
npm install
```

4. Run the development server:

```shell
bundle exec jekyll serve --livereload
```

## How to deploy

Run a production build:

```shell   
$env:JEKYLL_ENV = 'production'; bundle exec jekyll build
```

Copy the contents of `_site` to the server.
## Translations

The site is built in Dutch (default) and English by
[jekyll-polyglot](https://github.com/untra/polyglot). Dutch lives at the root,
English under `/en/`. Untranslated content falls back to Dutch rather than 404ing.

Where translations live:

| What | Where |
| --- | --- |
| Interface and page copy | `_data/nl/t.yml` and `_data/en/t.yml`, used as `{{ site.data.t.<key> }}` |
| Menu and filter labels | `_data/<lang>/navigation.yml` and `_data/<lang>/filters.yml` |
| Arcade and pinball pages | `_games/nl/<name>.md` and `_games/en/<name>.md` |
| Page title and description | an `en:` block in the page's own front matter |

Every build prints the translations that are still missing. Set
`i18n_strict: true` in `_config.yml` to turn those warnings into a build failure.

To add a language, add its code to `languages` in `_config.yml`, create
`_data/<code>/` and `_games/<code>/`, and add `_includes/icons/flags/<code>.svg`
for the flag in the navigation bar.
