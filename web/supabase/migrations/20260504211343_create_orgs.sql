-- An organization (org) is a marketing agency (or solo freelancer).
-- The owner is the profile who created it.
-- We break the circular dependency by adding owner FK after profiles is created.

CREATE TABLE public.orgs (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name         text        NOT NULL,
  slug         text        NOT NULL UNIQUE,       -- URL-safe identifier e.g. "rembrand"
  logo_url     text,
  owner_id     uuid        NOT NULL,              -- FK added below after profiles
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_orgs_updated_at
  BEFORE UPDATE ON public.orgs
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- Now that profiles exists, we can add the FK from orgs → profiles
ALTER TABLE public.orgs
  ADD CONSTRAINT orgs_owner_id_fkey
  FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE RESTRICT;

-- Tracks which profiles belong to which organization, and their role.
--
-- Roles:
--   owner  — full control, can delete the org, cannot be removed
--   admin  — can manage members, teams, and all content
--   member — can create and edit content, cannot manage org settings

CREATE TYPE public.org_role AS ENUM ('owner', 'admin', 'member');

CREATE TABLE public.org_members (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id          uuid        NOT NULL REFERENCES public.orgs(id) ON DELETE CASCADE,
  profile_id      uuid        NOT NULL REFERENCES public.profiles(id)      ON DELETE CASCADE,
  role            org_role    NOT NULL DEFAULT 'member',
  invited_by      uuid        REFERENCES public.profiles(id) ON DELETE SET NULL,
  joined_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, profile_id)
);

-- When a new organization is created, automatically add the owner as a member
CREATE OR REPLACE FUNCTION public.handle_new_org()
RETURNS trigger
SET search_path = ''
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.org_members (org_id, profile_id, role)
  VALUES (NEW.id, NEW.owner_id, 'owner');
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_on_org_created
  AFTER INSERT ON public.orgs
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_org();

-- Helper: get all organization_ids a profile belongs to
CREATE OR REPLACE FUNCTION public.get_member_org_ids(p_profile_id uuid)
RETURNS SETOF uuid
SET search_path = ''
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT org_id
  FROM public.org_members
  WHERE profile_id = p_profile_id;
$$;

-- Helper: get a member's role in a specific org (returns null if not a member)
CREATE OR REPLACE FUNCTION public.get_org_role(p_profile_id uuid, p_org_id uuid)
RETURNS public.org_role
SET search_path = ''
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT role
  FROM public.org_members
  WHERE profile_id = p_profile_id
    AND org_id = p_org_id;
$$;

ALTER TABLE public.orgs         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.org_members  ENABLE ROW LEVEL SECURITY;

-- Readable by any member of the org.
-- Only owner/admin can update. Only owner can delete.

CREATE POLICY "orgs: members can read"
  ON public.orgs FOR SELECT
  TO authenticated
  USING (
    id IN (SELECT public.get_member_org_ids(auth.uid()))
  );

CREATE POLICY "orgs: authenticated users can create"
  ON public.orgs FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "orgs: owner and admin can update"
  ON public.orgs FOR UPDATE
  TO authenticated
  USING (
    public.get_org_role(auth.uid(), id) IN ('owner', 'admin')
  )
  WITH CHECK (
    public.get_org_role(auth.uid(), id) IN ('owner', 'admin')
  );

CREATE POLICY "orgs: only owner can delete"
  ON public.orgs FOR DELETE
  TO authenticated
  USING (
    public.get_org_role(auth.uid(), id) = 'owner'
  );

-- Members can see who else is in their org.
-- Owners/admins can add or remove members. Only owners can change roles.

CREATE POLICY "org_members: members can read their org's members"
  ON public.org_members FOR SELECT
  TO authenticated
  USING (
    org_id IN (SELECT public.get_member_org_ids(auth.uid()))
  );

CREATE POLICY "org_members: owner and admin can insert"
  ON public.org_members FOR INSERT
  TO authenticated
  WITH CHECK (
    public.get_org_role(auth.uid(), org_id) IN ('owner', 'admin')
  );

CREATE POLICY "org_members: only owner can update roles"
  ON public.org_members FOR UPDATE
  TO authenticated
  USING (
    public.get_org_role(auth.uid(), org_id) = 'owner'
  )
  WITH CHECK (
    public.get_org_role(auth.uid(), org_id) = 'owner'
    AND role != 'owner'
  );

CREATE POLICY "org_members: owner and admin can remove members"
  ON public.org_members FOR DELETE
  TO authenticated
  USING (
    public.get_org_role(auth.uid(), org_id) IN ('owner', 'admin')
    -- owners cannot be removed via this policy; enforce that in app logic
    AND role != 'owner'
  );

-- Membership lookups (used heavily in RLS helpers)
CREATE INDEX idx_org_members_profile    ON public.org_members (profile_id);
CREATE INDEX idx_org_members_org        ON public.org_members (org_id);