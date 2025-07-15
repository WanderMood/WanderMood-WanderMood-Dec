-- Create scheduled_activities table for storing user's planned activities
CREATE TABLE IF NOT EXISTS public.scheduled_activities (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    activity_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER NOT NULL,
    location_name TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_confirmed BOOLEAN DEFAULT FALSE,
    tags TEXT,
    payment_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, activity_id)
);

-- Add foreign key constraint
ALTER TABLE public.scheduled_activities
ADD CONSTRAINT scheduled_activities_user_id_fkey
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create indexes for better performance
CREATE INDEX scheduled_activities_user_id_idx ON public.scheduled_activities(user_id);
CREATE INDEX scheduled_activities_start_time_idx ON public.scheduled_activities(start_time);
CREATE INDEX scheduled_activities_user_date_idx ON public.scheduled_activities(user_id, start_time);

-- Enable Row Level Security
ALTER TABLE public.scheduled_activities ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own scheduled activities"
ON public.scheduled_activities FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own scheduled activities"
ON public.scheduled_activities FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own scheduled activities"
ON public.scheduled_activities FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own scheduled activities"
ON public.scheduled_activities FOR DELETE
USING (auth.uid() = user_id); 