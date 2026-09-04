# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

preset_categories = [
  { name: "Streaming", icon: "clapperboard", color: "#e11d48" },
  { name: "Music", icon: "music", color: "#7c3aed" },
  { name: "Gaming", icon: "gamepad-2", color: "#059669" },
  { name: "Software & SaaS", icon: "laptop", color: "#2563eb" },
  { name: "Cloud Storage", icon: "cloud", color: "#0891b2" },
  { name: "News & Reading", icon: "newspaper", color: "#ca8a04" },
  { name: "Fitness & Health", icon: "dumbbell", color: "#16a34a" },
  { name: "Utilities", icon: "zap", color: "#f59e0b" },
  { name: "Other", icon: "layers", color: "#6b7280" }
].freeze

service_directory_entries = [
  { name: "Netflix", icon_asset: "netflix", brand_color: "#E50914", category: "Streaming", cancellation_url: "https://www.netflix.com/cancelplan" },
  { name: "Disney+", icon_asset: "disney-plus", brand_color: "#113CCF", category: "Streaming", cancellation_url: "https://www.disneyplus.com/account" },
  { name: "Amazon Prime Video", icon_asset: "prime-video", brand_color: "#00A8E1", category: "Streaming" },
  { name: "Max", icon_asset: "max", brand_color: "#002BE7", category: "Streaming" },
  { name: "YouTube Premium", icon_asset: "youtube-premium", brand_color: "#FF0000", category: "Streaming" },
  { name: "Spotify", icon_asset: "spotify", brand_color: "#1DB954", category: "Music", cancellation_url: "https://www.spotify.com/account/subscription/cancel/" },
  { name: "Apple Music", icon_asset: "apple-music", brand_color: "#FA243C", category: "Music" },
  { name: "YouTube Music", icon_asset: "youtube-music", brand_color: "#FF0000", category: "Music" },
  { name: "PlayStation Plus", icon_asset: "playstation-plus", brand_color: "#0070CC", category: "Gaming" },
  { name: "Xbox Game Pass", icon_asset: "xbox-game-pass", brand_color: "#107C10", category: "Gaming" },
  { name: "Nintendo Switch Online", icon_asset: "nintendo-switch-online", brand_color: "#E60012", category: "Gaming" },
  { name: "Adobe Creative Cloud", icon_asset: "adobe-cc", brand_color: "#FF0000", category: "Software & SaaS" },
  { name: "Microsoft 365", icon_asset: "microsoft-365", brand_color: "#D83B01", category: "Software & SaaS" },
  { name: "Notion", icon_asset: "notion", brand_color: "#000000", category: "Software & SaaS" },
  { name: "GitHub", icon_asset: "github", brand_color: "#181717", category: "Software & SaaS" },
  { name: "ChatGPT Plus", icon_asset: "chatgpt", brand_color: "#10A37F", category: "Software & SaaS" },
  { name: "LinkedIn Premium", icon_asset: "linkedin-premium", brand_color: "#0A66C2", category: "Software & SaaS" },
  { name: "iCloud+", icon_asset: "icloud", brand_color: "#3693F3", category: "Cloud Storage" },
  { name: "Google One", icon_asset: "google-one", brand_color: "#4285F4", category: "Cloud Storage" },
  { name: "Dropbox", icon_asset: "dropbox", brand_color: "#0061FF", category: "Cloud Storage" },
  { name: "The New York Times", icon_asset: "nyt", brand_color: "#000000", category: "News & Reading" },
  { name: "Audible", icon_asset: "audible", brand_color: "#F8991C", category: "News & Reading" },
  { name: "Peloton", icon_asset: "peloton", brand_color: "#181A1D", category: "Fitness & Health" },
  { name: "Strava", icon_asset: "strava", brand_color: "#FC4C02", category: "Fitness & Health" }
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
    default_category: categories_by_name.fetch(attrs[:category])
  )
  entry.save!
end

puts "Seeded #{Category.where(is_preset: true).count} preset categories and #{ServiceDirectoryEntry.count} service directory entries."
