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

-------------------------------------------------------------------
-- ROW-LEVEL SECURITY (RLS)
-------------------------------------------------------------------

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.zeroes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.opinions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.arguments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.live_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

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
