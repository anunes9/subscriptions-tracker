SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    icon character varying,
    color character varying,
    user_id uuid,
    is_preset boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: history_log_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.history_log_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subscription_id uuid NOT NULL,
    period character varying NOT NULL,
    amount numeric(12,2) NOT NULL,
    currency character varying NOT NULL,
    is_estimated boolean DEFAULT false NOT NULL,
    confirmed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: household_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.household_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    household_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role character varying DEFAULT 'member'::character varying NOT NULL,
    joined_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: households; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.households (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    owner_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: one_time_expenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.one_time_expenses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    category_id uuid NOT NULL,
    amount numeric(12,2) NOT NULL,
    currency character varying DEFAULT 'EUR'::character varying NOT NULL,
    expense_date date NOT NULL,
    note text,
    household_id uuid,
    visibility character varying DEFAULT 'shared'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: passwordless_login_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.passwordless_login_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying NOT NULL,
    token_hash character varying NOT NULL,
    code_hash character varying NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    used_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: reminder_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reminder_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subscription_id uuid NOT NULL,
    channel character varying NOT NULL,
    trigger_reason character varying NOT NULL,
    sent_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: service_directory_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_directory_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    icon_asset character varying NOT NULL,
    brand_color character varying,
    cancellation_url character varying,
    region character varying DEFAULT 'global'::character varying NOT NULL,
    default_category_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    service_directory_entry_id uuid,
    category_id uuid NOT NULL,
    name character varying NOT NULL,
    currency character varying DEFAULT 'EUR'::character varying NOT NULL,
    billing_cycle character varying NOT NULL,
    amount_type character varying NOT NULL,
    subscription_type character varying DEFAULT 'regular'::character varying NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    billing_anchor_date date NOT NULL,
    trial_end_date date,
    rating integer,
    tag character varying,
    icon_override character varying,
    color_override character varying,
    notes text,
    custom_reminder_lead_days integer,
    household_id uuid,
    visibility character varying DEFAULT 'shared'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.subscriptions FORCE ROW LEVEL SECURITY;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    confirmation_token character varying,
    confirmed_at timestamp(6) without time zone,
    confirmation_sent_at timestamp(6) without time zone,
    unconfirmed_email character varying,
    home_currency character varying DEFAULT 'EUR'::character varying NOT NULL,
    default_reminder_lead_days integer DEFAULT 3 NOT NULL,
    is_premium boolean DEFAULT false NOT NULL,
    premium_since timestamp(6) without time zone,
    provider character varying,
    uid character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: history_log_entries history_log_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_log_entries
    ADD CONSTRAINT history_log_entries_pkey PRIMARY KEY (id);


--
-- Name: household_members household_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.household_members
    ADD CONSTRAINT household_members_pkey PRIMARY KEY (id);


--
-- Name: households households_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.households
    ADD CONSTRAINT households_pkey PRIMARY KEY (id);


--
-- Name: one_time_expenses one_time_expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.one_time_expenses
    ADD CONSTRAINT one_time_expenses_pkey PRIMARY KEY (id);


--
-- Name: passwordless_login_requests passwordless_login_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passwordless_login_requests
    ADD CONSTRAINT passwordless_login_requests_pkey PRIMARY KEY (id);


--
-- Name: reminder_logs reminder_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reminder_logs
    ADD CONSTRAINT reminder_logs_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: service_directory_entries service_directory_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_directory_entries
    ADD CONSTRAINT service_directory_entries_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_categories_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_user_id ON public.categories USING btree (user_id);


--
-- Name: index_history_log_entries_on_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_history_log_entries_on_subscription_id ON public.history_log_entries USING btree (subscription_id);


--
-- Name: index_history_log_entries_on_subscription_id_and_period; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_history_log_entries_on_subscription_id_and_period ON public.history_log_entries USING btree (subscription_id, period);


--
-- Name: index_household_members_on_household_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_household_members_on_household_id ON public.household_members USING btree (household_id);


--
-- Name: index_household_members_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_household_members_on_user_id ON public.household_members USING btree (user_id);


--
-- Name: index_households_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_households_on_owner_id ON public.households USING btree (owner_id);


--
-- Name: index_one_time_expenses_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_one_time_expenses_on_category_id ON public.one_time_expenses USING btree (category_id);


--
-- Name: index_one_time_expenses_on_household_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_one_time_expenses_on_household_id ON public.one_time_expenses USING btree (household_id);


--
-- Name: index_one_time_expenses_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_one_time_expenses_on_user_id ON public.one_time_expenses USING btree (user_id);


--
-- Name: index_passwordless_login_requests_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_passwordless_login_requests_on_email ON public.passwordless_login_requests USING btree (email);


--
-- Name: index_passwordless_login_requests_on_token_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_passwordless_login_requests_on_token_hash ON public.passwordless_login_requests USING btree (token_hash);


--
-- Name: index_reminder_logs_on_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reminder_logs_on_subscription_id ON public.reminder_logs USING btree (subscription_id);


--
-- Name: index_service_directory_entries_on_default_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_directory_entries_on_default_category_id ON public.service_directory_entries USING btree (default_category_id);


--
-- Name: index_subscriptions_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_category_id ON public.subscriptions USING btree (category_id);


--
-- Name: index_subscriptions_on_household_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_household_id ON public.subscriptions USING btree (household_id);


--
-- Name: index_subscriptions_on_service_directory_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_service_directory_entry_id ON public.subscriptions USING btree (service_directory_entry_id);


--
-- Name: index_subscriptions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_user_id ON public.subscriptions USING btree (user_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: one_time_expenses fk_rails_29c99ddc89; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.one_time_expenses
    ADD CONSTRAINT fk_rails_29c99ddc89 FOREIGN KEY (household_id) REFERENCES public.households(id);


--
-- Name: one_time_expenses fk_rails_2a8ab7732d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.one_time_expenses
    ADD CONSTRAINT fk_rails_2a8ab7732d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: household_members fk_rails_342c771846; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.household_members
    ADD CONSTRAINT fk_rails_342c771846 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: history_log_entries fk_rails_3bf4d9dde1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_log_entries
    ADD CONSTRAINT fk_rails_3bf4d9dde1 FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id);


--
-- Name: household_members fk_rails_79aa12c2b5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.household_members
    ADD CONSTRAINT fk_rails_79aa12c2b5 FOREIGN KEY (household_id) REFERENCES public.households(id);


--
-- Name: subscriptions fk_rails_8939f4c134; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_8939f4c134 FOREIGN KEY (service_directory_entry_id) REFERENCES public.service_directory_entries(id);


--
-- Name: service_directory_entries fk_rails_8be4dfba44; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_directory_entries
    ADD CONSTRAINT fk_rails_8be4dfba44 FOREIGN KEY (default_category_id) REFERENCES public.categories(id);


--
-- Name: one_time_expenses fk_rails_9299ce6cbe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.one_time_expenses
    ADD CONSTRAINT fk_rails_9299ce6cbe FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: subscriptions fk_rails_933bdff476; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_933bdff476 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: subscriptions fk_rails_9c09050a70; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_9c09050a70 FOREIGN KEY (household_id) REFERENCES public.households(id);


--
-- Name: households fk_rails_9ec431b680; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.households
    ADD CONSTRAINT fk_rails_9ec431b680 FOREIGN KEY (owner_id) REFERENCES public.users(id);


--
-- Name: reminder_logs fk_rails_a06250abc3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reminder_logs
    ADD CONSTRAINT fk_rails_a06250abc3 FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id);


--
-- Name: categories fk_rails_b8e2f7adfc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT fk_rails_b8e2f7adfc FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: subscriptions fk_rails_f7d582e93e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_f7d582e93e FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: subscriptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: subscriptions subscriptions_owner_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY subscriptions_owner_access ON public.subscriptions USING ((user_id = (NULLIF(current_setting('app.current_user_id'::text, true), ''::text))::uuid));


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260903202128'),
('20260902235158'),
('20260902234844'),
('20260902211945'),
('20260902211943'),
('20260902211942'),
('20260902211941'),
('20260902211939'),
('20260902211920'),
('20260902211853'),
('20260902211825'),
('20260902211803'),
('20260902183235'),
('20260831122839');

