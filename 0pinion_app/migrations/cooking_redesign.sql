-- ═══════════════════════════════════════════════════════════════
-- COOKING REDESIGN — Run this in Supabase SQL Editor
-- Migrates from average-based is_cooking flag to client-side
-- time-decay scoring. Run ONCE.
-- ═══════════════════════════════════════════════════════════════

-- 1. Drop the old trigger that fires on argument insert/delete
DROP TRIGGER IF EXISTS update_cooking_trigger ON public.arguments;

-- 2. Drop the old function
DROP FUNCTION IF EXISTS public.check_cooking_status();

-- 3. Drop the view FIRST (it depends on is_cooking column)
DROP VIEW IF EXISTS public.public_opinions;

-- 4. Now drop the is_cooking column from opinions
ALTER TABLE public.opinions DROP COLUMN IF EXISTS is_cooking;

-- 5. Recreate the public_opinions view without is_cooking
CREATE VIEW public.public_opinions WITH (security_invoker = true) AS
SELECT 
    id,
    title,
    content,
    zero_id,
    is_anonymous,
    created_at,
    CASE WHEN is_anonymous THEN NULL ELSE author_id END AS author_id
FROM public.opinions;

-- 6. Prevent duplicate interactions: one support, one oppose, one question per user per opinion
ALTER TABLE public.arguments
  ADD CONSTRAINT arguments_unique_user_opinion_type
  UNIQUE (opinion_id, author_id, type);
