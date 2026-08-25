# Gives each language its own page title, description and locale.
#
# The problem this solves:
#
# Polyglot builds the whole site once per language. The same about.html file is
# rendered twice: once into /about.html and once into /en/about.html. But that
# file has only one set of front matter, and it is Dutch:
#
#   title: Over
#   description: Overcade staat voor authenticiteit en kwaliteit...
#
# jekyll-seo-tag reads those values straight off the page to build the <title>
# tag, the meta description, the Open Graph tags and the JSON-LD block. It has no
# idea that Polyglot is building an English copy, so without this plugin the
# English page would show "Over" in the browser tab, a Dutch description in
# Google's search results, and og:locale="nl_BE" when someone shares it.
#
# Polyglot does not help here. It handles URLs, and it merges the _data folders
# per language, but it never touches a page's front matter.
#
# How it works:
#
# Pages carry their translations in a nested block named after the language:
#
#   title: Over
#   description: Overcade staat voor authenticiteit en kwaliteit...
#   en:
#     title: About
#     description: Overcade stands for authenticity and quality...
#
# While the English copy is being built, this plugin copies the contents of that
# "en" block over the real title and description. Every later step, jekyll-seo-tag
# included, then sees English values and needs no changes of its own. Site-wide
# values (the name after the "|" in the browser tab, the fallback description, the
# locale) come from the "site" block in _data/<lang>/t.yml the same way.
#
# The swap happens on the post_read hook, which fires once Jekyll has read every
# file but before it renders anything. That timing matters: the obvious hook to
# use would be pre_render, but Jekyll hands the page to the renderer just before
# pre_render fires, so a title changed there arrives too late and the Dutch one is
# rendered anyway.
#
# A page without a block for the active language is left alone, and it then falls
# back to Dutch. _plugins/i18n_translation_check.rb reports those pages.

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
