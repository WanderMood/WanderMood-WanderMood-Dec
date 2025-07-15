-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User profiles (extends auth.users)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    username TEXT UNIQUE,
    bio TEXT,
    location TEXT,
    timezone TEXT,
    language TEXT DEFAULT 'en',
    notification_preferences JSONB DEFAULT '{"email": true, "push": true}'::jsonb,
    last_active_at TIMESTAMP WITH TIME ZONE,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Add updated_at trigger
CREATE TRIGGER handle_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

-- User roles and permissions
CREATE TABLE public.user_roles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'user',
    permissions JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_role CHECK (role IN ('user', 'admin', 'moderator')),
    UNIQUE(user_id, role)
);

-- Add updated_at trigger
CREATE TRIGGER handle_user_roles_updated_at
    BEFORE UPDATE ON public.user_roles
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

-- User sessions tracking
CREATE TABLE public.user_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_token TEXT UNIQUE NOT NULL,
    device_info JSONB DEFAULT '{}'::jsonb,
    ip_address TEXT,
    user_agent TEXT,
    is_valid BOOLEAN DEFAULT true,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT session_not_expired CHECK (expires_at > NOW())
);

-- Add updated_at trigger
CREATE TRIGGER handle_user_sessions_updated_at
    BEFORE UPDATE ON public.user_sessions
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

-- Add RLS policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone"
    ON public.profiles
    FOR SELECT
    USING (true);

CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Roles policies
CREATE POLICY "Users can view own roles"
    ON public.user_roles
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Only admins can manage roles"
    ON public.user_roles
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles
            WHERE user_id = auth.uid()
            AND role = 'admin'
        )
    );

-- Sessions policies
CREATE POLICY "Users can view own sessions"
    ON public.user_sessions
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can invalidate own sessions"
    ON public.user_sessions
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Create function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, avatar_url, username)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url',
        NEW.raw_user_meta_data->>'username'
    );

    -- Create default user role
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'user');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger the function every time a user is created
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Create function to clean up expired sessions
CREATE OR REPLACE FUNCTION public.cleanup_expired_sessions()
RETURNS void AS $$
BEGIN
    DELETE FROM public.user_sessions
    WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a scheduled job to clean up expired sessions (runs daily)
SELECT cron.schedule(
    'cleanup_expired_sessions',
    '0 0 * * *',  -- Run at midnight every day
    'SELECT public.cleanup_expired_sessions();'
); 