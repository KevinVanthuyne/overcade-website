# Reports translations that are still missing, so an untranslated page shows up
# in the build log instead of silently falling back to Dutch.
#
# Three things are checked against the default language:
#   * every string in _data/<default_lang>/ has a counterpart in _data/<lang>/
#   * every collection document in <collection>/<default_lang>/ has a sibling in
#     <collection>/<lang>/
#   * every page with a title carries a <lang>: front matter block
#
# Set i18n_strict: true in _config.yml to fail the build instead of warning.

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
