# Gives each language its own page title, description and locale.
#
# Polyglot builds every page twice, but front matter exists once and it is Dutch.
# jekyll-seo-tag reads it directly, so without this the English page shows "Over"
# in the browser tab and og:locale="nl_BE".
#
# Translations live in a block named after the language (en:) on the page itself,
# and in the "site" block of _data/<lang>/t.yml. Both are copied over the real
# values here.
#
# Runs on post_read, not pre_render: Jekyll hands the page to the renderer just
# before pre_render fires, so a title changed there arrives too late.

module Overcade
  module I18nPageMetadata
    SITE_KEYS = %w[title tagline description locale].freeze
    PAGE_KEYS = %w[title description].freeze

    module_function

    def localize_site(site)
      translations = site.data.dig(site.active_lang, "t", "site")
      return if translations.nil?

      SITE_KEYS.each do |key|
        site.config[key] = translations[key] unless translations[key].nil?
      end
    end

    def localize_pages(site)
      pages = site.pages + site.collections.each_value.flat_map(&:docs)
      pages.each do |page|
        overrides = page.data[site.active_lang]
        next unless overrides.is_a?(Hash)

        PAGE_KEYS.each do |key|
          page.data[key] = overrides[key] unless overrides[key].nil?
        end
      end
    end

    # Builds "Pac-Man arcade huren" from game.page_title in t.yml, so a new game
    # gets a search-friendly title without anyone having to remember to write one.
    def title_games(site)
      games = site.collections["games"]
      return if games.nil?

      games.docs.each do |doc|
        translations = site.data.dig(doc.data["lang"] || site.active_lang, "t", "game")
        pattern = translations&.dig("page_title")
        machine = translations&.dig("machine", doc.data["category"])
        next if pattern.nil? || machine.nil?

        # Jekyll has already filled in "Pac Man" from the filename when the front
        # matter has no title. Anything else was written by hand and wins.
        next unless doc.data["title"] == Jekyll::Utils.titleize_slug(doc.data["slug"].to_s)

        doc.data["title"] = format(pattern, name: doc.data["name"], machine: machine)
      end
    end
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  Overcade::I18nPageMetadata.localize_site(site)
  Overcade::I18nPageMetadata.localize_pages(site)
  Overcade::I18nPageMetadata.title_games(site)
end
