class CreatePasswordlessLoginRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :passwordless_login_requests, id: :uuid do |t|
      t.string :email, null: false
      t.string :token_hash, null: false
      t.string :code_hash, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :passwordless_login_requests, :email
    add_index :passwordless_login_requests, :token_hash, unique: true
  end
end
