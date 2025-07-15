-- Create mood stats function
CREATE OR REPLACE FUNCTION get_mood_stats(start_date TIMESTAMPTZ DEFAULT NULL, end_date TIMESTAMPTZ DEFAULT NULL)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSON;
BEGIN
    WITH mood_stats AS (
        SELECT 
            COUNT(*) as total_moods,
            AVG(CAST(energy_level AS FLOAT)) as avg_energy,
            MODE() WITHIN GROUP (ORDER BY label) as most_common_mood,
            COUNT(DISTINCT DATE(created_at)) as active_days,
            jsonb_agg(DISTINCT activities) as all_activities
        FROM moods
        WHERE auth.uid() = user_id
            AND (start_date IS NULL OR created_at >= start_date)
            AND (end_date IS NULL OR created_at <= end_date)
    ),
    activity_stats AS (
        SELECT 
            activities.value as activity_id,
            COUNT(*) as usage_count
        FROM moods,
        jsonb_array_elements(activities) as activities
        WHERE auth.uid() = user_id
            AND (start_date IS NULL OR created_at >= start_date)
            AND (end_date IS NULL OR created_at <= end_date)
        GROUP BY activities.value
        ORDER BY usage_count DESC
        LIMIT 5
    )
    SELECT 
        json_build_object(
            'total_moods', ms.total_moods,
            'avg_energy', ms.avg_energy,
            'most_common_mood', ms.most_common_mood,
            'active_days', ms.active_days,
            'top_activities', (
                SELECT json_agg(
                    json_build_object(
                        'activity_id', ast.activity_id,
                        'usage_count', ast.usage_count
                    )
                )
                FROM activity_stats ast
            )
        ) INTO result
    FROM mood_stats ms;

    RETURN result;
END;
$$; 