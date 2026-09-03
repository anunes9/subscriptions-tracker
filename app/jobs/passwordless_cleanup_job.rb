class PasswordlessCleanupJob < ApplicationJob
  queue_as :default

  # Purges expired/used PasswordlessLoginRequest rows (data-model.md 2.9).
  # Wired up as an empty stub here per the scaffolding plan; given the model
  # already exists (Ticket 0.5), only the actual deletion logic is deferred.
  def perform(*args)
    Rails.logger.info("[PasswordlessCleanupJob] ran (stub, no logic yet)")
  end
end
