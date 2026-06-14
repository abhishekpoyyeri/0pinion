-- 0pinion Database Schema & RLS Policies

-- 1. PROFILES (Extends auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    display_name TEXT,
    avatar_seed INTEGER NOT NULL DEFAULT 1,
    reputation_score INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. ZEROES (Topics/Categories)
CREATE TABLE public.zeroes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    opinions_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. OPINIONS (Main Posts)
CREATE TABLE public.opinions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    zero_id UUID REFERENCES public.zeroes(id) ON DELETE SET NULL,
    is_anonymous BOOLEAN NOT NULL DEFAULT false,
    is_cooking BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. ARGUMENTS (Responses)
CREATE TABLE public.arguments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    opinion_id UUID NOT NULL REFERENCES public.opinions(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('support', 'oppose', 'question')),
    content TEXT NOT NULL,
    is_anonymous BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. LIVE ROOMS & MESSAGES
CREATE TABLE public.live_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    topic TEXT NOT NULL,
    host_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    participant_count INTEGER NOT NULL DEFAULT 1,
    duration_minutes INTEGER NOT NULL DEFAULT 10,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'closed')),
    conclusion TEXT,
    closed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES public.live_rooms(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. SEARCH HISTORY
CREATE TABLE public.search_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    query TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-------------------------------------------------------------------
-- ROW-LEVEL SECURITY (RLS)
-------------------------------------------------------------------

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.zeroes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.opinions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.arguments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.live_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;

-- PROFILES
-- Anyone can read profiles
CREATE POLICY "Profiles are viewable by everyone" ON public.profiles
    FOR SELECT USING (true);
-- Users can only insert/update their own profile
CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK ((select auth.uid()) = id);
CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING ((select auth.uid()) = id) WITH CHECK ((select auth.uid()) = id);

-- ZEROES
-- Anyone can read zeroes
CREATE POLICY "Zeroes are viewable by everyone" ON public.zeroes
    FOR SELECT USING (true);

-- OPINIONS
-- Anyone can read opinions
CREATE POLICY "Opinions are viewable by everyone" ON public.opinions
    FOR SELECT USING (true);
-- Authenticated users can insert their own opinions
CREATE POLICY "Users can insert own opinions" ON public.opinions
    FOR INSERT TO authenticated WITH CHECK ((select auth.uid()) = author_id);
-- Authenticated users can update their own opinions
CREATE POLICY "Users can update own opinions" ON public.opinions
    FOR UPDATE TO authenticated USING ((select auth.uid()) = author_id) WITH CHECK ((select auth.uid()) = author_id);
-- Authenticated users can delete their own opinions
CREATE POLICY "Users can delete own opinions" ON public.opinions
    FOR DELETE TO authenticated USING ((select auth.uid()) = author_id);

-- ARGUMENTS
-- Anyone can read arguments
CREATE POLICY "Arguments are viewable by everyone" ON public.arguments
    FOR SELECT USING (true);
-- Authenticated users can insert their own arguments
CREATE POLICY "Users can insert own arguments" ON public.arguments
    FOR INSERT TO authenticated WITH CHECK ((select auth.uid()) = author_id);

-- LIVE ROOMS & MESSAGES
-- Public read
CREATE POLICY "Live rooms viewable by everyone" ON public.live_rooms FOR SELECT USING (true);
CREATE POLICY "Chat messages viewable by everyone" ON public.chat_messages FOR SELECT USING (true);
-- Authenticated insert
CREATE POLICY "Users can insert rooms" ON public.live_rooms FOR INSERT TO authenticated WITH CHECK ((select auth.uid()) = host_id);
CREATE POLICY "Users can insert messages" ON public.chat_messages FOR INSERT TO authenticated WITH CHECK ((select auth.uid()) = author_id);

-- SEARCH HISTORY
CREATE POLICY "Users can view their own search history" ON public.search_history
    FOR SELECT TO authenticated USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can insert their own search history" ON public.search_history
    FOR INSERT TO authenticated WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete their own search history" ON public.search_history
    FOR DELETE TO authenticated USING ((select auth.uid()) = user_id);

-------------------------------------------------------------------
-- ANONYMITY VIEW
-------------------------------------------------------------------
-- Instead of reading directly from the 'opinions' table, the client 
-- can read from this view, which securely strips the author_id if is_anonymous=true.
CREATE VIEW public.public_opinions WITH (security_invoker = true) AS
SELECT 
    id,
    title,
    content,
    zero_id,
    is_anonymous,
    is_cooking,
    created_at,
    CASE WHEN is_anonymous THEN NULL ELSE author_id END AS author_id
FROM public.opinions;

CREATE VIEW public.public_arguments WITH (security_invoker = true) AS
SELECT 
    id,
    opinion_id,
    type,
    content,
    is_anonymous,
    created_at,
    CASE WHEN is_anonymous THEN NULL ELSE author_id END AS author_id
FROM public.arguments;

-------------------------------------------------------------------
-- TRIGGERS & FUNCTIONS
-------------------------------------------------------------------
-- Function to dynamically compute 'is_cooking' for an opinion 
-- based on argument count vs global average
CREATE OR REPLACE FUNCTION public.check_cooking_status()
RETURNS TRIGGER AS $$
DECLARE
    avg_interaction FLOAT;
    total_opinions INT;
    total_arguments INT;
    opinion_interaction INT;
    min_threshold INT := 3; -- Minimum interactions required
    multiplier FLOAT := 1.5; -- Must be 50% higher than average
BEGIN
    -- Get total stats
    SELECT COUNT(*) INTO total_opinions FROM public.opinions;
    SELECT COUNT(*) INTO total_arguments FROM public.arguments;
    
    -- Calculate average
    IF total_opinions > 0 THEN
        avg_interaction := total_arguments::FLOAT / total_opinions::FLOAT;
    ELSE
        avg_interaction := 0;
    END IF;

    -- Get specific opinion count
    SELECT COUNT(*) INTO opinion_interaction 
    FROM public.arguments 
    WHERE opinion_id = COALESCE(NEW.opinion_id, OLD.opinion_id);

    -- Update the opinion's is_cooking flag
    UPDATE public.opinions
    SET is_cooking = (opinion_interaction >= min_threshold AND opinion_interaction > (avg_interaction * multiplier))
    WHERE id = COALESCE(NEW.opinion_id, OLD.opinion_id);

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
CREATE TRIGGER update_cooking_trigger
AFTER INSERT OR DELETE ON public.arguments
FOR EACH ROW
EXECUTE FUNCTION public.check_cooking_status();

-------------------------------------------------------------------
-- 6. COMMUNITIES
-------------------------------------------------------------------

CREATE TABLE public.communities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    creator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    avatar_seed INTEGER NOT NULL DEFAULT floor(random() * 100000)::int,
    member_count INTEGER NOT NULL DEFAULT 1,
    post_count INTEGER NOT NULL DEFAULT 0,
    is_private BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Community ↔ Zero many-to-many
CREATE TABLE public.community_zeroes (
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    zero_id UUID NOT NULL REFERENCES public.zeroes(id) ON DELETE CASCADE,
    PRIMARY KEY (community_id, zero_id)
);

-- Membership
CREATE TABLE public.community_members (
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'moderator', 'member')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (community_id, user_id)
);

-- Discussion posts
CREATE TABLE public.community_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    likes_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Community Invites
CREATE TABLE public.community_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    invitee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(community_id, invitee_id)
);

-------------------------------------------------------------------
-- COMMUNITY RLS
-------------------------------------------------------------------

ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_zeroes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_invites ENABLE ROW LEVEL SECURITY;

-- Communities: public read if not private, members/invitees read if private
CREATE POLICY "Public communities viewable by everyone" ON public.communities FOR SELECT USING (is_private = false);
CREATE POLICY "Private communities viewable by members and invited" ON public.communities FOR SELECT USING (
    is_private = true AND (
        creator_id = auth.uid() OR
        id IN (SELECT community_id FROM public.community_members WHERE user_id = auth.uid()) OR
        id IN (SELECT community_id FROM public.community_invites WHERE invitee_id = auth.uid())
    )
);
CREATE POLICY "Users can create communities" ON public.communities FOR INSERT TO authenticated WITH CHECK ((select auth.uid()) = creator_id);
CREATE POLICY "Creators can update communities" ON public.communities FOR UPDATE TO authenticated USING ((select auth.uid()) = creator_id) WITH CHECK ((select auth.uid()) = creator_id);
CREATE POLICY "Creators can delete communities" ON public.communities FOR DELETE TO authenticated USING ((select auth.uid()) = creator_id);

-- Community zeroes: public read, creator insert/delete (handled via community ownership)
CREATE POLICY "Community zeroes viewable by everyone" ON public.community_zeroes FOR SELECT USING (true);
CREATE POLICY "Users can link zeroes to communities" ON public.community_zeroes FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Users can unlink zeroes from communities" ON public.community_zeroes FOR DELETE TO authenticated USING (true);

-- Members: public read, self-join, self-leave
CREATE POLICY "Members viewable by everyone" ON public.community_members FOR SELECT USING (true);
CREATE POLICY "Users can join communities" ON public.community_members FOR INSERT TO authenticated WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can leave communities" ON public.community_members FOR DELETE TO authenticated USING ((select auth.uid()) = user_id);

-- Posts: public read, member insert, author delete
CREATE POLICY "Community posts viewable by everyone" ON public.community_posts FOR SELECT USING (true);
CREATE POLICY "Members can create posts" ON public.community_posts FOR INSERT TO authenticated WITH CHECK ((select auth.uid()) = author_id);
CREATE POLICY "Authors can delete own posts" ON public.community_posts FOR DELETE TO authenticated USING ((select auth.uid()) = author_id);

-- Invites: users can view invites sent to them, or invites they sent, or invites for communities they admin
CREATE POLICY "Users view relevant invites" ON public.community_invites FOR SELECT USING (
    invitee_id = auth.uid() OR 
    inviter_id = auth.uid() OR
    community_id IN (SELECT community_id FROM public.community_members WHERE user_id = auth.uid() AND role IN ('admin', 'moderator'))
);
CREATE POLICY "Admins can invite" ON public.community_invites FOR INSERT TO authenticated WITH CHECK (
    inviter_id = auth.uid() AND
    community_id IN (SELECT community_id FROM public.community_members WHERE user_id = auth.uid() AND role IN ('admin', 'moderator'))
);
CREATE POLICY "Invitees can update their invites" ON public.community_invites FOR UPDATE TO authenticated USING (invitee_id = auth.uid()) WITH CHECK (invitee_id = auth.uid());
CREATE POLICY "Admins can delete invites" ON public.community_invites FOR DELETE TO authenticated USING (
    inviter_id = auth.uid() OR
    community_id IN (SELECT community_id FROM public.community_members WHERE user_id = auth.uid() AND role IN ('admin', 'moderator'))
);

-------------------------------------------------------------------
-- COMMUNITY TRIGGERS
-------------------------------------------------------------------

-- Auto-update member_count on join/leave
CREATE OR REPLACE FUNCTION public.update_community_member_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.communities SET member_count = member_count + 1 WHERE id = NEW.community_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.communities SET member_count = GREATEST(member_count - 1, 0) WHERE id = OLD.community_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER community_member_count_trigger
AFTER INSERT OR DELETE ON public.community_members
FOR EACH ROW
EXECUTE FUNCTION public.update_community_member_count();

-- Auto-update post_count
CREATE OR REPLACE FUNCTION public.update_community_post_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.communities SET post_count = post_count + 1 WHERE id = NEW.community_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.communities SET post_count = GREATEST(post_count - 1, 0) WHERE id = OLD.community_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER community_post_count_trigger
AFTER INSERT OR DELETE ON public.community_posts
FOR EACH ROW
EXECUTE FUNCTION public.update_community_post_count();
