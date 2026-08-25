# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Overcade is a Jekyll static site for authentic arcade and pinball machine rentals ("arcadeverhuur") in Belgium. Content is Dutch (`nl_BE`) at the site root and English (`en_GB`) under `/en/`, built by `jekyll-polyglot`. Styling is Tailwind CSS, with markup patterns taken from Hyper UI.

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

The workflow caches `assets/resized` keyed on `assets/images/**`. `jekyll-responsive-image` runs with `save_to_source: true` and skips any size whose file already exists, so the cache alone is enough — no mtime juggling. Writing the images into the source tree is also what stops the second language pass from regenerating all ~610 of them.

## Architecture

### The filters system

`_data/<lang>/filters.yml` is the single source of truth for game properties. Each entry has an `id`, a translated `label`, an optional `tooltip`, and a list of `values` (each with `id` + `label`). The `id`s are language-neutral and **must** be identical across languages; only the labels are translated. It drives three things at once:

1. The filter sidebar checkboxes on [games.html](games.html).
2. The `data-<filter.id>="<value>"` attributes on each game `<li>`, which the inline filtering script reads.
3. The "Eigenschappen" definition list on [_layouts/game.html](_layouts/game.html) (which skips `category`).

A game's frontmatter key must exactly equal a `filter.id`, and its value must exactly equal one of that filter's `value.id`s. Mismatches fail silently — the game simply won't match the filter and the property won't render. **Adding a new filter is a `_data/<lang>/filters.yml` edit in every language plus a frontmatter key on the games; no template changes are needed.**

Quote labels that YAML would read as booleans (`"Yes"`, `"No"`), or they render as `true`/`false`.

Filtering is client-side, in an inline `<script>` at the bottom of `games.html`: OR within a filter group, AND across groups, with state mirrored into URL query params (`?genre=classic,shooter`) and restored on load.

### Game collection (`_games/<lang>/*.md`)

Output as individual pages via the `games` collection, defaulting to the `game` layout. One document per language, paired by an explicit `permalink`. Frontmatter beyond the filter keys:

- `image` — primary image; `images` — gallery, both rendered into a Splide carousel with thumbnails
- `showOnHomepage` — include in the "Uitgelicht aanbod" section on the home page
- `featured` — red "Populair" badge on the card
- `order` — sort order on `games.html` (games without it sort last)
- `tagline` — short line under the name, rendered through `markdownify`
- `preview: true` — an upcoming machine: the card renders greyed out with a "Binnenkort" badge, no link and no detail page, and needs no filter keys
- `published: false` — standard Jekyll; drops the document from `site.games` entirely, so it disappears from every listing. `_games/<lang>/shuffle-box.md` carries both, which means it is currently hidden site-wide, not shown as a preview.
- `lang` and `permalink` — `_games/nl/pac-man.md` and `_games/en/pac-man.md` both set `permalink: /games/pac-man.html`, which is what pairs them as translations and preserves the original URLs. The permalink must be explicit: Jekyll memoises `Document#url` before Polyglot gets a chance to strip the language segment from the path.

Everything except `name`, `tagline` and the body is duplicated between the two files. The missing-translation check catches a missing file, not divergent metadata, so keep images and filter keys in sync by hand.

### Images

Never write a plain `<img src>` for content images. Use the responsive image tags, which render through [_includes/responsive-image.html.liquid](_includes/responsive-image.html.liquid):

```liquid
{% responsive_image path: assets/images/foo.jpg alt: "Beschrijving" %}

{% responsive_image_block %}
path: {{ game.image }}
class: "h-full w-full object-contain"
{% endresponsive_image_block %}
```

**The inline form does not evaluate Liquid in its arguments.** `alt: "{{ site.data.t.foo }}"` ships as a literal template string. Anything with a variable in it — which now includes every translated `alt` — must use the block form, which renders its body first.

Paths are repo-root-relative with **no leading slash**. Widths 80–2500px are generated at 65% quality (see `responsive_image` in `_config.yml`). The output uses `data-src`/`data-srcset` with a `lazyload` class — lazysizes is loaded from CDN in `_layouts/default.html`, so images outside that layout won't load without it.

Images referenced only from CSS or otherwise invisible to Jekyll must be listed under `responsive_image.extra_images` in `_config.yml` (as `assets/images/pac-man-in-office.JPG` is, used by `.landing-page-background-image`).

### Translations

Dutch is the default language and is served from the site root; English is built into `/en/`. `jekyll-polyglot` renders the whole site once per language, so there is one copy of every template, not one per language.

| What | Where |
| --- | --- |
| Interface and page copy | `_data/nl/t.yml`, `_data/en/t.yml`, read as `{{ site.data.t.about.title }}` |
| Menu and filter labels | `_data/<lang>/navigation.yml`, `_data/<lang>/filters.yml` |
| Arcade and pinball pages | `_games/nl/*.md`, `_games/en/*.md` |
| Page title and description | an `en:` block in the page's own front matter |

Polyglot merges `site.data[default_lang]` and then `site.data[active_lang]` up to the top level of `site.data`. That is why templates write `site.data.t` with no language in the expression, and why a key missing from `en` falls back to the Dutch string. The merge recurses into hashes but **replaces arrays wholesale**, so a shortened list in `_data/en/` loses entries rather than inheriting them.

Copy belongs in `_data/<lang>/t.yml`, not in duplicated page files — the markup stays single-source.

Links are handled for you: Polyglot rewrites relative `href`s so `/games.html` becomes `/en/games.html` inside the English build. Two consequences:

- Anything that should **not** be rewritten needs `{% static_href %}`, as in `_includes/language-switcher.html.liquid` and `_includes/language-alternates.html.liquid`. In the alternates, the `href` is deliberately written before `hreflang`: Polyglot refuses to restore a `static_href` that directly follows `hreflang="<default_lang>"`.
- Only `href` attributes are rewritten. `src`, `content` and XML `<loc>` are not, which is why `sitemap.xml` is hand-written rather than generated by `jekyll-sitemap`, and why the canonical URL is set explicitly for `{% seo %}`.

Paths that exist only at the site root — `assets`, the favicons, the Maker Faire pages — are listed under `exclude_from_localization` in `_config.yml`. That keeps them out of `/en/` and stops links to them being prefixed. The language switcher and the `hreflang` alternates hide themselves on those pages.

Every build reports what is still untranslated, comparing the data files key by key, the collection folders file by file, and each page's front matter:

```
i18n: 1 missing EN translation(s)
i18n:   games/en/frogger.md is missing
```

Untranslated content falls back to Dutch instead of 404ing, so this warning is the only signal. Set `i18n_strict: true` in `_config.yml` to fail the build on it instead.

Adding a language means: its code in `languages` in `_config.yml`, a `_data/<code>/` directory, a `_games/<code>/` directory, and `_includes/icons/flags/<code>.svg` for the switcher.

### Styling

[assets/css/styles.scss](assets/css/styles.scss) is the only stylesheet entry point: it `@use`s the `_sass/` partials and the Inter font from `node_modules`, then pulls in Tailwind's layers. It carries an empty frontmatter block so Jekyll processes it, and PostCSS (`postcss.config.js`) parses it as SCSS, runs Tailwind and autoprefixer, and adds cssnano only when `JEKYLL_ENV=production`.

Tailwind purges against the `content` globs in `tailwind.config.js` (note `_games/**/*.md` — the games are nested per language). Templates in a new top-level directory need a glob added there, or their classes get stripped from the production build. Prefer Tailwind utilities; `_sass/` is for the few things utilities can't express (background images, masks, Splide thumbnail states).

### Third-party JS

Splide (carousels) and lazysizes are loaded from CDNs, not npm — lazysizes in `_layouts/default.html`, Splide's CSS there and its JS in each template that uses it (`_layouts/game.html`, `_includes/sections/home-page-games-overview.html.liquid`). A page with a carousel must include the Splide script itself.

### Pages

`index.html` is a thin list of `_includes/sections/*` includes — home page changes usually mean editing one of those section partials. Navigation comes from `_data/<lang>/navigation.yml`. `_layouts/default.html` supplies the nav, footer, favicons, language switcher, `hreflang` alternates and `{% seo %}` tags.

Site-wide SEO defaults live in `_config.yml`, but `_plugins/i18n_page_metadata.rb` overrides the title, tagline, description, locale and canonical URL per language before anything renders — change those in `_data/<lang>/t.yml`, not `_config.yml`.
