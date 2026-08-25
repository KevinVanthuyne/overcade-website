# Lists the translations that are still missing, on every build.
#
# When one is absent Polyglot silently serves the Dutch version, so a half
# translated site looks finished. This compares _data/nl with _data/en, _games/nl
# with _games/en, and each page's front matter, then warns about the gaps.
#
# Lists are compared entry by entry because Polyglot replaces a whole list rather
# than merging it, so a shorter English list quietly renders fewer items.
#
# i18n_strict: true in _config.yml turns the warnings into a failed build.

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
