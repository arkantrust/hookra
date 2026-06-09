


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


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."content_format" AS ENUM (
    'reel',
    'story',
    'post',
    'video',
    'image',
    'carousel',
    'text'
);


ALTER TYPE "public"."content_format" OWNER TO "postgres";


CREATE TYPE "public"."content_platform" AS ENUM (
    'instagram',
    'tiktok',
    'facebook',
    'linkedin',
    'twitter',
    'youtube'
);


ALTER TYPE "public"."content_platform" OWNER TO "postgres";


CREATE TYPE "public"."content_status" AS ENUM (
    'draft',
    'in_review',
    'changes_requested',
    'approved',
    'published',
    'archived'
);


ALTER TYPE "public"."content_status" OWNER TO "postgres";


CREATE TYPE "public"."org_role" AS ENUM (
    'owner',
    'admin',
    'member'
);


ALTER TYPE "public"."org_role" OWNER TO "postgres";


CREATE TYPE "public"."team_role" AS ENUM (
    'manager',
    'editor',
    'client'
);


ALTER TYPE "public"."team_role" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."accept_org_invite"("p_token" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_invite org_invites%ROWTYPE;
BEGIN
  SELECT * INTO v_invite
  FROM org_invites
  WHERE token = p_token::uuid
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invite_not_found';
  END IF;

  IF v_invite.expires_at < NOW() THEN
    RAISE EXCEPTION 'invite_expired';
  END IF;

  IF v_invite.accepted_at IS NOT NULL THEN
    RAISE EXCEPTION 'already_accepted';
  END IF;

  INSERT INTO organization_members (organization_id, profile_id, role)
  VALUES (v_invite.organization_id, auth.uid(), v_invite.role);

  UPDATE org_invites
  SET accepted_at = NOW()
  WHERE token = p_token::uuid;
END;
$$;


ALTER FUNCTION "public"."accept_org_invite"("p_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_member_org_ids"("p_profile_id" "uuid") RETURNS SETOF "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  SELECT organization_id
  FROM public.organization_members
  WHERE profile_id = p_profile_id;
$$;


ALTER FUNCTION "public"."get_member_org_ids"("p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_org_members_with_profiles"("org_uuid" "uuid") RETURNS TABLE("profile_id" "uuid", "first_name" "text", "last_name" "text", "email" "text", "role" "text")
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT m.profile_id, p.first_name, p.last_name, p.email, m.role::text AS role
  FROM public.organization_members m
  LEFT JOIN public.profiles p ON p.id = m.profile_id
  WHERE m.organization_id = org_uuid;
$$;


ALTER FUNCTION "public"."get_org_members_with_profiles"("org_uuid" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_org_role"("p_profile_id" "uuid", "p_org_id" "uuid") RETURNS "public"."org_role"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  SELECT role
  FROM public.organization_members
  WHERE profile_id = p_profile_id
    AND organization_id = p_org_id;
$$;


ALTER FUNCTION "public"."get_org_role"("p_profile_id" "uuid", "p_org_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_team_role"("p_profile_id" "uuid", "p_team_id" "uuid") RETURNS "public"."team_role"
    LANGUAGE "sql" STABLE
    SET "search_path" TO ''
    AS $$
  SELECT role
  FROM public.team_members
  WHERE profile_id = p_profile_id
    AND team_id = p_team_id;
$$;


ALTER FUNCTION "public"."get_team_role"("p_profile_id" "uuid", "p_team_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_comment_resolved"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  IF NEW.resolved = true AND OLD.resolved = false THEN
    NEW.resolved_at := now();
    NEW.resolved_by := auth.uid();
  END IF;
  IF NEW.resolved = false AND OLD.resolved = true THEN
    NEW.resolved_at := NULL;
    NEW.resolved_by := NULL;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_comment_resolved"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_content_version"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  -- Only snapshot if any of the actual content fields changed
  IF (
    OLD.hook      IS DISTINCT FROM NEW.hook      OR
    OLD.script    IS DISTINCT FROM NEW.script    OR
    OLD.caption   IS DISTINCT FROM NEW.caption   OR
    OLD.cta       IS DISTINCT FROM NEW.cta       OR
    OLD.hashtags  IS DISTINCT FROM NEW.hashtags
  ) THEN
    INSERT INTO public.content_versions (
      content_id, version_number,
      hook, script, caption, cta, hashtags,
      saved_by
    ) VALUES (
      OLD.id, OLD.current_version,
      OLD.hook, OLD.script, OLD.caption, OLD.cta, OLD.hashtags,
      auth.uid()
    );

    NEW.current_version := OLD.current_version + 1;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_content_version"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_organization"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
BEGIN
  INSERT INTO public.organization_members (organization_id, profile_id, role)
  VALUES (NEW.id, NEW.owner_id, 'owner');
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_organization"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_team"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  BEGIN
    INSERT INTO public.projects (team_id, name, created_by)
    VALUES (NEW.id, NEW.name, NEW.created_by);
    RETURN NEW;
  END;
  $$;


ALTER FUNCTION "public"."handle_new_team"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
BEGIN
  INSERT INTO public.profiles (id, email, first_name, last_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name'
  );
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."analytics" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "content_id" "uuid" NOT NULL,
    "platform" "public"."content_platform" NOT NULL,
    "views" bigint DEFAULT 0 NOT NULL,
    "likes" bigint DEFAULT 0 NOT NULL,
    "comments" bigint DEFAULT 0 NOT NULL,
    "shares" bigint DEFAULT 0 NOT NULL,
    "saves" bigint DEFAULT 0 NOT NULL,
    "reach" bigint DEFAULT 0 NOT NULL,
    "impressions" bigint DEFAULT 0 NOT NULL,
    "engagement_rate" numeric(6,4),
    "recorded_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."analytics" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."analytics_latest" AS
 SELECT DISTINCT ON ("content_id") "id",
    "content_id",
    "platform",
    "views",
    "likes",
    "comments",
    "shares",
    "saves",
    "reach",
    "impressions",
    "engagement_rate",
    "recorded_at"
   FROM "public"."analytics"
  ORDER BY "content_id", "recorded_at" DESC;


ALTER VIEW "public"."analytics_latest" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "content_id" "uuid" NOT NULL,
    "author_id" "uuid" NOT NULL,
    "parent_id" "uuid",
    "body" "text" NOT NULL,
    "resolved" boolean DEFAULT false NOT NULL,
    "resolved_by" "uuid",
    "resolved_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."content" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "created_by" "uuid",
    "title" "text" NOT NULL,
    "platform" "public"."content_platform" NOT NULL,
    "format" "public"."content_format" NOT NULL,
    "status" "public"."content_status" DEFAULT 'draft'::"public"."content_status" NOT NULL,
    "ai_prompt" "text",
    "ai_model" "text",
    "hook" "text",
    "script" "text",
    "caption" "text",
    "cta" "text",
    "hashtags" "text"[],
    "published_at" timestamp with time zone,
    "published_url" "text",
    "current_version" integer DEFAULT 1 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."content" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."content_versions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "content_id" "uuid" NOT NULL,
    "version_number" integer NOT NULL,
    "hook" "text",
    "script" "text",
    "caption" "text",
    "cta" "text",
    "hashtags" "text"[],
    "saved_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."content_versions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."org_invites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "role" "public"."org_role" DEFAULT 'member'::"public"."org_role" NOT NULL,
    "token" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone DEFAULT ("now"() + '7 days'::interval) NOT NULL,
    "accepted_at" timestamp with time zone
);


ALTER TABLE "public"."org_invites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."organization_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "role" "public"."org_role" DEFAULT 'member'::"public"."org_role" NOT NULL,
    "invited_by" "uuid",
    "joined_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."organization_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."organizations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "logo_url" "text",
    "owner_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."organizations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "first_name" "text" NOT NULL,
    "last_name" "text" NOT NULL,
    "avatar_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "team_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "projects_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'paused'::"text", 'completed'::"text", 'archived'::"text"])))
);


ALTER TABLE "public"."projects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."team_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "team_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "role" "public"."team_role" DEFAULT 'editor'::"public"."team_role" NOT NULL,
    "invited_by" "uuid",
    "joined_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."team_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."teams" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "logo_url" "text",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "state" "text" DEFAULT 'draft'::"text",
    "deleted_at" timestamp with time zone,
    CONSTRAINT "teams_state_check" CHECK (("state" = ANY (ARRAY['draft'::"text", 'published'::"text", 'approved'::"text"])))
);


ALTER TABLE "public"."teams" OWNER TO "postgres";


ALTER TABLE ONLY "public"."analytics"
    ADD CONSTRAINT "analytics_content_id_recorded_at_key" UNIQUE ("content_id", "recorded_at");



ALTER TABLE ONLY "public"."analytics"
    ADD CONSTRAINT "analytics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."content"
    ADD CONSTRAINT "content_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."content_versions"
    ADD CONSTRAINT "content_versions_content_id_version_number_key" UNIQUE ("content_id", "version_number");



ALTER TABLE ONLY "public"."content_versions"
    ADD CONSTRAINT "content_versions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."org_invites"
    ADD CONSTRAINT "org_invites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."org_invites"
    ADD CONSTRAINT "org_invites_token_key" UNIQUE ("token");



ALTER TABLE ONLY "public"."organization_members"
    ADD CONSTRAINT "organization_members_organization_id_profile_id_key" UNIQUE ("organization_id", "profile_id");



ALTER TABLE ONLY "public"."organization_members"
    ADD CONSTRAINT "organization_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."organizations"
    ADD CONSTRAINT "organizations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."organizations"
    ADD CONSTRAINT "organizations_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_team_id_profile_id_key" UNIQUE ("team_id", "profile_id");



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_organization_id_name_key" UNIQUE ("organization_id", "name");



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_analytics_content" ON "public"."analytics" USING "btree" ("content_id");



CREATE INDEX "idx_analytics_recorded_at" ON "public"."analytics" USING "btree" ("recorded_at" DESC);



CREATE INDEX "idx_comments_author" ON "public"."comments" USING "btree" ("author_id");



CREATE INDEX "idx_comments_content" ON "public"."comments" USING "btree" ("content_id");



CREATE INDEX "idx_comments_parent" ON "public"."comments" USING "btree" ("parent_id");



CREATE INDEX "idx_content_platform" ON "public"."content" USING "btree" ("platform");



CREATE INDEX "idx_content_project" ON "public"."content" USING "btree" ("project_id");



CREATE INDEX "idx_content_status" ON "public"."content" USING "btree" ("status");



CREATE INDEX "idx_content_versions_content" ON "public"."content_versions" USING "btree" ("content_id");



CREATE INDEX "idx_org_members_org" ON "public"."organization_members" USING "btree" ("organization_id");



CREATE INDEX "idx_org_members_profile" ON "public"."organization_members" USING "btree" ("profile_id");



CREATE INDEX "idx_projects_team" ON "public"."projects" USING "btree" ("team_id");



CREATE INDEX "idx_team_members_profile" ON "public"."team_members" USING "btree" ("profile_id");



CREATE INDEX "idx_team_members_team" ON "public"."team_members" USING "btree" ("team_id");



CREATE INDEX "idx_teams_org" ON "public"."teams" USING "btree" ("organization_id");



CREATE OR REPLACE TRIGGER "trg_comment_resolved_at" BEFORE UPDATE ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."handle_comment_resolved"();



CREATE OR REPLACE TRIGGER "trg_comments_updated_at" BEFORE UPDATE ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_content_updated_at" BEFORE UPDATE ON "public"."content" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_content_version_snapshot" BEFORE UPDATE ON "public"."content" FOR EACH ROW EXECUTE FUNCTION "public"."handle_content_version"();



CREATE OR REPLACE TRIGGER "trg_on_organization_created" AFTER INSERT ON "public"."organizations" FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_organization"();



CREATE OR REPLACE TRIGGER "trg_on_team_created" AFTER INSERT ON "public"."teams" FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_team"();



CREATE OR REPLACE TRIGGER "trg_organizations_updated_at" BEFORE UPDATE ON "public"."organizations" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_profiles_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_projects_updated_at" BEFORE UPDATE ON "public"."projects" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_teams_updated_at" BEFORE UPDATE ON "public"."teams" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



ALTER TABLE ONLY "public"."analytics"
    ADD CONSTRAINT "analytics_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "public"."content"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "public"."content"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_resolved_by_fkey" FOREIGN KEY ("resolved_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."content"
    ADD CONSTRAINT "content_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."content"
    ADD CONSTRAINT "content_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."content_versions"
    ADD CONSTRAINT "content_versions_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "public"."content"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."content_versions"
    ADD CONSTRAINT "content_versions_saved_by_fkey" FOREIGN KEY ("saved_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."org_invites"
    ADD CONSTRAINT "org_invites_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."org_invites"
    ADD CONSTRAINT "org_invites_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."organization_members"
    ADD CONSTRAINT "organization_members_invited_by_fkey" FOREIGN KEY ("invited_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."organization_members"
    ADD CONSTRAINT "organization_members_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."organization_members"
    ADD CONSTRAINT "organization_members_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."organizations"
    ADD CONSTRAINT "organizations_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_invited_by_fkey" FOREIGN KEY ("invited_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



ALTER TABLE "public"."analytics" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "analytics: no direct insert from client" ON "public"."analytics" FOR INSERT TO "authenticated" WITH CHECK (false);



CREATE POLICY "analytics: team members can read" ON "public"."analytics" FOR SELECT TO "authenticated" USING (("content_id" IN ( SELECT "content"."id"
   FROM "public"."content")));



ALTER TABLE "public"."comments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "comments: authors and team managers can delete" ON "public"."comments" FOR DELETE TO "authenticated" USING ((("auth"."uid"() = "author_id") OR (( SELECT "p"."team_id"
   FROM ("public"."projects" "p"
     JOIN "public"."content" "c" ON (("c"."project_id" = "p"."id")))
  WHERE ("c"."id" = "comments"."content_id")) IN ( SELECT "team_members"."team_id"
   FROM "public"."team_members"
  WHERE (("team_members"."profile_id" = "auth"."uid"()) AND ("team_members"."role" = 'manager'::"public"."team_role"))))));



CREATE POLICY "comments: authors can update their own" ON "public"."comments" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "author_id"));



CREATE POLICY "comments: team members can insert" ON "public"."comments" FOR INSERT TO "authenticated" WITH CHECK ((("auth"."uid"() = "author_id") AND ("content_id" IN ( SELECT "content"."id"
   FROM "public"."content"))));



CREATE POLICY "comments: team members can read" ON "public"."comments" FOR SELECT TO "authenticated" USING (("content_id" IN ( SELECT "content"."id"
   FROM "public"."content")));



ALTER TABLE "public"."content" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "content: agency members and editors can create" ON "public"."content" FOR INSERT TO "authenticated" WITH CHECK (("project_id" IN ( SELECT "p"."id"
   FROM "public"."projects" "p"
  WHERE (("p"."team_id" IN ( SELECT "t"."id"
           FROM "public"."teams" "t"
          WHERE ("t"."organization_id" IN ( SELECT "public"."get_member_org_ids"("auth"."uid"()) AS "get_member_org_ids")))) OR ("p"."team_id" IN ( SELECT "team_members"."team_id"
           FROM "public"."team_members"
          WHERE (("team_members"."profile_id" = "auth"."uid"()) AND ("team_members"."role" = ANY (ARRAY['manager'::"public"."team_role", 'editor'::"public"."team_role"])))))))));



CREATE POLICY "content: agency members and editors can update" ON "public"."content" FOR UPDATE TO "authenticated" USING (("project_id" IN ( SELECT "p"."id"
   FROM "public"."projects" "p"
  WHERE (("p"."team_id" IN ( SELECT "t"."id"
           FROM "public"."teams" "t"
          WHERE ("t"."organization_id" IN ( SELECT "public"."get_member_org_ids"("auth"."uid"()) AS "get_member_org_ids")))) OR ("p"."team_id" IN ( SELECT "team_members"."team_id"
           FROM "public"."team_members"
          WHERE (("team_members"."profile_id" = "auth"."uid"()) AND ("team_members"."role" = ANY (ARRAY['manager'::"public"."team_role", 'editor'::"public"."team_role"])))))))));



CREATE POLICY "content: org owner/admin can delete non-published content" ON "public"."content" FOR DELETE TO "authenticated" USING ((("status" <> 'published'::"public"."content_status") AND ("project_id" IN ( SELECT "p"."id"
   FROM ("public"."projects" "p"
     JOIN "public"."teams" "t" ON (("t"."id" = "p"."team_id")))
  WHERE ("t"."organization_id" IN ( SELECT "organization_members"."organization_id"
           FROM "public"."organization_members"
          WHERE (("organization_members"."profile_id" = "auth"."uid"()) AND ("organization_members"."role" = ANY (ARRAY['owner'::"public"."org_role", 'admin'::"public"."org_role"])))))))));



CREATE POLICY "content: team members can read" ON "public"."content" FOR SELECT TO "authenticated" USING (("project_id" IN ( SELECT "p"."id"
   FROM "public"."projects" "p"
  WHERE (("p"."team_id" IN ( SELECT "t"."id"
           FROM "public"."teams" "t"
          WHERE ("t"."organization_id" IN ( SELECT "public"."get_member_org_ids"("auth"."uid"()) AS "get_member_org_ids")))) OR ("p"."team_id" IN ( SELECT "team_members"."team_id"
           FROM "public"."team_members"
          WHERE ("team_members"."profile_id" = "auth"."uid"())))))));



ALTER TABLE "public"."content_versions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "content_versions: insert via trigger only" ON "public"."content_versions" FOR INSERT TO "authenticated" WITH CHECK (false);



CREATE POLICY "content_versions: team members can read" ON "public"."content_versions" FOR SELECT TO "authenticated" USING (("content_id" IN ( SELECT "content"."id"
   FROM "public"."content")));



ALTER TABLE "public"."org_invites" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "org_invites: anyone can accept" ON "public"."org_invites" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "org_invites: anyone can read by token" ON "public"."org_invites" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "org_invites: owner and admin can delete" ON "public"."org_invites" FOR DELETE TO "authenticated" USING (("public"."get_org_role"("auth"."uid"(), "organization_id") = ANY (ARRAY['owner'::"public"."org_role", 'admin'::"public"."org_role"])));



CREATE POLICY "org_invites: owner and admin can insert" ON "public"."org_invites" FOR INSERT TO "authenticated" WITH CHECK (("public"."get_org_role"("auth"."uid"(), "organization_id") = ANY (ARRAY['owner'::"public"."org_role", 'admin'::"public"."org_role"])));



CREATE POLICY "org_members: members can read their org's members" ON "public"."organization_members" FOR SELECT TO "authenticated" USING (("organization_id" IN ( SELECT "public"."get_member_org_ids"("auth"."uid"()) AS "get_member_org_ids")));



CREATE POLICY "org_members: only owner can update roles" ON "public"."organization_members" FOR UPDATE TO "authenticated" USING (("public"."get_org_role"("auth"."uid"(), "organization_id") = 'owner'::"public"."org_role"));



CREATE POLICY "org_members: owner and admin can insert" ON "public"."organization_members" FOR INSERT TO "authenticated" WITH CHECK (("public"."get_org_role"("auth"."uid"(), "organization_id") = ANY (ARRAY['owner'::"public"."org_role", 'admin'::"public"."org_role"])));



CREATE POLICY "org_members: owner and admin can remove members" ON "public"."organization_members" FOR DELETE TO "authenticated" USING ((("public"."get_org_role"("auth"."uid"(), "organization_id") = ANY (ARRAY['owner'::"public"."org_role", 'admin'::"public"."org_role"])) AND ("role" <> 'owner'::"public"."org_role")));



ALTER TABLE "public"."organization_members" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "organizations: authenticated users can create" ON "public"."organizations" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "owner_id"));



CREATE POLICY "organizations: members can read" ON "public"."organizations" FOR SELECT TO "authenticated" USING (("id" IN ( SELECT "public"."get_member_org_ids"("auth"."uid"()) AS "get_member_org_ids")));



CREATE POLICY "organizations: only owner can delete" ON "public"."organizations" FOR DELETE TO "authenticated" USING (("public"."get_org_role"("auth"."uid"(), "id") = 'owner'::"public"."org_role"));



CREATE POLICY "organizations: owner and admin can update" ON "public"."organizations" FOR UPDATE TO "authenticated" USING (("public"."get_org_role"("auth"."uid"(), "id") = ANY (ARRAY['owner'::"public"."org_role", 'admin'::"public"."org_role"])));



CREATE POLICY "profiles: authenticated users can read all" ON "public"."profiles" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "profiles: users can insert their own" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "profiles: users can update their own" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id"));



ALTER TABLE "public"."projects" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "projects: agency members can create" ON "public"."projects" FOR INSERT TO "authenticated" WITH CHECK (((( SELECT "teams"."organization_id"
   FROM "public"."teams"
  WHERE ("teams"."id" = "projects"."team_id")) IN ( SELECT "public"."get_member_org_ids"("auth"."uid"()) AS "get_member_org_ids")) OR ("public"."get_team_role"("auth"."uid"(), "team_id") = ANY (ARRAY['manager'::"public"."team_role", 'editor'::"public"."team_role"]))));



CREATE POLICY "projects: agency members can update" ON "public"."projects" FOR UPDATE TO "authenticated" USING (((( SELECT "teams"."organization_id"
   FROM "public"."teams"
  WHERE ("teams"."id" = "projects"."team_id")) IN ( SELECT "public"."get_member_org_ids"("auth"."uid"()) AS "get_member_org_ids")) OR ("public"."get_team_role"("auth"."uid"(), "team_id") = ANY (ARRAY['manager'::"public"."team_role", 'editor'::"public"."team_role"]))));



CREATE POLICY "projects: org members and team members can read" ON "public"."projects" FOR SELECT TO "authenticated" USING ((("team_id" IN ( SELECT "t"."id"
   FROM "public"."teams" "t"
  WHERE ("t"."organization_id" IN ( SELECT "public"."get_member_org_ids"("auth"."uid"()) AS "get_member_org_ids")))) OR ("team_id" IN ( SELECT "team_members"."team_id"
   FROM "public"."team_members"
  WHERE ("team_members"."profile_id" = "auth"."uid"())))));



CREATE POLICY "projects: org owner/admin or team manager can delete" ON "public"."projects" FOR DELETE TO "authenticated" USING (((( SELECT "teams"."organization_id"
   FROM "public"."teams"
  WHERE ("teams"."id" = "projects"."team_id")) IN ( SELECT "organization_members"."organization_id"
   FROM "public"."organization_members"
  WHERE (("organization_members"."profile_id" = "auth"."uid"()) AND ("organization_members"."role" = ANY (ARRAY['owner'::"public"."org_role", 'admin'::"public"."org_role"]))))) OR ("public"."get_team_role"("auth"."uid"(), "team_id") = 'manager'::"public"."team_role")));



CREATE POLICY "team_members: org members and team members can read" ON "public"."team_members" FOR SELECT TO "authenticated" USING ((("team_id" IN ( SELECT "t"."id"
   FROM "public"."teams" "t"
  WHERE ("t"."organization_id" IN ( SELECT "public"."get_member_org_ids"("auth"."uid"()) AS "get_member_org_ids")))) OR ("profile_id" = "auth"."uid"())));



CREATE POLICY "team_members: org owner/admin or team manager can delete" ON "public"."team_members" FOR DELETE TO "authenticated" USING (((( SELECT "teams"."organization_id"
   FROM "public"."teams"
  WHERE ("teams"."id" = "team_members"."team_id")) IN ( SELECT "organization_members"."organization_id"
   FROM "public"."organization_members"
  WHERE (("organization_members"."profile_id" = "auth"."uid"()) AND ("organization_members"."role" = ANY (ARRAY['owner'::"public"."org_role", 'admin'::"public"."org_role"]))))) OR ("public"."get_team_role"("auth"."uid"(), "team_id") = 'manager'::"public"."team_role")));



CREATE POLICY "team_members: org owner/admin or team manager can insert" ON "public"."team_members" FOR INSERT TO "authenticated" WITH CHECK (((( SELECT "teams"."organization_id"
   FROM "public"."teams"
  WHERE ("teams"."id" = "team_members"."team_id")) IN ( SELECT "organization_members"."organization_id"
   FROM "public"."organization_members"
  WHERE (("organization_members"."profile_id" = "auth"."uid"()) AND ("organization_members"."role" = ANY (ARRAY['owner'::"public"."org_role", 'admin'::"public"."org_role"]))))) OR ("public"."get_team_role"("auth"."uid"(), "team_id") = 'manager'::"public"."team_role")));



CREATE POLICY "teams: org members can read their org's teams" ON "public"."teams" FOR SELECT TO "authenticated" USING ((("organization_id" IN ( SELECT "public"."get_member_org_ids"("auth"."uid"()) AS "get_member_org_ids")) OR ("id" IN ( SELECT "team_members"."team_id"
   FROM "public"."team_members"
  WHERE ("team_members"."profile_id" = "auth"."uid"())))));



CREATE POLICY "teams: org owner and admin can create" ON "public"."teams" FOR INSERT TO "authenticated" WITH CHECK (("public"."get_org_role"("auth"."uid"(), "organization_id") = ANY (ARRAY['owner'::"public"."org_role", 'admin'::"public"."org_role"])));



CREATE POLICY "teams: org owner and admin can delete" ON "public"."teams" FOR DELETE TO "authenticated" USING (("public"."get_org_role"("auth"."uid"(), "organization_id") = ANY (ARRAY['owner'::"public"."org_role", 'admin'::"public"."org_role"])));



CREATE POLICY "teams: org owner and admin can update" ON "public"."teams" FOR UPDATE TO "authenticated" USING (("public"."get_org_role"("auth"."uid"(), "organization_id") = ANY (ARRAY['owner'::"public"."org_role", 'admin'::"public"."org_role"])));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






















































































































































GRANT ALL ON FUNCTION "public"."accept_org_invite"("p_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."accept_org_invite"("p_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."accept_org_invite"("p_token" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_member_org_ids"("p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_member_org_ids"("p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_member_org_ids"("p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_org_members_with_profiles"("org_uuid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_org_members_with_profiles"("org_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_org_members_with_profiles"("org_uuid" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_org_role"("p_profile_id" "uuid", "p_org_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_org_role"("p_profile_id" "uuid", "p_org_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_org_role"("p_profile_id" "uuid", "p_org_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_team_role"("p_profile_id" "uuid", "p_team_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_team_role"("p_profile_id" "uuid", "p_team_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_team_role"("p_profile_id" "uuid", "p_team_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_comment_resolved"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_comment_resolved"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_comment_resolved"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_content_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_content_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_content_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_organization"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_organization"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_organization"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_team"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_team"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_team"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";


















GRANT ALL ON TABLE "public"."analytics" TO "anon";
GRANT ALL ON TABLE "public"."analytics" TO "authenticated";
GRANT ALL ON TABLE "public"."analytics" TO "service_role";



GRANT ALL ON TABLE "public"."analytics_latest" TO "anon";
GRANT ALL ON TABLE "public"."analytics_latest" TO "authenticated";
GRANT ALL ON TABLE "public"."analytics_latest" TO "service_role";



GRANT ALL ON TABLE "public"."comments" TO "anon";
GRANT ALL ON TABLE "public"."comments" TO "authenticated";
GRANT ALL ON TABLE "public"."comments" TO "service_role";



GRANT ALL ON TABLE "public"."content" TO "anon";
GRANT ALL ON TABLE "public"."content" TO "authenticated";
GRANT ALL ON TABLE "public"."content" TO "service_role";



GRANT ALL ON TABLE "public"."content_versions" TO "anon";
GRANT ALL ON TABLE "public"."content_versions" TO "authenticated";
GRANT ALL ON TABLE "public"."content_versions" TO "service_role";



GRANT ALL ON TABLE "public"."org_invites" TO "anon";
GRANT ALL ON TABLE "public"."org_invites" TO "authenticated";
GRANT ALL ON TABLE "public"."org_invites" TO "service_role";



GRANT ALL ON TABLE "public"."organization_members" TO "anon";
GRANT ALL ON TABLE "public"."organization_members" TO "authenticated";
GRANT ALL ON TABLE "public"."organization_members" TO "service_role";



GRANT ALL ON TABLE "public"."organizations" TO "anon";
GRANT ALL ON TABLE "public"."organizations" TO "authenticated";
GRANT ALL ON TABLE "public"."organizations" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."projects" TO "anon";
GRANT ALL ON TABLE "public"."projects" TO "authenticated";
GRANT ALL ON TABLE "public"."projects" TO "service_role";



GRANT ALL ON TABLE "public"."team_members" TO "anon";
GRANT ALL ON TABLE "public"."team_members" TO "authenticated";
GRANT ALL ON TABLE "public"."team_members" TO "service_role";



GRANT ALL ON TABLE "public"."teams" TO "anon";
GRANT ALL ON TABLE "public"."teams" TO "authenticated";
GRANT ALL ON TABLE "public"."teams" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































