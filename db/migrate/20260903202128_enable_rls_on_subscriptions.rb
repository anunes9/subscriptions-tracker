class EnableRlsOnSubscriptions < ActiveRecord::Migration[7.2]
  def up
    execute "ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;"
    # FORCE is required because Postgres exempts the table owner from RLS by
    # default — without it, the app's own DB role (which owns the table it
    # created) would silently bypass every policy below.
    execute "ALTER TABLE subscriptions FORCE ROW LEVEL SECURITY;"

    # NULLIF guards against two distinct "unset" states for a custom GUC:
    # a session that never touched app.current_user_id sees NULL from
    # current_setting(..., true) (missing_ok), but a session that SET it
    # earlier and then RESET it sees '' (Postgres resets a custom GUC
    # placeholder to empty string, not NULL) — and ''::uuid raises rather
    # than just failing the comparison. NULLIF collapses both to NULL, so
    # a request that forgets to set app.current_user_id sees zero rows
    # instead of a hard error, matching this spike's acceptance criteria.
    execute <<~SQL
      CREATE POLICY subscriptions_owner_access ON subscriptions
      USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS subscriptions_owner_access ON subscriptions;"
    execute "ALTER TABLE subscriptions NO FORCE ROW LEVEL SECURITY;"
    execute "ALTER TABLE subscriptions DISABLE ROW LEVEL SECURITY;"
  end
end
