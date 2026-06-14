-- 1. Add is_private column to communities
ALTER TABLE public.communities ADD COLUMN is_private BOOLEAN NOT NULL DEFAULT false;

-- 2. Drop existing community policy
DROP POLICY IF EXISTS "Communities viewable by everyone" ON public.communities;

-- 3. Create community_invites table FIRST
CREATE TABLE public.community_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    invitee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(community_id, invitee_id)
);

ALTER TABLE public.community_invites ENABLE ROW LEVEL SECURITY;

-- 4. Add new policies for communities
-- Public communities are viewable by everyone
CREATE POLICY "Public communities viewable by everyone" ON public.communities
    FOR SELECT USING (is_private = false);

-- Private communities are viewable by creators, members, and invited users
CREATE POLICY "Private communities viewable by members and invited" ON public.communities
    FOR SELECT USING (
        is_private = true AND (
            creator_id = auth.uid() OR
            id IN (SELECT community_id FROM public.community_members WHERE user_id = auth.uid()) OR
            id IN (SELECT community_id FROM public.community_invites WHERE invitee_id = auth.uid())
        )
    );

-- 5. Add policies for community_invites

-- Invites: users can view invites sent to them, or invites they sent, or invites for communities they admin
CREATE POLICY "Users view relevant invites" ON public.community_invites
    FOR SELECT USING (
        invitee_id = auth.uid() OR 
        inviter_id = auth.uid() OR
        community_id IN (SELECT community_id FROM public.community_members WHERE user_id = auth.uid() AND role IN ('admin', 'moderator'))
    );

-- Invites: Admins/Moderators can insert invites
CREATE POLICY "Admins can invite" ON public.community_invites
    FOR INSERT TO authenticated WITH CHECK (
        inviter_id = auth.uid() AND
        community_id IN (SELECT community_id FROM public.community_members WHERE user_id = auth.uid() AND role IN ('admin', 'moderator'))
    );

-- Invites: Invitees can update (accept/decline)
CREATE POLICY "Invitees can update their invites" ON public.community_invites
    FOR UPDATE TO authenticated USING (invitee_id = auth.uid()) WITH CHECK (invitee_id = auth.uid());

-- Invites: Admins can delete invites
CREATE POLICY "Admins can delete invites" ON public.community_invites
    FOR DELETE TO authenticated USING (
        inviter_id = auth.uid() OR
        community_id IN (SELECT community_id FROM public.community_members WHERE user_id = auth.uid() AND role IN ('admin', 'moderator'))
    );
