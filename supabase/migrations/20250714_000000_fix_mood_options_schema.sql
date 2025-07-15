-- Fix mood_options table schema to match MoodOption model
-- The app expects 'label' and 'color_hex' fields, not 'name' and 'color'

-- Drop existing mood_options table if it exists
DROP TABLE IF EXISTS public.mood_options CASCADE;

-- Create mood_options table with correct schema
CREATE TABLE public.mood_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    label TEXT NOT NULL,
    emoji TEXT NOT NULL,
    color_hex TEXT DEFAULT '#3B82F6',
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert sample mood options data
INSERT INTO public.mood_options (label, emoji, color_hex, display_order, is_active) VALUES
('Happy', '😊', '#FFD700', 1, true),
('Adventurous', '🚀', '#FF6B6B', 2, true),
('Relaxed', '😌', '#4ECDC4', 3, true),
('Energetic', '⚡', '#45B7D1', 4, true),
('Contemplative', '🤔', '#96CEB4', 5, true),
('Social', '👥', '#FFEAA7', 6, true),
('Romantic', '💕', '#FD79A8', 7, true),
('Cultural', '🎭', '#A29BFE', 8, true),
('Curious', '🔍', '#FF7675', 9, true),
('Peaceful', '🕊️', '#81ECEC', 10, true);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_mood_options_display_order ON public.mood_options(display_order);
CREATE INDEX IF NOT EXISTS idx_mood_options_active ON public.mood_options(is_active);

-- Enable RLS
ALTER TABLE public.mood_options ENABLE ROW LEVEL SECURITY;

-- Create policy for reading mood options (public read access)
CREATE POLICY "Allow public read access to mood options" ON public.mood_options
    FOR SELECT USING (true);

-- Success message
SELECT '🎉 mood_options table fixed with correct schema!' as status; 