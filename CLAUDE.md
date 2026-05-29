# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Overcade is a Jekyll-based static website for authentic arcade game rentals (Dutch: "arcadeverhuur"). The site showcases available arcade games, rental plans, and contact information.

## Development Commands

### Initial Setup

```bash
# Install Ruby gems (requires Ruby and Jekyll installed)
bundle install

# Install Node.js dependencies
npm install

# For responsive image support, ensure ImageMagick is installed:
# Download: https://imagemagick.org/archive/binaries/ImageMagick-6.9.13-21-Q16-HDRI-x64-dll.exe
# Install to a path WITHOUT spaces and check:
# - Install development headers and libraries for C and C++
# - Install legacy utilities (e.g. identify)
# - Add application directory to your system path
# Then install rmagick gem: gem install rmagick -- --with-opt-dir=[ImageMagick_path]
```

### Running the Development Server

```bash
# Start local development with live reload
bundle exec jekyll serve --livereload
# Site will be available at http://localhost:4000
```

### Building for Production

```powershell
# Windows PowerShell
$env:JEKYLL_ENV = 'production'; bundle exec jekyll build
```

The compiled site is in the `_site/` directory, ready for deployment.

### Code Formatting

```bash
# Format all Liquid templates and HTML
npx prettier --write "**/*.{html,liquid,md}"

# Format SCSS only
npx prettier --write "**/*.scss"
```

## Architecture

### Content Structure

**Collections (`_games/`)**: Arcade game entries as Markdown files with YAML frontmatter. Each game has:
- Metadata: `name`, `year`, `manufacturer`, `category`
- Images: `image` (primary) and `images` (gallery)
- Display options: `featured`, `showOnHomepage`, `order`
- Filters: `multiplayer`, `force_feedback`, `controls`, `genre`
- Description: Markdown body content

**Static Pages**: `index.html`, `games.html`, `about.html`, `contact.html`, `leaderboard.html` — contain main content with Liquid template includes.

**Layouts** (`_layouts/`):
- `default.html`: Main layout with navigation, footer, and SEO tags
- `game.html`: Layout for individual arcade game pages (inherits from default)

**Includes** (`_includes/`):
- `sections/`: Home page sections (banner, features, plans, contact, games overview)
- `icons/`: SVG icons (trophy, location, joystick, etc.)
- `logo/`: Brand assets
- `navigation.html.liquid`, `footer.html.liquid`: Global UI components
- `game-card.html.liquid`, `plan-card.html.liquid`, `feature-card.html.liquid`: Reusable card components
- `responsive-image.html.liquid`: Image rendering with multiple sizes

### Styling

**Tailwind CSS**: Utility-first framework configured in `tailwind.config.js`. Content paths include:
- `_includes/**/*.html.liquid`
- `_layouts/**/*.html.liquid`
- `_games/*.md`
- Root `.html` and `.html.liquid` files

**PostCSS Pipeline** (`postcss.config.js`):
1. Parse SCSS via postcss-scss
2. Process Tailwind utilities
3. Add vendor prefixes (autoprefixer)
4. Minify CSS in production (cssnano)

**Styles** (`assets/css/styles.scss`): Main SCSS entry point that imports Tailwind and custom styles.

### Image Handling

Jekyll's responsive-image plugin generates multiple image sizes (80px to 2500px wide) for performance. Configuration in `_config.yml`:
- Template: `_includes/responsive-image.html.liquid`
- Default quality: 65%
- Extra images processed: `assets/images/pac-man-in-office.JPG`
- Images stored in: `assets/images/arcades/[game-name]/`

### SEO & Metadata

`_config.yml` defines site-wide SEO through jekyll-seo-tag:
- Title, description, URL, locale (nl_BE for Dutch/Belgium)
- Social media links (Facebook, Instagram)
- Default preview image for social sharing
- Sitemap auto-generation

## Key Dependencies

**Ruby/Bundler**:
- `jekyll`: Static site generator
- `jekyll-sitemap`: Auto-generates sitemap.xml
- `jekyll-seo-tag`: SEO meta tags and structured data
- `jekyll-postcss-v2`: Integrates PostCSS build into Jekyll
- `jekyll-responsive-image`: Multi-size responsive images (requires ImageMagick)

**Node.js/npm**:
- `tailwindcss`: Utility CSS framework
- `postcss` & `postcss-cli`: CSS transformation
- `postcss-scss`: SCSS parser for PostCSS
- `autoprefixer`: Vendor prefixes
- `cssnano`: CSS minification (production)
- `prettier` + `@shopify/prettier-plugin-liquid`: Code formatting
- `@fontsource-variable/inter`: Variable Inter font

## Important Details

- **Language**: Dutch (nl_BE locale) — content and UI in Dutch
- **Deployment**: Manual — copy `_site/` contents to server after production build
- **Image Optimization**: ImageMagick must be installed and in PATH; missing it breaks responsive image generation
- **Live Reload**: Only works in development; requires `--livereload` flag
- **Production CSS**: Only minified when `JEKYLL_ENV=production` is set
- **Responsive Images**: Processed at build time; don't edit images in `_site/` — they'll be overwritten on next build
