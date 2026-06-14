-- ============================================================
-- Fix orphaned communities & prevent future ghost-name conflicts
-- ============================================================

-- 1. Delete orphaned communities whose creator no longer exists in profiles
DELETE FROM public.communities
WHERE creator_id NOT IN (SELECT id FROM public.profiles);

-- 2. Delete orphaned community_members whose user no longer exists
DELETE FROM public.community_members
WHERE user_id NOT IN (SELECT id FROM public.profiles);

-- 3. Delete orphaned community_invites where inviter or invitee no longer exists
DELETE FROM public.community_invites
WHERE inviter_id NOT IN (SELECT id FROM public.profiles)
   OR invitee_id NOT IN (SELECT id FROM public.profiles);

-- 4. Create an RPC function that checks community name availability
--    bypassing RLS so it sees ALL rows (including ones hidden from the current user).
--    SECURITY DEFINER runs as the function owner (postgres), not the calling user.
CREATE OR REPLACE FUNCTION public.is_community_name_taken(check_name TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.communities
    WHERE lower(name) = lower(check_name)
  );
$$;

-- 5. (Optional) If you want deleting a profile to auto-delete their communities,
--    drop and re-add the FK with ON DELETE CASCADE.
--    Uncomment the lines below if you want this behavior:
--
-- ALTER TABLE public.communities
--   DROP CONSTRAINT IF EXISTS communities_creator_id_fkey;
-- ALTER TABLE public.communities
--   ADD CONSTRAINT communities_creator_id_fkey
--   FOREIGN KEY (creator_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
