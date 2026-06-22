-- Make author_id nullable for truly anonymous posts
ALTER TABLE public.opinions ALTER COLUMN author_id DROP NOT NULL;
ALTER TABLE public.arguments ALTER COLUMN author_id DROP NOT NULL;

-- Update RLS for opinions
DROP POLICY IF EXISTS "Users can insert own opinions" ON public.opinions;
CREATE POLICY "Users can insert own opinions" ON public.opinions
    FOR INSERT TO authenticated WITH CHECK (
        (select auth.uid()) = author_id OR 
        (author_id IS NULL AND is_anonymous = true)
    );

-- Update RLS for arguments
DROP POLICY IF EXISTS "Users can insert own arguments" ON public.arguments;
CREATE POLICY "Users can insert own arguments" ON public.arguments
    FOR INSERT TO authenticated WITH CHECK (
        (select auth.uid()) = author_id OR 
        (author_id IS NULL AND is_anonymous = true)
    );
