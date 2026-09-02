class ReminderMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.reminder_mailer.renewal_due.subject
  #
  def renewal_due
    @greeting = "Hi"

    mail to: "to@example.org"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.reminder_mailer.trial_ending.subject
  #
  def trial_ending
    @greeting = "Hi"

    mail to: "to@example.org"
  end
end
