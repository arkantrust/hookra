-- A content piece belongs to a project.
-- Structured around the Hookra workflow: hook → script → caption → cta → hashtags.

CREATE TYPE public.content_platform AS ENUM (
  'instagram', 'tiktok', 'facebook', 'linkedin', 'twitter', 'youtube'
);

CREATE TYPE public.content_format AS ENUM (
  'reel', 'story', 'post', 'video', 'image', 'carousel', 'text'
);

CREATE TYPE public.content_status AS ENUM (
  'draft',        -- being worked on by agency
  'in_review',    -- sent to client for approval
  'changes_requested', -- client asked for revisions
  'approved',     -- client approved, ready to publish
  'published',    -- live on the platform
  'archived'      -- no longer active
);

CREATE TABLE public.content (
  id              uuid             PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id      uuid             NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  created_by      uuid             REFERENCES public.profiles(id) ON DELETE SET NULL,
  title           text             NOT NULL,
  platform        content_platform NOT NULL,
  format          content_format   NOT NULL,
  status          content_status   NOT NULL DEFAULT 'draft',

  -- AI generation inputs
  ai_prompt       text,            -- the prompt sent to the AI
  ai_model        text,            -- which model was used e.g. "claude-sonnet-4"

  -- Content fields (these are versioned — see content_versions)
  hook            text,            -- attention-grabbing opening line
  script          text,            -- full script or body copy
  caption         text,            -- platform caption
  cta             text,            -- call to action
  hashtags        text[],          -- stored as an array for easy filtering

  -- Publishing
  published_at    timestamptz,
  published_url   text,

  -- Versioning
  current_version int  NOT NULL DEFAULT 1,

  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_content_updated_at
  BEFORE UPDATE ON public.content
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Auto-save a version snapshot whenever content fields change
CREATE OR REPLACE FUNCTION public.handle_content_version()
RETURNS trigger
SET search_path = ''
LANGUAGE plpgsql
SECURITY DEFINER
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

CREATE TRIGGER trg_content_version_snapshot
  BEFORE UPDATE ON public.content
  FOR EACH ROW EXECUTE FUNCTION public.handle_content_version();

-- Immutable snapshots of content fields before each edit.
-- Version N = what the content looked like before edit N+1 was made.

CREATE TABLE public.content_versions (
  id             uuid  PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id     uuid  NOT NULL REFERENCES public.content(id) ON DELETE CASCADE,
  version_number int   NOT NULL,
  hook           text,
  script         text,
  caption        text,
  cta            text,
  hashtags       text[],
  saved_by       uuid  REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (content_id, version_number)
);

-- Comments on a content piece. Any team member (agency or client) can comment.
-- Supports threaded replies via parent_id.

CREATE TABLE public.comments (
  id          uuid  PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id  uuid  NOT NULL REFERENCES public.content(id) ON DELETE CASCADE,
  author_id   uuid  NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  parent_id   uuid  REFERENCES public.comments(id) ON DELETE CASCADE, -- for threaded replies
  body        text  NOT NULL,
  resolved    bool  NOT NULL DEFAULT false,
  resolved_by uuid  REFERENCES public.profiles(id) ON DELETE SET NULL,
  resolved_at timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_comments_updated_at
  BEFORE UPDATE ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Auto-stamp resolved_at when resolved is flipped to true
CREATE OR REPLACE FUNCTION public.handle_comment_resolved()
RETURNS trigger
SET search_path = ''
LANGUAGE plpgsql
SECURITY INVOKER
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

CREATE TRIGGER trg_comment_resolved_at
  BEFORE UPDATE ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.handle_comment_resolved();

-- Periodic performance snapshots per content piece.
-- Multiple rows per content piece (one per recorded_at snapshot).
-- Deltas (change since last snapshot) are computed at query time.

CREATE TABLE public.analytics (
  id          uuid  PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id  uuid  NOT NULL REFERENCES public.content(id) ON DELETE CASCADE,
  platform    content_platform NOT NULL,

  -- Raw cumulative counts as reported by the platform API
  views       bigint NOT NULL DEFAULT 0,
  likes       bigint NOT NULL DEFAULT 0,
  comments    bigint NOT NULL DEFAULT 0,
  shares      bigint NOT NULL DEFAULT 0,
  saves       bigint NOT NULL DEFAULT 0,
  reach       bigint NOT NULL DEFAULT 0,   -- unique accounts reached
  impressions bigint NOT NULL DEFAULT 0,

  -- Computed and stored at snapshot time for convenience
  engagement_rate numeric(6,4),            -- (likes+comments+shares+saves) / reach

  recorded_at timestamptz NOT NULL DEFAULT now(),

  -- Prevent duplicate snapshots for the same content at the same time
  UNIQUE (content_id, recorded_at)
);

-- Convenience view: latest analytics snapshot per content piece
CREATE OR REPLACE VIEW public.analytics_latest AS
SELECT DISTINCT ON (content_id)
  *
FROM public.analytics
ORDER BY content_id, recorded_at DESC;

ALTER TABLE public.content               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_versions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics             ENABLE ROW LEVEL SECURITY;

-- Clients can read content in their team.
-- Only agency-side can create/update. Nobody deletes published content.

CREATE POLICY "content: team members can read"
  ON public.content FOR SELECT
  TO authenticated
  USING (
    project_id IN (
      SELECT p.id FROM public.projects p
      WHERE
        -- org member
        p.team_id IN (
          SELECT t.id FROM public.teams t
          WHERE t.org_id IN (SELECT public.get_member_org_ids(auth.uid()))
        )
        OR
        -- team member (including clients)
        p.team_id IN (
          SELECT team_id FROM public.team_members WHERE profile_id = auth.uid()
        )
    )
  );

CREATE POLICY "content: agency members and editors can create"
  ON public.content FOR INSERT
  TO authenticated
  WITH CHECK (
    project_id IN (
      SELECT p.id FROM public.projects p
      WHERE
        p.team_id IN (
          SELECT t.id FROM public.teams t
          WHERE t.org_id IN (SELECT public.get_member_org_ids(auth.uid()))
        )
        OR
        p.team_id IN (
          SELECT team_id FROM public.team_members
          WHERE profile_id = auth.uid() AND role IN ('manager', 'editor')
        )
    )
  );

CREATE POLICY "content: agency members and editors can update"
  ON public.content FOR UPDATE
  TO authenticated
  USING (
    project_id IN (
      SELECT p.id FROM public.projects p
      WHERE
        p.team_id IN (
          SELECT t.id FROM public.teams t
          WHERE t.org_id IN (SELECT public.get_member_org_ids(auth.uid()))
        )
        OR
        p.team_id IN (
          SELECT team_id FROM public.team_members
          WHERE profile_id = auth.uid() AND role IN ('manager', 'editor')
        )
    )
  );

CREATE POLICY "content: org owner/admin can delete non-published content"
  ON public.content FOR DELETE
  TO authenticated
  USING (
    status != 'published'
    AND
    project_id IN (
      SELECT p.id FROM public.projects p
      JOIN public.teams t ON t.id = p.team_id
      WHERE t.org_id IN (
        SELECT org_id FROM public.org_members
        WHERE profile_id = auth.uid() AND role IN ('owner', 'admin')
      )
    )
  );

-- Same read access as content. Immutable — no update or delete.

CREATE POLICY "content_versions: team members can read"
  ON public.content_versions FOR SELECT
  TO authenticated
  USING (
    content_id IN (
      SELECT id FROM public.content -- piggybacks on content RLS via subquery
      -- NOTE: this requires content RLS to be enforced first; works in Supabase
    )
  );

CREATE POLICY "content_versions: insert via trigger only"
  ON public.content_versions FOR INSERT
  TO authenticated
  WITH CHECK (false); -- versions are only inserted by the SECURITY DEFINER trigger

-- All team members (including clients) can read and post comments.
-- Authors can edit/delete their own comments. Managers can delete any.

CREATE POLICY "comments: team members can read"
  ON public.comments FOR SELECT
  TO authenticated
  USING (
    content_id IN (SELECT id FROM public.content)
  );

CREATE POLICY "comments: team members can insert"
  ON public.comments FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = author_id
    AND
    content_id IN (SELECT id FROM public.content)
  );

CREATE POLICY "comments: authors can update their own"
  ON public.comments FOR UPDATE
  TO authenticated
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "comments: authors and team managers can delete"
  ON public.comments FOR DELETE
  TO authenticated
  USING (
    auth.uid() = author_id
    OR
    -- team manager can delete any comment
    (
      SELECT p.team_id FROM public.projects p
      JOIN public.content c ON c.project_id = p.id
      WHERE c.id = content_id
    ) IN (
      SELECT team_id FROM public.team_members
      WHERE profile_id = auth.uid() AND role = 'manager'
    )
  );

-- Read-only for all team members. Written by server-side jobs only.

CREATE POLICY "analytics: team members can read"
  ON public.analytics FOR SELECT
  TO authenticated
  USING (
    content_id IN (SELECT id FROM public.content)
  );

CREATE POLICY "analytics: no direct insert from client"
  ON public.analytics FOR INSERT
  TO authenticated
  WITH CHECK (false); -- inserted via service_role from sync jobs only

-- Content queries
CREATE INDEX idx_content_project        ON public.content (project_id);
CREATE INDEX idx_content_status         ON public.content (status);
CREATE INDEX idx_content_platform       ON public.content (platform);

-- Versioning
CREATE INDEX idx_content_versions_content ON public.content_versions (content_id);

-- Comments
CREATE INDEX idx_comments_content       ON public.comments (content_id);
CREATE INDEX idx_comments_author        ON public.comments (author_id);
CREATE INDEX idx_comments_parent        ON public.comments (parent_id);

-- Analytics
CREATE INDEX idx_analytics_content      ON public.analytics (content_id);
CREATE INDEX idx_analytics_content_recorded ON public.analytics (content_id, recorded_at DESC);
