-- Create user_check_ins table for storing check-in history
CREATE TABLE IF NOT EXISTS public.user_check_ins (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL,
    mood TEXT,
    activities TEXT[] DEFAULT '{}',
    reactions TEXT[] DEFAULT '{}',
    text TEXT,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add foreign key constraint
ALTER TABLE public.user_check_ins
ADD CONSTRAINT user_check_ins_user_id_fkey
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create indexes for better performance
CREATE INDEX user_check_ins_user_id_idx ON public.user_check_ins(user_id);
CREATE INDEX user_check_ins_timestamp_idx ON public.user_check_ins(timestamp);
CREATE INDEX user_check_ins_user_timestamp_idx ON public.user_check_ins(user_id, timestamp DESC);

-- Enable Row Level Security
ALTER TABLE public.user_check_ins ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own check-ins"
ON public.user_check_ins FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own check-ins"
ON public.user_check_ins FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own check-ins"
ON public.user_check_ins FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own check-ins"
ON public.user_check_ins FOR DELETE
USING (auth.uid() = user_id);


