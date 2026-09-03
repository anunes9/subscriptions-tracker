class PriceChangeCheckJob < ApplicationJob
  queue_as :default

  # Compares the newest vs. previous confirmed HistoryLogEntry.amount and flags
  # price changes for Premium users. Logic lands in Phase 2/5 (MVP scope doc).
  def perform(*args)
    Rails.logger.info("[PriceChangeCheckJob] ran (stub, no logic yet)")
  end
end
