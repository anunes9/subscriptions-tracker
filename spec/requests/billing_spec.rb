require "rails_helper"

RSpec.describe "Billing webhook", type: :request do
  let(:signing_secret) { Rails.application.credentials.dig(:stripe, :webhook_signing_secret) }
  let(:payload) do
    {
      id: "evt_test_123",
      object: "event",
      type: "customer.subscription.updated",
      data: { object: { id: "sub_test_123" } }
    }.to_json
  end

  def signed_header_for(payload, secret: signing_secret, timestamp: Time.current)
    signature = Stripe::Webhook::Signature.compute_signature(timestamp, payload, secret)
    Stripe::Webhook::Signature.generate_header(timestamp, signature)
  end

  it "returns 200 for a validly-signed event" do
    post "/billing/webhook", params: payload, headers: { "Stripe-Signature" => signed_header_for(payload), "Content-Type" => "application/json" }

    expect(response).to have_http_status(:ok)
  end

  it "returns 400 for a signature signed with the wrong secret" do
    bad_header = signed_header_for(payload, secret: "whsec_totally_wrong_secret")

    post "/billing/webhook", params: payload, headers: { "Stripe-Signature" => bad_header, "Content-Type" => "application/json" }

    expect(response).to have_http_status(:bad_request)
  end

  it "returns 400 when the payload is tampered with after signing" do
    header = signed_header_for(payload)
    tampered_payload = JSON.parse(payload).merge(type: "customer.subscription.deleted").to_json

    post "/billing/webhook", params: tampered_payload, headers: { "Stripe-Signature" => header, "Content-Type" => "application/json" }

    expect(response).to have_http_status(:bad_request)
  end

  it "returns 400 when the Stripe-Signature header is missing entirely" do
    post "/billing/webhook", params: payload, headers: { "Content-Type" => "application/json" }

    expect(response).to have_http_status(:bad_request)
  end
end
