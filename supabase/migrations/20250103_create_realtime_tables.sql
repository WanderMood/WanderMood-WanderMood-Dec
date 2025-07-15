-- Create realtime events table for notifications and live updates
CREATE TABLE IF NOT EXISTS realtime_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL CHECK (type IN (
        'postLike', 'postComment', 'postShare', 'newFollower',
        'weatherAlert', 'placeRecommendation', 
        'welcomeMessage', 'achievementUnlocked',
        'liveLocationUpdate', 'groupTravelUpdate',
        'emergencyAlert', 'travelAdvisory'
    )),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB NOT NULL DEFAULT '{}',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    image_url TEXT,
    action_url TEXT,
    related_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    related_post_id UUID REFERENCES diary_entries(id) ON DELETE SET NULL,
    priority INTEGER DEFAULT 0,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create notification settings table
CREATE TABLE IF NOT EXISTS notification_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    push_notifications BOOLEAN NOT NULL DEFAULT TRUE,
    in_app_notifications BOOLEAN NOT NULL DEFAULT TRUE,
    email_notifications BOOLEAN NOT NULL DEFAULT TRUE,
    social_interactions BOOLEAN NOT NULL DEFAULT TRUE,
    travel_updates BOOLEAN NOT NULL DEFAULT TRUE,
    weather_alerts BOOLEAN NOT NULL DEFAULT TRUE,
    emergency_alerts BOOLEAN NOT NULL DEFAULT TRUE,
    quiet_hours BOOLEAN NOT NULL DEFAULT FALSE,
    quiet_start_hour INTEGER NOT NULL DEFAULT 22 CHECK (quiet_start_hour >= 0 AND quiet_start_hour <= 23),
    quiet_end_hour INTEGER NOT NULL DEFAULT 7 CHECK (quiet_end_hour >= 0 AND quiet_end_hour <= 23),
    muted_users JSONB NOT NULL DEFAULT '[]',
    muted_event_types JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create live updates table for real-time synchronization
CREATE TABLE IF NOT EXISTS live_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name TEXT NOT NULL,
    update_type TEXT NOT NULL CHECK (update_type IN ('insert', 'update', 'delete')),
    record_data JSONB NOT NULL,
    old_record_data JSONB,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed BOOLEAN NOT NULL DEFAULT FALSE
);

-- Create user presence table for live location and activity tracking
CREATE TABLE IF NOT EXISTS user_presence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    is_online BOOLEAN NOT NULL DEFAULT FALSE,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    current_location JSONB,
    activity_status TEXT DEFAULT 'offline' CHECK (activity_status IN ('online', 'away', 'busy', 'offline', 'traveling')),
    is_sharing_location BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on all tables
ALTER TABLE realtime_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_presence ENABLE ROW LEVEL SECURITY;

-- RLS policies for realtime_events
CREATE POLICY "Users can view own events" ON realtime_events
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own events" ON realtime_events
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can insert events" ON realtime_events
    FOR INSERT WITH CHECK (true); -- Allow system to create events for any user

-- RLS policies for notification_settings
CREATE POLICY "Users can manage own notification settings" ON notification_settings
    FOR ALL USING (auth.uid() = user_id);

-- RLS policies for live_updates
CREATE POLICY "Users can view relevant updates" ON live_updates
    FOR SELECT USING (
        auth.uid() = user_id OR 
        record_data->>'user_id' = auth.uid()::text OR
        old_record_data->>'user_id' = auth.uid()::text
    );

CREATE POLICY "System can manage live updates" ON live_updates
    FOR ALL USING (true); -- Allow system to manage updates

-- RLS policies for user_presence
CREATE POLICY "Users can view all presence data" ON user_presence
    FOR SELECT USING (true); -- Public read for social features

CREATE POLICY "Users can update own presence" ON user_presence
    FOR ALL USING (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX idx_realtime_events_user_id ON realtime_events(user_id);
CREATE INDEX idx_realtime_events_timestamp ON realtime_events(timestamp DESC);
CREATE INDEX idx_realtime_events_type ON realtime_events(type);
CREATE INDEX idx_realtime_events_is_read ON realtime_events(is_read);
CREATE INDEX idx_realtime_events_priority ON realtime_events(priority DESC);

CREATE INDEX idx_notification_settings_user_id ON notification_settings(user_id);

CREATE INDEX idx_live_updates_table_name ON live_updates(table_name);
CREATE INDEX idx_live_updates_timestamp ON live_updates(timestamp DESC);
CREATE INDEX idx_live_updates_processed ON live_updates(processed);

CREATE INDEX idx_user_presence_user_id ON user_presence(user_id);
CREATE INDEX idx_user_presence_is_online ON user_presence(is_online);
CREATE INDEX idx_user_presence_last_seen ON user_presence(last_seen DESC);

-- Create triggers for updated_at
CREATE TRIGGER update_realtime_events_updated_at
    BEFORE UPDATE ON realtime_events
    FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER update_notification_settings_updated_at
    BEFORE UPDATE ON notification_settings
    FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER update_user_presence_updated_at
    BEFORE UPDATE ON user_presence
    FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- Create function to send realtime notifications
CREATE OR REPLACE FUNCTION send_realtime_notification(
    target_user_id UUID,
    event_type TEXT,
    event_title TEXT,
    event_message TEXT,
    event_data JSONB DEFAULT '{}',
    source_user_id UUID DEFAULT NULL,
    related_post_id UUID DEFAULT NULL,
    priority_level INTEGER DEFAULT 0
)
RETURNS UUID AS $$
DECLARE
    event_id UUID;
    settings notification_settings%ROWTYPE;
BEGIN
    -- Get user notification settings
    SELECT * INTO settings 
    FROM notification_settings 
    WHERE user_id = target_user_id;
    
    -- If no settings exist, create default ones
    IF NOT FOUND THEN
        INSERT INTO notification_settings (user_id) 
        VALUES (target_user_id)
        RETURNING * INTO settings;
    END IF;
    
    -- Check if notifications are enabled for this event type
    IF NOT settings.in_app_notifications THEN
        RETURN NULL;
    END IF;
    
    -- Create the realtime event
    INSERT INTO realtime_events (
        user_id, type, title, message, data, 
        related_user_id, related_post_id, priority
    ) VALUES (
        target_user_id, event_type, event_title, event_message, event_data,
        source_user_id, related_post_id, priority_level
    ) RETURNING id INTO event_id;
    
    -- Send realtime update via Supabase Realtime
    PERFORM pg_notify(
        'realtime_event',
        json_build_object(
            'user_id', target_user_id,
            'event_id', event_id,
            'type', event_type,
            'title', event_title,
            'message', event_message
        )::text
    );
    
    RETURN event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to mark events as read
CREATE OR REPLACE FUNCTION mark_events_as_read(event_ids UUID[])
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE realtime_events 
    SET is_read = TRUE, updated_at = NOW()
    WHERE id = ANY(event_ids) 
    AND user_id = auth.uid()
    AND is_read = FALSE;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to clean up old events
CREATE OR REPLACE FUNCTION cleanup_old_events()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete read events older than 30 days
    DELETE FROM realtime_events 
    WHERE is_read = TRUE 
    AND timestamp < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Delete unread events older than 90 days (except high priority)
    DELETE FROM realtime_events 
    WHERE is_read = FALSE 
    AND timestamp < NOW() - INTERVAL '90 days'
    AND priority < 3;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Create function to update user presence
CREATE OR REPLACE FUNCTION update_user_presence(
    activity_status TEXT DEFAULT 'online',
    location_data JSONB DEFAULT NULL,
    share_location BOOLEAN DEFAULT FALSE
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO user_presence (
        user_id, is_online, last_seen, activity_status, 
        current_location, is_sharing_location
    ) VALUES (
        auth.uid(), TRUE, NOW(), activity_status, 
        location_data, share_location
    ) ON CONFLICT (user_id) DO UPDATE SET
        is_online = TRUE,
        last_seen = NOW(),
        activity_status = EXCLUDED.activity_status,
        current_location = COALESCE(EXCLUDED.current_location, user_presence.current_location),
        is_sharing_location = EXCLUDED.is_sharing_location,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to handle diary interactions (likes, comments, etc.)
CREATE OR REPLACE FUNCTION handle_diary_interaction()
RETURNS TRIGGER AS $$
DECLARE
    post_author_id UUID;
    event_type TEXT;
    event_title TEXT;
    event_message TEXT;
    actor_name TEXT;
BEGIN
    -- Get post author and actor information
    SELECT user_id INTO post_author_id 
    FROM diary_entries 
    WHERE id = NEW.diary_entry_id;
    
    SELECT full_name INTO actor_name 
    FROM profiles 
    WHERE id = auth.uid();
    
    -- Don't notify users of their own actions
    IF post_author_id = auth.uid() THEN
        RETURN NEW;
    END IF;
    
    -- Determine event type based on table
    IF TG_TABLE_NAME = 'diary_likes' THEN
        event_type := 'postLike';
        event_title := 'Post Liked';
        event_message := actor_name || ' liked your diary entry';
    ELSIF TG_TABLE_NAME = 'diary_comments' THEN
        event_type := 'postComment';
        event_title := 'New Comment';
        event_message := actor_name || ' commented on your diary entry';
    END IF;
    
    -- Send notification
    PERFORM send_realtime_notification(
        post_author_id,
        event_type,
        event_title,
        event_message,
        json_build_object(
            'userName', actor_name,
            'postId', NEW.diary_entry_id,
            'actorId', auth.uid()
        )::jsonb,
        auth.uid(),
        NEW.diary_entry_id,
        2
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers for diary interactions
CREATE TRIGGER trigger_diary_like_notification
    AFTER INSERT ON diary_likes
    FOR EACH ROW EXECUTE FUNCTION handle_diary_interaction();

CREATE TRIGGER trigger_diary_comment_notification
    AFTER INSERT ON diary_comments
    FOR EACH ROW EXECUTE FUNCTION handle_diary_interaction();

-- Enable realtime for all tables
ALTER TABLE realtime_events REPLICA IDENTITY FULL;
ALTER TABLE notification_settings REPLICA IDENTITY FULL;
ALTER TABLE user_presence REPLICA IDENTITY FULL;
ALTER TABLE live_updates REPLICA IDENTITY FULL;

-- Comments for documentation
COMMENT ON TABLE realtime_events IS 'Real-time events and notifications for users';
COMMENT ON TABLE notification_settings IS 'User notification preferences and settings';
COMMENT ON TABLE live_updates IS 'Live database updates for real-time synchronization';
COMMENT ON TABLE user_presence IS 'User online status and location tracking';
COMMENT ON FUNCTION send_realtime_notification IS 'Send real-time notification to a user';
COMMENT ON FUNCTION cleanup_old_events IS 'Clean up old notification events';
COMMENT ON FUNCTION update_user_presence IS 'Update user online status and location'; 