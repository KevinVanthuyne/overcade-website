# Lists the translations that are still missing, every time the site is built.
#
# The problem this solves:
#
# When Polyglot cannot find an English version of something, it does not fail and
# it does not warn. It quietly falls back to the Dutch version and carries on. A
# visitor on /en/ then reads a page that is partly or entirely in Dutch, and
# nothing anywhere says so. Delete _games/en/frogger.md and the build stays green;
# /en/games/frogger.html simply serves the Dutch text.
#
# That fallback is deliberate and worth keeping, because it means the site can be
# translated a page at a time instead of all at once. But it needs a counterweight,
# or a forgotten translation is only ever found by a visitor. This plugin is that
# counterweight: it compares the two languages after every read and prints what is
# missing.
#
# What it compares:
#
#   1. Data files. Every value in _data/nl/ must have a counterpart in _data/en/.
#      This covers interface text (t.yml), the menu (navigation.yml) and the filter
#      labels (filters.yml) in one pass, and it looks inside lists as well as
#      nested keys, because Polyglot replaces a whole list rather than merging it
#      entry by entry. An English list one item shorter than the Dutch one silently
#      renders one card fewer, so that has to be caught too.
#
#   2. Collection documents. Every file in _games/nl/ must have a file with the
#      same name in _games/en/.
#
#   3. Pages. Every page with a title must carry a front matter block for the other
#      language, as described in _plugins/i18n_page_metadata.rb. Pages that only
#      exist in Dutch on purpose, the Maker Faire ones, are skipped: they are listed
#      in exclude_from_localization in _config.yml and are never built in English.
#
# What it prints:
#
#   i18n: 3 missing EN translation(s)
#   i18n:   _data/en/ is missing t.games.clear_filters
#   i18n:   games/en/frogger.md is missing
#   i18n:   about.html has no en: block with a title
#
# Setting i18n_strict: true in _config.yml turns those warnings into an error that
# stops the build, which is the useful setting once everything is translated and
# the goal is to keep it that way.

module Overcade
  module I18nTranslationCheck
    module_function

    # Flattens nested data into dotted paths so two languages can be diffed as
    # flat lists of leaves.
    def leaf_paths(value, prefix = "")
      case value
      when Hash
        value.flat_map { |key, nested| leaf_paths(nested, join(prefix, key)) }
      when Array
        value.each_with_index.flat_map { |nested, index| leaf_paths(nested, "#{prefix}[#{index}]") }
      else
        [prefix]
      end
    end

    def join(prefix, key)
      prefix.empty? ? key.to_s : "#{prefix}.#{key}"
    end

    def data_gaps(site, lang)
      default = site.data[site.default_lang] || {}
      translated = site.data[lang] || {}
      (leaf_paths(default) - leaf_paths(translated)).map do |path|
        "_data/#{lang}/ is missing #{path}"
      end
    end

    def document_gaps(site, lang)
      site.collections.each_value.flat_map do |collection|
        default_dir = File.join(collection.directory, site.default_lang)
        next [] unless Dir.exist?(default_dir)

        translated_dir = File.join(collection.directory, lang)
        translated = Dir.exist?(translated_dir) ? Dir.children(translated_dir) : []
        (Dir.children(default_dir) - translated).map do |name|
          "#{collection.label}/#{lang}/#{name} is missing"
        end
      end
    end

    def page_gaps(site, lang)
      excluded = site.config["exclude_from_localization"] || []
      site.pages.reject { |page| skip_page?(page, excluded) }
          .reject { |page| page.data[lang].is_a?(Hash) && page.data[lang]["title"] }
          .map { |page| "#{page.path} has no #{lang}: block with a title" }
    end

    def skip_page?(page, excluded)
      page.data["title"].nil? || excluded.any? { |prefix| page.path.start_with?(prefix) }
    end

    def report(site)
      site.languages.reject { |lang| lang == site.default_lang }.each do |lang|
        gaps = data_gaps(site, lang) + document_gaps(site, lang) + page_gaps(site, lang)
        next if gaps.empty?

        summary = "#{gaps.length} missing #{lang.upcase} translation(s)"
        raise "#{summary}: #{gaps.join(', ')}" if site.config["i18n_strict"]

        Jekyll.logger.warn "i18n:", summary
        gaps.each { |gap| Jekyll.logger.warn "i18n:", "  #{gap}" }
      end
    end
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  # Every language re-reads the site, so only report while the first one builds.
  Overcade::I18nTranslationCheck.report(site) if site.active_lang == site.default_lang
end
