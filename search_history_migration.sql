-- Migration to add search_history table

CREATE TABLE public.search_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    query TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own search history" ON public.search_history
    FOR SELECT TO authenticated USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert their own search history" ON public.search_history
    FOR INSERT TO authenticated WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can delete their own search history" ON public.search_history
    FOR DELETE TO authenticated USING ((select auth.uid()) = user_id);
