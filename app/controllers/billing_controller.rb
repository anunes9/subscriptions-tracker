class BillingController < ApplicationController
  # Stripe posts webhooks without a Rails session/CSRF token.
  skip_before_action :verify_authenticity_token, only: :webhook

  def checkout
    # Stripe Checkout session creation is Phase 3 (MVP scope doc) — this is
    # just the plumbing shape for now.
    head :not_implemented
  end

  def webhook
    event = Stripe::Webhook.construct_event(
      request.body.read,
      request.headers["Stripe-Signature"],
      Rails.application.credentials.dig(:stripe, :webhook_signing_secret)
    )

    Rails.logger.info("[BillingController#webhook] received #{event.type} (#{event.id})")

    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Rails.logger.warn("[BillingController#webhook] rejected: #{e.message}")
    head :bad_request
  end
end
