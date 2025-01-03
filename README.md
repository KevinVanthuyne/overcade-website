# Overcade Website

Built with Jekyll, Tailwind CSS and Hyper UI.

## Setup

1. [Install Ruby and Jekyll](https://jekyllrb.com/docs/installation/windows/)

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