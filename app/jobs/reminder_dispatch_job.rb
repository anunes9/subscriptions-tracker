class ReminderDispatchJob < ApplicationJob
  queue_as :default

  # Finds upcoming renewals/trial-ends within the lead-time window, sends the
  # email + in-app notification, and logs to ReminderLog. Logic lands in
  # Phase 2 (MVP scope doc).
  def perform(*args)
    Rails.logger.info("[ReminderDispatchJob] ran (stub, no logic yet)")
  end
end
