-- Add RLS policy to allow users to delete their own arguments
CREATE POLICY "Users can delete own arguments" ON public.arguments
    FOR DELETE TO authenticated USING ((select auth.uid()) = author_id);
