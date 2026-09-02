require "rails_helper"

RSpec.describe ReminderMailer, type: :mailer do
  describe "renewal_due" do
    let(:mail) { ReminderMailer.renewal_due }

    it "renders the headers" do
      expect(mail.subject).to eq("Renewal due")
      expect(mail.to).to eq([ "to@example.org" ])
      expect(mail.from).to eq([ "hello@example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "trial_ending" do
    let(:mail) { ReminderMailer.trial_ending }

    it "renders the headers" do
      expect(mail.subject).to eq("Trial ending")
      expect(mail.to).to eq([ "to@example.org" ])
      expect(mail.from).to eq([ "hello@example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end
end
