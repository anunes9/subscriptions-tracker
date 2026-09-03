class PeriodRolloverJob < ApplicationJob
  queue_as :default

  # For each active subscription whose billing period has turned over, creates
  # the next HistoryLogEntry. Logic lands in Phase 2 (MVP scope doc).
  def perform(*args)
    Rails.logger.info("[PeriodRolloverJob] ran (stub, no logic yet)")
  end
end
