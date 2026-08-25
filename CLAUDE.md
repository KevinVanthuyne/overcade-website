# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Overcade is a Jekyll static site for authentic arcade and pinball machine rentals ("arcadeverhuur") in Belgium. All content and UI text is in Dutch (`nl_BE`). Styling is Tailwind CSS, with markup patterns taken from Hyper UI.

## Commands

```bash
bundle install                          # Ruby gems
npm install                             # Node dependencies
bundle exec jekyll serve --livereload   # dev server on http://localhost:4000
```

```powershell
# Production build (Windows PowerShell) — output in _site/
$env:JEKYLL_ENV = 'production'; bundle exec jekyll build
```

```bash
npx prettier --write "**/*.{html,liquid,md}"   # format templates (no prettier config file; plugin comes from package.json)
```

There are no tests and no linter. Verification means running a build and checking the rendered output.

### ImageMagick prerequisite

`jekyll-responsive-image` needs ImageMagick 6 (**not** 7) plus the `rmagick` gem. Install [ImageMagick-6.9.13-21-Q16-HDRI-x64-dll.exe](https://imagemagick.org/archive/binaries/ImageMagick-6.9.13-21-Q16-HDRI-x64-dll.exe) to a path **without spaces**, checking "development headers and libraries for C and C++", "legacy utilities (e.g. identify)", and "Add application directory to your system path". Then:

```shell
gem install rmagick -- --with-opt-dir=S:\ProgramFiles\ImageMagick-6.9.13-Q16-HDRI
```

Without it, every build fails at image generation.

## Deployment

Pushing to `master` triggers `.github/workflows/build_and_deploy.yml`: it builds with `JEKYLL_ENV=production` and deploys `_site/` over FTPS to `./httpdocs/` using the `FTP_SERVER_URL` / `FTP_USERNAME` / `FTP_PASSWORD` secrets. Manually copying `_site/` to the server (as the README describes) is only a fallback.

The workflow caches `_site/assets/resized` keyed on `assets/images/**`, then `touch`es the restored files into the future — `jekyll-responsive-image` regenerates only when the destination is older than the source, and a fresh checkout resets source mtimes. Keep that step if you touch the workflow, or every build regenerates all image sizes.

## Architecture

### The filters system

`_data/filters.yml` is the single source of truth for game properties. Each entry has an `id`, a Dutch `label`, an optional `tooltip`, and a list of `values` (each with `id` + `label`). It drives three things at once:

1. The filter sidebar checkboxes on [games.html](games.html).
2. The `data-<filter.id>="<value>"` attributes on each game `<li>`, which the inline filtering script reads.
3. The "Eigenschappen" definition list on [_layouts/game.html](_layouts/game.html) (which skips `category`).

A game's frontmatter key must exactly equal a `filter.id`, and its value must exactly equal one of that filter's `value.id`s. Mismatches fail silently — the game simply won't match the filter and the property won't render. **Adding a new filter is a `_data/filters.yml` edit plus a frontmatter key on the games; no template changes are needed.**

Filtering is client-side, in an inline `<script>` at the bottom of `games.html`: OR within a filter group, AND across groups, with state mirrored into URL query params (`?genre=classic,shooter`) and restored on load.

### Game collection (`_games/*.md`)

Output as individual pages via the `games` collection, defaulting to the `game` layout. Frontmatter beyond the filter keys:

- `image` — primary image; `images` — gallery, both rendered into a Splide carousel with thumbnails
- `showOnHomepage` — include in the "Uitgelicht aanbod" section on the home page
- `featured` — red "Populair" badge on the card
- `order` — sort order on `games.html` (games without it sort last)
- `tagline` — short line under the name, rendered through `markdownify`
- `preview: true` — an upcoming machine: the card renders greyed out with a "Binnenkort" badge, no link and no detail page, and needs no filter keys
- `published: false` — standard Jekyll; drops the document from `site.games` entirely, so it disappears from every listing. `_games/shuffle-box.md` carries both, which means it is currently hidden site-wide, not shown as a preview.

### Images

Never write a plain `<img src>` for content images. Use the responsive image tags, which render through [_includes/responsive-image.html.liquid](_includes/responsive-image.html.liquid):

```liquid
{% responsive_image path: assets/images/foo.jpg alt: "Beschrijving" %}

{% responsive_image_block %}
path: {{ game.image }}
class: "h-full w-full object-contain"
{% endresponsive_image_block %}
```

Paths are repo-root-relative with **no leading slash**. Widths 80–2500px are generated at 65% quality (see `responsive_image` in `_config.yml`). The output uses `data-src`/`data-srcset` with a `lazyload` class — lazysizes is loaded from CDN in `_layouts/default.html`, so images outside that layout won't load without it.

Images referenced only from CSS or otherwise invisible to Jekyll must be listed under `responsive_image.extra_images` in `_config.yml` (as `assets/images/pac-man-in-office.JPG` is, used by `.landing-page-background-image`).

### Styling

[assets/css/styles.scss](assets/css/styles.scss) is the only stylesheet entry point: it `@use`s the `_sass/` partials and the Inter font from `node_modules`, then pulls in Tailwind's layers. It carries an empty frontmatter block so Jekyll processes it, and PostCSS (`postcss.config.js`) parses it as SCSS, runs Tailwind and autoprefixer, and adds cssnano only when `JEKYLL_ENV=production`.

Tailwind purges against the `content` globs in `tailwind.config.js`. Templates in a new top-level directory need a glob added there, or their classes get stripped from the production build. Prefer Tailwind utilities; `_sass/` is for the few things utilities can't express (background images, masks, Splide thumbnail states).

### Third-party JS

Splide (carousels) and lazysizes are loaded from CDNs, not npm — lazysizes in `_layouts/default.html`, Splide's CSS there and its JS in each template that uses it (`_layouts/game.html`, `_includes/sections/home-page-games-overview.html.liquid`). A page with a carousel must include the Splide script itself.

### Pages

`index.html` is a thin list of `_includes/sections/*` includes — home page changes usually mean editing one of those section partials. Navigation comes from `_data/navigation.yml`. `_layouts/default.html` supplies the nav, footer, favicons, and `{% seo %}` tags; site-wide SEO values live in `_config.yml`.
