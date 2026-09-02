class Rack::Attack
  # Independent of Rails.cache, which is a :null_store in development/test —
  # throttling needs counts to actually persist.
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  throttle("passwordless_login_requests/email", limit: 3, period: 10.minutes) do |req|
    if req.path == "/login/passwordless" && req.post?
      req.params["email"].to_s.downcase.strip.presence
    end
  end

  throttle("passwordless_login_requests/ip", limit: 10, period: 10.minutes) do |req|
    req.ip if req.path == "/login/passwordless" && req.post?
  end

  self.throttled_responder = lambda do |request|
    [ 429, { "Content-Type" => "application/json" }, [ { error: "Too many requests. Please try again later." }.to_json ] ]
  end
end
