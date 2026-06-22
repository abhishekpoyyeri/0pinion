-- Rename duration_minutes to duration_seconds and convert existing data
ALTER TABLE public.live_rooms
  RENAME COLUMN duration_minutes TO duration_seconds;

-- Multiply existing minute values by 60 to convert them to seconds
UPDATE public.live_rooms
SET duration_seconds = duration_seconds * 60
WHERE duration_seconds IS NOT NULL;
