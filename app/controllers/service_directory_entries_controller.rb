class ServiceDirectoryEntriesController < AuthenticatedController
  # Autocomplete data source for the add-subscription flow (name -> icon/category
  # prefill, PRD 4.4.1) — a plain JSON endpoint rather than an Inertia page since
  # it's consumed via fetch from within another page, not navigated to directly.
  def index
    entries = ServiceDirectoryEntry.search(params[:q]).order(:name).limit(10)

    render json: entries.as_json(
      only: [ :id, :name, :icon_asset, :brand_color, :cancellation_url, :region, :default_category_id ]
    )
  end
end
