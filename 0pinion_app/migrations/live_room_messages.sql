-- ═══════════════════════════════════════════════════════════════
-- LIVE ROOM MESSAGES — Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- 1. Create the table
CREATE TABLE IF NOT EXISTS public.live_room_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES public.live_rooms(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Enable Row Level Security
ALTER TABLE public.live_room_messages ENABLE ROW LEVEL SECURITY;

-- 3. Policy: Anyone can read messages
CREATE POLICY "Anyone can read live room messages"
  ON public.live_room_messages
  FOR SELECT
  USING (true);

-- 4. Policy: Authenticated users can insert messages
CREATE POLICY "Authenticated users can insert messages"
  ON public.live_room_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = sender_id
  );

-- 5. Add index for faster querying by room and ordering by time
CREATE INDEX IF NOT EXISTS live_room_messages_room_id_created_at_idx 
  ON public.live_room_messages (room_id, created_at);
