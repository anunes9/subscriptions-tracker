# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

# vite-plugin-pwa's manifest.webmanifest isn't in Rack's built-in mime table,
# so Rails' static file server would otherwise serve it as text/plain.
Rack::Mime::MIME_TYPES[".webmanifest"] = "application/manifest+json"
