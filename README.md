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