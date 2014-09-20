--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plperl; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: -
--

CREATE OR REPLACE PROCEDURAL LANGUAGE plperl;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: plperl_call_handler(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION plperl_call_handler() RETURNS language_handler
    LANGUAGE c
    AS '$libdir/plperl', 'plperl_call_handler';


--
-- Name: plpgsql_call_handler(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION plpgsql_call_handler() RETURNS language_handler
    LANGUAGE c
    AS '$libdir/plpgsql', 'plpgsql_call_handler';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: flags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE flags (
    id integer NOT NULL,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: flags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE flags_id_seq OWNED BY flags.id;


--
-- Name: newsgroups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE newsgroups (
    id integer NOT NULL,
    name text,
    status text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: newsgroups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE newsgroups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: newsgroups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE newsgroups_id_seq OWNED BY newsgroups.id;


--
-- Name: postings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE postings (
    id integer NOT NULL,
    newsgroup_id integer,
    post_id integer,
    number integer,
    top_level boolean
);


--
-- Name: postings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE postings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: postings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE postings_id_seq OWNED BY postings.id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE posts (
    id integer NOT NULL,
    subject text,
    author text,
    date timestamp without time zone,
    message_id text,
    stripped boolean,
    sticky_user_id integer,
    sticky_until timestamp without time zone,
    headers text,
    body text,
    dethreaded boolean,
    followup_newsgroup_id integer,
    ancestry text
);


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE posts_id_seq OWNED BY posts.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: starred_post_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE starred_post_entries (
    id integer NOT NULL,
    user_id integer,
    post_id integer,
    created_at timestamp without time zone
);


--
-- Name: starred_post_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE starred_post_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: starred_post_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE starred_post_entries_id_seq OWNED BY starred_post_entries.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subscriptions (
    id integer NOT NULL,
    user_id integer,
    newsgroup_name text,
    unread_level integer,
    email_level integer,
    digest_type text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subscriptions_id_seq OWNED BY subscriptions.id;


--
-- Name: unread_post_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE unread_post_entries (
    id integer NOT NULL,
    user_id integer,
    post_id integer,
    personal_level integer,
    user_created boolean
);


--
-- Name: unread_post_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE unread_post_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: unread_post_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE unread_post_entries_id_seq OWNED BY unread_post_entries.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    username text,
    real_name text,
    preferences text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    api_key text,
    api_data text
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY flags ALTER COLUMN id SET DEFAULT nextval('flags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY newsgroups ALTER COLUMN id SET DEFAULT nextval('newsgroups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY postings ALTER COLUMN id SET DEFAULT nextval('postings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY posts ALTER COLUMN id SET DEFAULT nextval('posts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY starred_post_entries ALTER COLUMN id SET DEFAULT nextval('starred_post_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions ALTER COLUMN id SET DEFAULT nextval('subscriptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY unread_post_entries ALTER COLUMN id SET DEFAULT nextval('unread_post_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY flags
    ADD CONSTRAINT flags_pkey PRIMARY KEY (id);


--
-- Name: newsgroups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY newsgroups
    ADD CONSTRAINT newsgroups_pkey PRIMARY KEY (id);


--
-- Name: postings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY postings
    ADD CONSTRAINT postings_pkey PRIMARY KEY (id);


--
-- Name: posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: starred_post_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY starred_post_entries
    ADD CONSTRAINT starred_post_entries_pkey PRIMARY KEY (id);


--
-- Name: subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: unread_post_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY unread_post_entries
    ADD CONSTRAINT unread_post_entries_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_newsgroups_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_newsgroups_on_name ON newsgroups USING btree (name);


--
-- Name: index_postings_on_newsgroup_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_postings_on_newsgroup_id ON postings USING btree (newsgroup_id);


--
-- Name: index_postings_on_newsgroup_id_and_post_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_postings_on_newsgroup_id_and_post_id ON postings USING btree (newsgroup_id, post_id);


--
-- Name: index_postings_on_post_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_postings_on_post_id ON postings USING btree (post_id);


--
-- Name: index_posts_on_ancestry; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_on_ancestry ON posts USING btree (ancestry text_pattern_ops);


--
-- Name: index_posts_on_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_on_date ON posts USING btree (date);


--
-- Name: index_posts_on_followup_newsgroup_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_on_followup_newsgroup_id ON posts USING btree (followup_newsgroup_id);


--
-- Name: index_posts_on_message_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_posts_on_message_id ON posts USING btree (message_id);


--
-- Name: index_posts_on_sticky_until; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_on_sticky_until ON posts USING btree (sticky_until);


--
-- Name: index_posts_on_sticky_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_on_sticky_user_id ON posts USING btree (sticky_user_id);


--
-- Name: index_starred_post_entries_on_post_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_starred_post_entries_on_post_id ON starred_post_entries USING btree (post_id);


--
-- Name: index_starred_post_entries_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_starred_post_entries_on_user_id ON starred_post_entries USING btree (user_id);


--
-- Name: index_starred_post_entries_on_user_id_and_post_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_starred_post_entries_on_user_id_and_post_id ON starred_post_entries USING btree (user_id, post_id);


--
-- Name: index_subscriptions_on_newsgroup_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_subscriptions_on_newsgroup_name ON subscriptions USING btree (newsgroup_name);


--
-- Name: index_subscriptions_on_newsgroup_name_and_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_subscriptions_on_newsgroup_name_and_user_id ON subscriptions USING btree (newsgroup_name, user_id);


--
-- Name: index_subscriptions_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_subscriptions_on_user_id ON subscriptions USING btree (user_id);


--
-- Name: index_unread_post_entries_on_post_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_unread_post_entries_on_post_id ON unread_post_entries USING btree (post_id);


--
-- Name: index_unread_post_entries_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_unread_post_entries_on_user_id ON unread_post_entries USING btree (user_id);


--
-- Name: index_unread_post_entries_on_user_id_and_post_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_unread_post_entries_on_user_id_and_post_id ON unread_post_entries USING btree (user_id, post_id);


--
-- Name: index_users_on_api_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_api_key ON users USING btree (api_key);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_username ON users USING btree (username);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20110722010927');

INSERT INTO schema_migrations (version) VALUES ('20110722013036');

INSERT INTO schema_migrations (version) VALUES ('20110722013949');

INSERT INTO schema_migrations (version) VALUES ('20110722021456');

INSERT INTO schema_migrations (version) VALUES ('20111004143929');

INSERT INTO schema_migrations (version) VALUES ('20111115010321');

INSERT INTO schema_migrations (version) VALUES ('20111226194104');

INSERT INTO schema_migrations (version) VALUES ('20120112010906');

INSERT INTO schema_migrations (version) VALUES ('20120304014715');

INSERT INTO schema_migrations (version) VALUES ('20120505165046');

INSERT INTO schema_migrations (version) VALUES ('20120527182337');

INSERT INTO schema_migrations (version) VALUES ('20120809215745');

INSERT INTO schema_migrations (version) VALUES ('20120901192447');

INSERT INTO schema_migrations (version) VALUES ('20130512230751');

INSERT INTO schema_migrations (version) VALUES ('20130522004513');

INSERT INTO schema_migrations (version) VALUES ('20130608141604');

INSERT INTO schema_migrations (version) VALUES ('20131009224837');

INSERT INTO schema_migrations (version) VALUES ('20140822012950');

INSERT INTO schema_migrations (version) VALUES ('20140822021710');

INSERT INTO schema_migrations (version) VALUES ('20140826155556');

INSERT INTO schema_migrations (version) VALUES ('20140828220838');

INSERT INTO schema_migrations (version) VALUES ('20140907004526');

INSERT INTO schema_migrations (version) VALUES ('20140907004527');

INSERT INTO schema_migrations (version) VALUES ('20140908165746');

INSERT INTO schema_migrations (version) VALUES ('20140908204835');

INSERT INTO schema_migrations (version) VALUES ('20140908213001');

INSERT INTO schema_migrations (version) VALUES ('20140908214711');

INSERT INTO schema_migrations (version) VALUES ('20140916160844');

INSERT INTO schema_migrations (version) VALUES ('20140920004346');

INSERT INTO schema_migrations (version) VALUES ('20140920010001');

