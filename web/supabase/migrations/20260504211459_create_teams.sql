-- A team represents one client inside an organization.
-- Example: "Crumbly" is a team inside the "Rembrand" organization.

CREATE TABLE public.teams (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id          uuid        NOT NULL REFERENCES public.orgs(id) ON DELETE CASCADE,
  name            text        NOT NULL,
  description     text,
  logo_url        text,
  created_by      uuid        REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, name)
);

CREATE TRIGGER trg_teams_updated_at
  BEFORE UPDATE ON public.teams
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Tracks who has access to a team and in what capacity.
--
-- Roles:
--   manager  — agency-side: full control of the team's content and settings
--   editor   — agency-side: can create and edit content, cannot approve
--   client   — client-side: can view, comment, and approve/reject content

CREATE TYPE public.team_role AS ENUM ('manager', 'editor', 'client');

CREATE TABLE public.team_members (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id    uuid        NOT NULL REFERENCES public.teams(id)    ON DELETE CASCADE,
  profile_id uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role       team_role   NOT NULL DEFAULT 'editor',
  invited_by uuid        REFERENCES public.profiles(id) ON DELETE SET NULL,
  joined_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (team_id, profile_id)
);

-- Helper: get a member's role in a specific team
CREATE OR REPLACE FUNCTION public.get_team_role(p_profile_id uuid, p_team_id uuid)
RETURNS public.team_role
SET search_path = ''
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  SELECT role
  FROM public.team_members
  WHERE profile_id = p_profile_id
    AND team_id = p_team_id;
$$;

-- A project is a content campaign or initiative within a team.
-- Example: "Summer Sale 2025" inside the "Crumbly" team.

CREATE TYPE public.project_status AS ENUM ('active', 'paused', 'completed', 'archived');

CREATE TABLE public.projects (
  id          uuid           PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id     uuid           NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  name        text           NOT NULL,
  description text,
  status      project_status NOT NULL DEFAULT 'active',
  created_by  uuid        REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_projects_updated_at
  BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.teams                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects              ENABLE ROW LEVEL SECURITY;

-- Readable by: org members AND team members (client users who aren't org members).
-- Writable by org owner/admin.

CREATE POLICY "teams: org members can read their org's teams"
  ON public.teams FOR SELECT
  TO authenticated
  USING (
    org_id IN (SELECT public.get_member_org_ids(auth.uid()))
    OR
    id IN (SELECT team_id FROM public.team_members WHERE profile_id = auth.uid())
  );

CREATE POLICY "teams: org owner and admin can create"
  ON public.teams FOR INSERT
  TO authenticated
  WITH CHECK (
    public.get_org_role(auth.uid(), org_id) IN ('owner', 'admin')
  );

CREATE POLICY "teams: org owner and admin can update"
  ON public.teams FOR UPDATE
  TO authenticated
  USING (
    public.get_org_role(auth.uid(), org_id) IN ('owner', 'admin')
  )
  WITH CHECK (
    public.get_org_role(auth.uid(), org_id) IN ('owner', 'admin')
  );

CREATE POLICY "teams: org owner and admin can delete"
  ON public.teams FOR DELETE
  TO authenticated
  USING (
    public.get_org_role(auth.uid(), org_id) IN ('owner', 'admin')
  );

-- Readable by: org members of the parent org, or existing team members.
-- Manageable by: org owner/admin, or team managers.

CREATE POLICY "team_members: org members and team members can read"
  ON public.team_members FOR SELECT
  TO authenticated
  USING (
    -- is an org member
    team_id IN (
      SELECT t.id FROM public.teams t
      WHERE t.org_id IN (SELECT public.get_member_org_ids(auth.uid()))
    )
    OR
    -- is already on this team
    profile_id = auth.uid()
  );

CREATE POLICY "team_members: org owner/admin or team manager can insert"
  ON public.team_members FOR INSERT
  TO authenticated
  WITH CHECK (
    -- org-level permission
    (SELECT org_id FROM public.teams WHERE id = team_id)
      IN (
        SELECT org_id FROM public.org_members
        WHERE profile_id = auth.uid()
          AND role IN ('owner', 'admin')
      )
    OR
    -- team-level permission
    public.get_team_role(auth.uid(), team_id) = 'manager'
  );

CREATE POLICY "team_members: org owner/admin or team manager can delete"
  ON public.team_members FOR DELETE
  TO authenticated
  USING (
    (SELECT org_id FROM public.teams WHERE id = team_id)
      IN (
        SELECT org_id FROM public.org_members
        WHERE profile_id = auth.uid()
          AND role IN ('owner', 'admin')
      )
    OR
    public.get_team_role(auth.uid(), team_id) = 'manager'
  );

-- Readable by org members and team members.
-- Writable by agency-side (org members + team manager/editor), not by clients.

CREATE POLICY "projects: org members and team members can read"
  ON public.projects FOR SELECT
  TO authenticated
  USING (
    team_id IN (
      -- org members see all teams in their org
      SELECT t.id FROM public.teams t
      WHERE t.org_id IN (SELECT public.get_member_org_ids(auth.uid()))
    )
    OR
    -- direct team members (including client role)
    team_id IN (
      SELECT team_id FROM public.team_members WHERE profile_id = auth.uid()
    )
  );

CREATE POLICY "projects: agency members can create"
  ON public.projects FOR INSERT
  TO authenticated
  WITH CHECK (
    -- must be an org member (not a pure client user)
    (SELECT org_id FROM public.teams WHERE id = team_id)
      IN (SELECT public.get_member_org_ids(auth.uid()))
    OR
    -- or a team manager or editor
    public.get_team_role(auth.uid(), team_id) IN ('manager', 'editor')
  );

CREATE POLICY "projects: agency members can update"
  ON public.projects FOR UPDATE
  TO authenticated
  USING (
    (SELECT org_id FROM public.teams WHERE id = team_id)
      IN (SELECT public.get_member_org_ids(auth.uid()))
    OR
    public.get_team_role(auth.uid(), team_id) IN ('manager', 'editor')
  )
  WITH CHECK (
    (SELECT org_id FROM public.teams WHERE id = team_id)
      IN (SELECT public.get_member_org_ids(auth.uid()))
    OR
    public.get_team_role(auth.uid(), team_id) IN ('manager', 'editor')
  );

CREATE POLICY "projects: org owner/admin or team manager can delete"
  ON public.projects FOR DELETE
  TO authenticated
  USING (
    (SELECT org_id FROM public.teams WHERE id = team_id)
      IN (
        SELECT org_id FROM public.org_members
        WHERE profile_id = auth.uid()
          AND role IN ('owner', 'admin')
      )
    OR
    public.get_team_role(auth.uid(), team_id) = 'manager'
  );

-- Indexes
CREATE INDEX idx_teams_org              ON public.teams (org_id);
CREATE INDEX idx_projects_team          ON public.projects (team_id);
CREATE INDEX idx_team_members_profile   ON public.team_members (profile_id);
CREATE INDEX idx_team_members_team      ON public.team_members (team_id);