-- ═══════════════════════════════════════════════════════════════
-- LIVE ROOMS UPGRADE — Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- 1. Add new columns to live_rooms
ALTER TABLE public.live_rooms
  ADD COLUMN IF NOT EXISTS duration_minutes INTEGER NOT NULL DEFAULT 10,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS conclusion TEXT,
  ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ;

-- 2. Add check constraint for status
ALTER TABLE public.live_rooms
  ADD CONSTRAINT live_rooms_status_check CHECK (status IN ('active', 'closed'));

-- 3. RLS: Host can update own rooms (to close them)
CREATE POLICY "Host can update own rooms" ON public.live_rooms
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = host_id)
  WITH CHECK ((select auth.uid()) = host_id);

-- 4. RLS: Host can delete own rooms
CREATE POLICY "Host can delete own rooms" ON public.live_rooms
  FOR DELETE TO authenticated
  USING ((select auth.uid()) = host_id);

-- 5. Authenticated users can insert zeroes (for auto-create from opinion content)
CREATE POLICY "Authenticated users can insert zeroes" ON public.zeroes
  FOR INSERT TO authenticated WITH CHECK (true);
