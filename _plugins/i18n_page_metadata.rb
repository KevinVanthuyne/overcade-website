# Polyglot renders the whole site once per language, but a page keeps the front
# matter it was written with. jekyll-seo-tag reads the title, description and
# locale straight off the page and the site, so the active language's values are
# swapped in right after reading, before anything is rendered.
#
# Site-wide values come from _data/<lang>/t.yml, per-page values from a nested
# block in the page's own front matter:
#
#   title: Over
#   en:
#     title: About

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
