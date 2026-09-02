# Preview all emails at http://localhost:3000/rails/mailers/reminder_mailer
class ReminderMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/reminder_mailer/renewal_due
  def renewal_due
    ReminderMailer.renewal_due
  end

  # Preview this email at http://localhost:3000/rails/mailers/reminder_mailer/trial_ending
  def trial_ending
    ReminderMailer.trial_ending
  end
end
