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
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  Overcade::I18nPageMetadata.localize_site(site)
  Overcade::I18nPageMetadata.localize_pages(site)
end
