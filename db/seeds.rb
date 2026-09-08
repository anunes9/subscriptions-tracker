# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Categories and the service directory follow PRD sections 4.4 and 4.4.1 exactly
# (the "finalized initial set"). Education and Family & Childcare have no
# directory entries yet — the PRD itself defers their brand list to a design
# pass — but the categories exist so custom subscriptions can use them.
#
# Cancellation URLs are only set where a specific one is already known to be
# correct; per the PRD, the directory (including these links) is
# "maintained by the team over time" — left blank rather than guessed for
# every other entry.

preset_categories = [
  { name: "Streaming & Entertainment", icon: "clapperboard", color: "#e11d48" },
  { name: "Music & Audio", icon: "music", color: "#7c3aed" },
  { name: "Health & Fitness", icon: "dumbbell", color: "#16a34a" },
  { name: "Home & Utilities", icon: "zap", color: "#f59e0b" },
  { name: "Transportation & Vehicle", icon: "car", color: "#0891b2" },
  { name: "Food & Delivery", icon: "utensils", color: "#f97316" },
  { name: "Education", icon: "graduation-cap", color: "#4338ca" },
  { name: "Family & Childcare", icon: "baby", color: "#db2777" },
  { name: "Software & Cloud", icon: "laptop", color: "#2563eb" },
  { name: "Other", icon: "layers", color: "#6b7280" }
].freeze

service_directory_entries = [
  # Streaming & Entertainment
  { name: "Netflix", icon_asset: "netflix", brand_color: "#E50914", category: "Streaming & Entertainment", cancellation_url: "https://www.netflix.com/cancelplan" },
  { name: "Amazon Prime Video", icon_asset: "prime-video", brand_color: "#00A8E1", category: "Streaming & Entertainment" },
  { name: "HBO Max", icon_asset: "hbo-max", brand_color: "#002BE7", category: "Streaming & Entertainment" },
  { name: "Disney+", icon_asset: "disney-plus", brand_color: "#113CCF", category: "Streaming & Entertainment", cancellation_url: "https://www.disneyplus.com/account" },
  { name: "YouTube Premium", icon_asset: "youtube-premium", brand_color: "#FF0000", category: "Streaming & Entertainment" },
  { name: "Hulu", icon_asset: "hulu", brand_color: "#1CE783", category: "Streaming & Entertainment" },
  { name: "Peacock", icon_asset: "peacock", brand_color: "#000000", category: "Streaming & Entertainment" },
  { name: "Apple TV", icon_asset: "apple-tv", brand_color: "#000000", category: "Streaming & Entertainment" },
  { name: "Paramount+", icon_asset: "paramount-plus", brand_color: "#0064FF", category: "Streaming & Entertainment" },
  { name: "SkyShowtime", icon_asset: "skyshowtime", brand_color: "#6C4CE2", category: "Streaming & Entertainment" },
  { name: "Crunchyroll", icon_asset: "crunchyroll", brand_color: "#F47521", category: "Streaming & Entertainment" },
  { name: "DAZN", icon_asset: "dazn", brand_color: "#F8FF13", category: "Streaming & Entertainment" },
  { name: "SportTV", icon_asset: "sporttv", brand_color: "#00953B", category: "Streaming & Entertainment", region: "PT" },
  { name: "Lionsgate+", icon_asset: "lionsgate-plus", brand_color: "#000000", category: "Streaming & Entertainment" },

  # Music & Audio
  { name: "Spotify", icon_asset: "spotify", brand_color: "#1DB954", category: "Music & Audio", cancellation_url: "https://www.spotify.com/account/subscription/cancel/" },
  { name: "Apple Music", icon_asset: "apple-music", brand_color: "#FA243C", category: "Music & Audio" },
  { name: "YouTube Music", icon_asset: "youtube-music", brand_color: "#FF0000", category: "Music & Audio" },
  { name: "Amazon Music", icon_asset: "amazon-music", brand_color: "#25D1DA", category: "Music & Audio" },
  { name: "Deezer", icon_asset: "deezer", brand_color: "#A238FF", category: "Music & Audio" },
  { name: "Tidal", icon_asset: "tidal", brand_color: "#000000", category: "Music & Audio" },
  { name: "Audible", icon_asset: "audible", brand_color: "#F8991C", category: "Music & Audio" },

  # Software & Cloud
  { name: "Claude", icon_asset: "claude", brand_color: "#D97757", category: "Software & Cloud" },
  { name: "ChatGPT", icon_asset: "chatgpt", brand_color: "#10A37F", category: "Software & Cloud" },
  { name: "iCloud+", icon_asset: "icloud", brand_color: "#3693F3", category: "Software & Cloud" },
  { name: "Google One", icon_asset: "google-one", brand_color: "#4285F4", category: "Software & Cloud" },
  { name: "Gemini", icon_asset: "gemini", brand_color: "#8E75B2", category: "Software & Cloud" },
  { name: "Dropbox", icon_asset: "dropbox", brand_color: "#0061FF", category: "Software & Cloud" },
  { name: "Railway", icon_asset: "railway", brand_color: "#0B0D0E", category: "Software & Cloud" },
  { name: "Vercel", icon_asset: "vercel", brand_color: "#000000", category: "Software & Cloud" },
  { name: "Cursor", icon_asset: "cursor", brand_color: "#000000", category: "Software & Cloud" },

  # Home & Utilities — PT providers, plus generic fallbacks for others
  { name: "Vodafone", icon_asset: "vodafone", brand_color: "#E60000", category: "Home & Utilities", region: "PT" },
  { name: "MEO", icon_asset: "meo", brand_color: "#00A19A", category: "Home & Utilities", region: "PT" },
  { name: "NOS", icon_asset: "nos", brand_color: "#E2001A", category: "Home & Utilities", region: "PT" },
  { name: "EDP", icon_asset: "edp", brand_color: "#00A19A", category: "Home & Utilities", region: "PT" },
  { name: "Galp", icon_asset: "galp", brand_color: "#E2001A", category: "Home & Utilities", region: "PT" },
  { name: "Electricity", icon_asset: "electricity-generic", brand_color: "#f59e0b", category: "Home & Utilities" },
  { name: "Gas", icon_asset: "gas-generic", brand_color: "#f59e0b", category: "Home & Utilities" },

  # Health & Fitness — Portugal gym chains
  { name: "Holmes Place", icon_asset: "holmes-place", brand_color: "#000000", category: "Health & Fitness", region: "PT" },
  { name: "Fitness Hut", icon_asset: "fitness-hut", brand_color: "#E2001A", category: "Health & Fitness", region: "PT" },
  { name: "Virgin Active", icon_asset: "virgin-active", brand_color: "#E10A0A", category: "Health & Fitness", region: "PT" },
  { name: "Solinca", icon_asset: "solinca", brand_color: "#00A19A", category: "Health & Fitness", region: "PT" },
  { name: "Fitness UP", icon_asset: "fitness-up", brand_color: "#8E75B2", category: "Health & Fitness", region: "PT" },
  { name: "Vivagym", icon_asset: "vivagym", brand_color: "#00953B", category: "Health & Fitness", region: "PT" },
  { name: "TTF", icon_asset: "ttf", brand_color: "#000000", category: "Health & Fitness", region: "PT" },

  # Transportation & Vehicle
  { name: "Uber", icon_asset: "uber", brand_color: "#000000", category: "Transportation & Vehicle" },
  { name: "Uber One", icon_asset: "uber-one", brand_color: "#000000", category: "Transportation & Vehicle" },
  { name: "Fidelidade", icon_asset: "fidelidade", brand_color: "#E2001A", category: "Transportation & Vehicle", region: "PT" },
  { name: "Generali Tranquilidade", icon_asset: "generali-tranquilidade", brand_color: "#C40C0C", category: "Transportation & Vehicle", region: "PT" },
  { name: "Ageas", icon_asset: "ageas", brand_color: "#003DA5", category: "Transportation & Vehicle", region: "PT" },
  { name: "Allianz", icon_asset: "allianz", brand_color: "#003781", category: "Transportation & Vehicle", region: "PT" },
  { name: "Zurich", icon_asset: "zurich", brand_color: "#0066CC", category: "Transportation & Vehicle", region: "PT" },

  # Food & Delivery
  { name: "Glovo", icon_asset: "glovo", brand_color: "#FFC244", category: "Food & Delivery" },
  { name: "Uber Eats", icon_asset: "uber-eats", brand_color: "#06C167", category: "Food & Delivery" }
].freeze

categories_by_name = preset_categories.each_with_object({}) do |attrs, memo|
  category = Category.find_or_initialize_by(name: attrs[:name], is_preset: true)
  category.assign_attributes(icon: attrs[:icon], color: attrs[:color])
  category.save!
  memo[attrs[:name]] = category
end

service_directory_entries.each do |attrs|
  entry = ServiceDirectoryEntry.find_or_initialize_by(name: attrs[:name])
  entry.assign_attributes(
    icon_asset: attrs[:icon_asset],
    brand_color: attrs[:brand_color],
    cancellation_url: attrs[:cancellation_url],
    region: attrs[:region] || "global",
    default_category: categories_by_name.fetch(attrs[:category])
  )
  entry.save!
end

# Drop directory entries from an earlier seed pass that are no longer in the
# list above — but only ones nothing references, so a real subscription
# never loses its directory link out from under it. Must run before the
# stale-category cleanup below: a category can't be destroyed while an old
# directory entry still points to it.
ServiceDirectoryEntry
  .where.not(name: service_directory_entries.map { |e| e[:name] })
  .where.missing(:subscriptions)
  .destroy_all

# Drop any preset categories from an earlier seed pass that no longer match
# PRD 4.4's list, reassigning their subscriptions/one-time expenses/leftover
# directory entries to Other first (same behavior as
# CategoriesController#destroy) rather than leaving them dangling.
#
# Unlike the controller (which only ever touches the signed-in user's own
# custom category, already covered by the request's RLS session variable), a
# stale *preset* can have subscriptions belonging to many different users —
# this runs outside any request, so each row needs app.current_user_id set to
# its own owner before Row-Level Security will allow the update.
other = categories_by_name.fetch("Other")
Category.presets.where.not(name: preset_categories.map { |c| c[:name] }).find_each do |stale|
  stale.subscriptions.find_each do |subscription|
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute(
        "SET LOCAL app.current_user_id = #{ActiveRecord::Base.connection.quote(subscription.user_id)}"
      )
      subscription.update!(category_id: other.id)
    end
  end
  stale.one_time_expenses.update_all(category_id: other.id)
  ServiceDirectoryEntry.where(default_category_id: stale.id).update_all(default_category_id: other.id)
  stale.destroy!
end

puts "Seeded #{Category.where(is_preset: true).count} preset categories and #{ServiceDirectoryEntry.count} service directory entries."
