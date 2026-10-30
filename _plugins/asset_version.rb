# Gives the stylesheet URL a version that is the same for every language.
#
# styles.css has no fingerprint in its file name and the server sends no
# Cache-Control header, so browsers keep serving an old copy after a deploy.
# Polyglot resets the site once per language, which changes site.time, so the
# version is taken once here instead.

Jekyll::Hooks.register :site, :after_init do |site|
  site.config['asset_version'] = Time.now.to_i.to_s
end
