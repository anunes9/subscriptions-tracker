-- Runs once, automatically, the first time the postgres container initializes
-- its data directory (docker-entrypoint-initdb.d convention) — as the
-- superuser, since that's the only role the postgres image guarantees exists.
--
-- Creates the actual non-superuser role the app connects as in every
-- environment (see config/database.yml and README.md#row-level-security):
-- Postgres superusers always bypass Row-Level Security regardless of policy,
-- so the app deliberately never connects as one, even locally.
CREATE ROLE subscriptions_tracker WITH LOGIN CREATEDB PASSWORD 'subscriptions_tracker_dev';

CREATE DATABASE subscriptions_tracker_development OWNER subscriptions_tracker;
CREATE DATABASE subscriptions_tracker_development_queue OWNER subscriptions_tracker;
CREATE DATABASE subscriptions_tracker_test OWNER subscriptions_tracker;
CREATE DATABASE subscriptions_tracker_test_queue OWNER subscriptions_tracker;
