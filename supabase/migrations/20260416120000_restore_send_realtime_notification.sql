-- Restore tables + RPC used by Mood Match in-app invite (GroupPlanningRepository.sendMoodMatchInAppInvite).
-- 20260406215838_sync_remote_schema_v83.sql dropped realtime_events, notification_settings,
-- and send_realtime_notification without recreating them.

-- ---------------------------------------------------------------------------
-- notification_settings
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notification_settings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL UNIQUE REFERENCES auth.users (id) ON DELETE CASCADE,
    push_notifications boolean NOT NULL DEFAULT true,
    in_app_notifications boolean NOT NULL DEFAULT true,
    email_notifications boolean NOT NULL DEFAULT true,
    social_interactions boolean NOT NULL DEFAULT true,
    travel_updates boolean NOT NULL DEFAULT true,
    weather_alerts boolean NOT NULL DEFAULT true,
    emergency_alerts boolean NOT NULL DEFAULT true,
    quiet_hours boolean NOT NULL DEFAULT false,
    quiet_start_hour integer NOT NULL DEFAULT 22 CHECK (quiet_start_hour >= 0 AND quiet_start_hour <= 23),
    quiet_end_hour integer NOT NULL DEFAULT 7 CHECK (quiet_end_hour >= 0 AND quiet_end_hour <= 23),
    muted_users jsonb NOT NULL DEFAULT '[]'::jsonb,
    muted_event_types jsonb NOT NULL DEFAULT '[]'::jsonb,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notification_settings_user_id ON public.notification_settings (user_id);

ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own notification settings" ON public.notification_settings;
CREATE POLICY "Users can manage own notification settings" ON public.notification_settings
    FOR ALL USING (auth.uid() = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.notification_settings TO authenticated;

-- ---------------------------------------------------------------------------
-- realtime_events
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.realtime_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
    type text NOT NULL,
    title text NOT NULL,
    message text NOT NULL,
    data jsonb NOT NULL DEFAULT '{}'::jsonb,
    is_read boolean NOT NULL DEFAULT false,
    image_url text,
    action_url text,
    related_user_id uuid REFERENCES auth.users (id) ON DELETE SET NULL,
    related_post_id uuid,
    priority integer DEFAULT 0,
    "timestamp" timestamptz DEFAULT now(),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    CONSTRAINT realtime_events_type_check CHECK (
        type = ANY (
            ARRAY[
                'postLike'::text,
                'postComment'::text,
                'postShare'::text,
                'newFollower'::text,
                'weatherAlert'::text,
                'placeRecommendation'::text,
                'welcomeMessage'::text,
                'achievementUnlocked'::text,
                'liveLocationUpdate'::text,
                'groupTravelUpdate'::text,
                'emergencyAlert'::text,
                'travelAdvisory'::text
            ]
        )
    )
);

CREATE INDEX IF NOT EXISTS idx_realtime_events_user_id ON public.realtime_events (user_id);
CREATE INDEX IF NOT EXISTS idx_realtime_events_timestamp ON public.realtime_events ("timestamp" DESC);
CREATE INDEX IF NOT EXISTS idx_realtime_events_type ON public.realtime_events (type);
CREATE INDEX IF NOT EXISTS idx_realtime_events_is_read ON public.realtime_events (is_read);
CREATE INDEX IF NOT EXISTS idx_realtime_events_priority ON public.realtime_events (priority DESC);

ALTER TABLE public.realtime_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own events" ON public.realtime_events;
CREATE POLICY "Users can view own events" ON public.realtime_events
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own events" ON public.realtime_events;
CREATE POLICY "Users can update own events" ON public.realtime_events
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert events" ON public.realtime_events;
CREATE POLICY "System can insert events" ON public.realtime_events
    FOR INSERT WITH CHECK (true);

GRANT SELECT, UPDATE ON public.realtime_events TO authenticated;

-- ---------------------------------------------------------------------------
-- RPC: insert row + pg_notify (SECURITY DEFINER bypasses RLS on insert)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.send_realtime_notification(
    target_user_id uuid,
    event_type text,
    event_title text,
    event_message text,
    event_data jsonb DEFAULT '{}'::jsonb,
    source_user_id uuid DEFAULT NULL::uuid,
    related_post_id uuid DEFAULT NULL::uuid,
    priority_level integer DEFAULT 0
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
    event_id uuid;
    settings_row public.notification_settings%ROWTYPE;
BEGIN
    SELECT * INTO settings_row
    FROM public.notification_settings
    WHERE user_id = target_user_id;

    IF NOT FOUND THEN
        INSERT INTO public.notification_settings (user_id)
        VALUES (target_user_id)
        RETURNING * INTO settings_row;
    END IF;

    IF NOT settings_row.in_app_notifications THEN
        RETURN NULL;
    END IF;

    INSERT INTO public.realtime_events (
        user_id,
        type,
        title,
        message,
        data,
        related_user_id,
        related_post_id,
        priority
    )
    VALUES (
        target_user_id,
        event_type,
        event_title,
        event_message,
        event_data,
        source_user_id,
        related_post_id,
        priority_level
    )
    RETURNING id INTO event_id;

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
$function$;

COMMENT ON FUNCTION public.send_realtime_notification IS 'Insert realtime_events row + notify; used by Mood Match in-app invite.';

GRANT EXECUTE ON FUNCTION public.send_realtime_notification(
    uuid, text, text, text, jsonb, uuid, uuid, integer
) TO authenticated, service_role;
