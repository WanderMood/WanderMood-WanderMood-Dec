drop extension if exists "pg_net";

drop trigger if exists "update_account_security_updated_at" on "public"."account_security";

drop trigger if exists "trigger_update_patterns_on_rating" on "public"."activity_ratings";

drop trigger if exists "set_timestamp_diary_comments" on "public"."diary_comments";

drop trigger if exists "trigger_diary_comment_notification" on "public"."diary_comments";

drop trigger if exists "set_timestamp_diary_entries" on "public"."diary_entries";

drop trigger if exists "trigger_diary_like_notification" on "public"."diary_likes";

drop trigger if exists "update_notification_settings_updated_at" on "public"."notification_settings";

drop trigger if exists "update_places_cache_updated_at" on "public"."places_cache";

drop trigger if exists "update_profile_timestamps" on "public"."profiles";

drop trigger if exists "update_realtime_events_updated_at" on "public"."realtime_events";

drop trigger if exists "update_user_presence_updated_at" on "public"."user_presence";

drop policy "Users can manage own security" on "public"."account_security";

drop policy "Users can delete own sessions" on "public"."active_sessions";

drop policy "Users can view own sessions" on "public"."active_sessions";

drop policy "Users can delete their own activity ratings" on "public"."activity_ratings";

drop policy "Users can insert their own activity ratings" on "public"."activity_ratings";

drop policy "Users can update their own activity ratings" on "public"."activity_ratings";

drop policy "Users can view their own activity ratings" on "public"."activity_ratings";

drop policy "Users can manage their own AI recommendations" on "public"."ai_recommendations";

drop policy "Anyone can view cached places" on "public"."cached_places";

drop policy "Users can manage own collection items" on "public"."collection_items";

drop policy "Users can view own exports" on "public"."data_exports";

drop policy "Public read access for comments" on "public"."diary_comments";

drop policy "Users can manage own comments" on "public"."diary_comments";

drop policy "Users can manage own diary entries" on "public"."diary_entries";

drop policy "Users can view public diary entries" on "public"."diary_entries";

drop policy "Public read access for likes" on "public"."diary_likes";

drop policy "Users can manage own likes" on "public"."diary_likes";

drop policy "Public read access for itinerary items" on "public"."itinerary_items";

drop policy "Users can manage own itinerary items" on "public"."itinerary_items";

drop policy "System can manage live updates" on "public"."live_updates";

drop policy "Users can view relevant updates" on "public"."live_updates";

drop policy "Allow public read access to mood options" on "public"."mood_options";

drop policy "Users can manage their own moods" on "public"."moods";

drop policy "Users can manage own notification settings" on "public"."notification_settings";

drop policy "Users can access own places cache" on "public"."places_cache";

drop policy "Public read access for public collections" on "public"."post_collections";

drop policy "Users can manage own collections" on "public"."post_collections";

drop policy "Public read access for reactions" on "public"."post_reactions";

drop policy "Users can manage own reactions" on "public"."post_reactions";

drop policy "Public profiles are viewable by everyone" on "public"."profiles";

drop policy "Users can insert their own profile" on "public"."profiles";

drop policy "Users can update their own profile" on "public"."profiles";

drop policy "Users can view their own profile" on "public"."profiles";

drop policy "System can insert events" on "public"."realtime_events";

drop policy "Users can update own events" on "public"."realtime_events";

drop policy "Users can view own events" on "public"."realtime_events";

drop policy "Users can manage own saved entries" on "public"."saved_diary_entries";

drop policy "Users can delete their own scheduled activities" on "public"."scheduled_activities";

drop policy "Users can insert their own scheduled activities" on "public"."scheduled_activities";

drop policy "Users can update their own scheduled activities" on "public"."scheduled_activities";

drop policy "Users can view their own scheduled activities" on "public"."scheduled_activities";

drop policy "Users can manage own expenses" on "public"."travel_expenses";

drop policy "Users can delete their own check-ins" on "public"."user_check_ins";

drop policy "Users can insert their own check-ins" on "public"."user_check_ins";

drop policy "Users can update their own check-ins" on "public"."user_check_ins";

drop policy "Users can view their own check-ins" on "public"."user_check_ins";

drop policy "Public read access for follows" on "public"."user_follows";

drop policy "Users can manage own follows" on "public"."user_follows";

drop policy "Users can insert their own preference patterns" on "public"."user_preference_patterns";

drop policy "Users can update their own preference patterns" on "public"."user_preference_patterns";

drop policy "Users can view their own preference patterns" on "public"."user_preference_patterns";

drop policy "Users can manage their own preferences" on "public"."user_preferences";

drop policy "Users can update own presence" on "public"."user_presence";

drop policy "Users can view all presence data" on "public"."user_presence";

drop policy "Users can insert their own weekly reflections" on "public"."weekly_reflections";

drop policy "Users can update their own weekly reflections" on "public"."weekly_reflections";

drop policy "Users can view their own weekly reflections" on "public"."weekly_reflections";

drop policy "Anyone can view activities" on "public"."activities";

drop policy "Users can manage own subscriptions" on "public"."subscriptions";

drop policy "Anyone can view weather cache" on "public"."weather_cache";

revoke delete on table "public"."account_security" from "anon";

revoke insert on table "public"."account_security" from "anon";

revoke references on table "public"."account_security" from "anon";

revoke select on table "public"."account_security" from "anon";

revoke trigger on table "public"."account_security" from "anon";

revoke truncate on table "public"."account_security" from "anon";

revoke update on table "public"."account_security" from "anon";

revoke delete on table "public"."account_security" from "authenticated";

revoke insert on table "public"."account_security" from "authenticated";

revoke references on table "public"."account_security" from "authenticated";

revoke select on table "public"."account_security" from "authenticated";

revoke trigger on table "public"."account_security" from "authenticated";

revoke truncate on table "public"."account_security" from "authenticated";

revoke update on table "public"."account_security" from "authenticated";

revoke delete on table "public"."account_security" from "service_role";

revoke insert on table "public"."account_security" from "service_role";

revoke references on table "public"."account_security" from "service_role";

revoke select on table "public"."account_security" from "service_role";

revoke trigger on table "public"."account_security" from "service_role";

revoke truncate on table "public"."account_security" from "service_role";

revoke update on table "public"."account_security" from "service_role";

revoke delete on table "public"."active_sessions" from "anon";

revoke insert on table "public"."active_sessions" from "anon";

revoke references on table "public"."active_sessions" from "anon";

revoke select on table "public"."active_sessions" from "anon";

revoke trigger on table "public"."active_sessions" from "anon";

revoke truncate on table "public"."active_sessions" from "anon";

revoke update on table "public"."active_sessions" from "anon";

revoke delete on table "public"."active_sessions" from "authenticated";

revoke insert on table "public"."active_sessions" from "authenticated";

revoke references on table "public"."active_sessions" from "authenticated";

revoke select on table "public"."active_sessions" from "authenticated";

revoke trigger on table "public"."active_sessions" from "authenticated";

revoke truncate on table "public"."active_sessions" from "authenticated";

revoke update on table "public"."active_sessions" from "authenticated";

revoke delete on table "public"."active_sessions" from "service_role";

revoke insert on table "public"."active_sessions" from "service_role";

revoke references on table "public"."active_sessions" from "service_role";

revoke select on table "public"."active_sessions" from "service_role";

revoke trigger on table "public"."active_sessions" from "service_role";

revoke truncate on table "public"."active_sessions" from "service_role";

revoke update on table "public"."active_sessions" from "service_role";

revoke delete on table "public"."ai_recommendations" from "anon";

revoke insert on table "public"."ai_recommendations" from "anon";

revoke references on table "public"."ai_recommendations" from "anon";

revoke select on table "public"."ai_recommendations" from "anon";

revoke trigger on table "public"."ai_recommendations" from "anon";

revoke truncate on table "public"."ai_recommendations" from "anon";

revoke update on table "public"."ai_recommendations" from "anon";

revoke delete on table "public"."ai_recommendations" from "authenticated";

revoke insert on table "public"."ai_recommendations" from "authenticated";

revoke references on table "public"."ai_recommendations" from "authenticated";

revoke select on table "public"."ai_recommendations" from "authenticated";

revoke trigger on table "public"."ai_recommendations" from "authenticated";

revoke truncate on table "public"."ai_recommendations" from "authenticated";

revoke update on table "public"."ai_recommendations" from "authenticated";

revoke delete on table "public"."ai_recommendations" from "service_role";

revoke insert on table "public"."ai_recommendations" from "service_role";

revoke references on table "public"."ai_recommendations" from "service_role";

revoke select on table "public"."ai_recommendations" from "service_role";

revoke trigger on table "public"."ai_recommendations" from "service_role";

revoke truncate on table "public"."ai_recommendations" from "service_role";

revoke update on table "public"."ai_recommendations" from "service_role";

revoke delete on table "public"."billing_payments" from "anon";

revoke insert on table "public"."billing_payments" from "anon";

revoke references on table "public"."billing_payments" from "anon";

revoke select on table "public"."billing_payments" from "anon";

revoke trigger on table "public"."billing_payments" from "anon";

revoke truncate on table "public"."billing_payments" from "anon";

revoke update on table "public"."billing_payments" from "anon";

revoke delete on table "public"."billing_payments" from "authenticated";

revoke insert on table "public"."billing_payments" from "authenticated";

revoke references on table "public"."billing_payments" from "authenticated";

revoke select on table "public"."billing_payments" from "authenticated";

revoke trigger on table "public"."billing_payments" from "authenticated";

revoke truncate on table "public"."billing_payments" from "authenticated";

revoke update on table "public"."billing_payments" from "authenticated";

revoke delete on table "public"."billing_payments" from "service_role";

revoke insert on table "public"."billing_payments" from "service_role";

revoke references on table "public"."billing_payments" from "service_role";

revoke select on table "public"."billing_payments" from "service_role";

revoke trigger on table "public"."billing_payments" from "service_role";

revoke truncate on table "public"."billing_payments" from "service_role";

revoke update on table "public"."billing_payments" from "service_role";

revoke delete on table "public"."cached_places" from "anon";

revoke insert on table "public"."cached_places" from "anon";

revoke references on table "public"."cached_places" from "anon";

revoke select on table "public"."cached_places" from "anon";

revoke trigger on table "public"."cached_places" from "anon";

revoke truncate on table "public"."cached_places" from "anon";

revoke update on table "public"."cached_places" from "anon";

revoke delete on table "public"."cached_places" from "authenticated";

revoke insert on table "public"."cached_places" from "authenticated";

revoke references on table "public"."cached_places" from "authenticated";

revoke select on table "public"."cached_places" from "authenticated";

revoke trigger on table "public"."cached_places" from "authenticated";

revoke truncate on table "public"."cached_places" from "authenticated";

revoke update on table "public"."cached_places" from "authenticated";

revoke delete on table "public"."cached_places" from "service_role";

revoke insert on table "public"."cached_places" from "service_role";

revoke references on table "public"."cached_places" from "service_role";

revoke select on table "public"."cached_places" from "service_role";

revoke trigger on table "public"."cached_places" from "service_role";

revoke truncate on table "public"."cached_places" from "service_role";

revoke update on table "public"."cached_places" from "service_role";

revoke delete on table "public"."collection_items" from "anon";

revoke insert on table "public"."collection_items" from "anon";

revoke references on table "public"."collection_items" from "anon";

revoke select on table "public"."collection_items" from "anon";

revoke trigger on table "public"."collection_items" from "anon";

revoke truncate on table "public"."collection_items" from "anon";

revoke update on table "public"."collection_items" from "anon";

revoke delete on table "public"."collection_items" from "authenticated";

revoke insert on table "public"."collection_items" from "authenticated";

revoke references on table "public"."collection_items" from "authenticated";

revoke select on table "public"."collection_items" from "authenticated";

revoke trigger on table "public"."collection_items" from "authenticated";

revoke truncate on table "public"."collection_items" from "authenticated";

revoke update on table "public"."collection_items" from "authenticated";

revoke delete on table "public"."collection_items" from "service_role";

revoke insert on table "public"."collection_items" from "service_role";

revoke references on table "public"."collection_items" from "service_role";

revoke select on table "public"."collection_items" from "service_role";

revoke trigger on table "public"."collection_items" from "service_role";

revoke truncate on table "public"."collection_items" from "service_role";

revoke update on table "public"."collection_items" from "service_role";

revoke delete on table "public"."data_exports" from "anon";

revoke insert on table "public"."data_exports" from "anon";

revoke references on table "public"."data_exports" from "anon";

revoke select on table "public"."data_exports" from "anon";

revoke trigger on table "public"."data_exports" from "anon";

revoke truncate on table "public"."data_exports" from "anon";

revoke update on table "public"."data_exports" from "anon";

revoke delete on table "public"."data_exports" from "authenticated";

revoke insert on table "public"."data_exports" from "authenticated";

revoke references on table "public"."data_exports" from "authenticated";

revoke select on table "public"."data_exports" from "authenticated";

revoke trigger on table "public"."data_exports" from "authenticated";

revoke truncate on table "public"."data_exports" from "authenticated";

revoke update on table "public"."data_exports" from "authenticated";

revoke delete on table "public"."data_exports" from "service_role";

revoke insert on table "public"."data_exports" from "service_role";

revoke references on table "public"."data_exports" from "service_role";

revoke select on table "public"."data_exports" from "service_role";

revoke trigger on table "public"."data_exports" from "service_role";

revoke truncate on table "public"."data_exports" from "service_role";

revoke update on table "public"."data_exports" from "service_role";

revoke delete on table "public"."diary_comments" from "anon";

revoke insert on table "public"."diary_comments" from "anon";

revoke references on table "public"."diary_comments" from "anon";

revoke select on table "public"."diary_comments" from "anon";

revoke trigger on table "public"."diary_comments" from "anon";

revoke truncate on table "public"."diary_comments" from "anon";

revoke update on table "public"."diary_comments" from "anon";

revoke delete on table "public"."diary_comments" from "authenticated";

revoke insert on table "public"."diary_comments" from "authenticated";

revoke references on table "public"."diary_comments" from "authenticated";

revoke select on table "public"."diary_comments" from "authenticated";

revoke trigger on table "public"."diary_comments" from "authenticated";

revoke truncate on table "public"."diary_comments" from "authenticated";

revoke update on table "public"."diary_comments" from "authenticated";

revoke delete on table "public"."diary_comments" from "service_role";

revoke insert on table "public"."diary_comments" from "service_role";

revoke references on table "public"."diary_comments" from "service_role";

revoke select on table "public"."diary_comments" from "service_role";

revoke trigger on table "public"."diary_comments" from "service_role";

revoke truncate on table "public"."diary_comments" from "service_role";

revoke update on table "public"."diary_comments" from "service_role";

revoke delete on table "public"."diary_entries" from "anon";

revoke insert on table "public"."diary_entries" from "anon";

revoke references on table "public"."diary_entries" from "anon";

revoke select on table "public"."diary_entries" from "anon";

revoke trigger on table "public"."diary_entries" from "anon";

revoke truncate on table "public"."diary_entries" from "anon";

revoke update on table "public"."diary_entries" from "anon";

revoke delete on table "public"."diary_entries" from "authenticated";

revoke insert on table "public"."diary_entries" from "authenticated";

revoke references on table "public"."diary_entries" from "authenticated";

revoke select on table "public"."diary_entries" from "authenticated";

revoke trigger on table "public"."diary_entries" from "authenticated";

revoke truncate on table "public"."diary_entries" from "authenticated";

revoke update on table "public"."diary_entries" from "authenticated";

revoke delete on table "public"."diary_entries" from "service_role";

revoke insert on table "public"."diary_entries" from "service_role";

revoke references on table "public"."diary_entries" from "service_role";

revoke select on table "public"."diary_entries" from "service_role";

revoke trigger on table "public"."diary_entries" from "service_role";

revoke truncate on table "public"."diary_entries" from "service_role";

revoke update on table "public"."diary_entries" from "service_role";

revoke delete on table "public"."diary_likes" from "anon";

revoke insert on table "public"."diary_likes" from "anon";

revoke references on table "public"."diary_likes" from "anon";

revoke select on table "public"."diary_likes" from "anon";

revoke trigger on table "public"."diary_likes" from "anon";

revoke truncate on table "public"."diary_likes" from "anon";

revoke update on table "public"."diary_likes" from "anon";

revoke delete on table "public"."diary_likes" from "authenticated";

revoke insert on table "public"."diary_likes" from "authenticated";

revoke references on table "public"."diary_likes" from "authenticated";

revoke select on table "public"."diary_likes" from "authenticated";

revoke trigger on table "public"."diary_likes" from "authenticated";

revoke truncate on table "public"."diary_likes" from "authenticated";

revoke update on table "public"."diary_likes" from "authenticated";

revoke delete on table "public"."diary_likes" from "service_role";

revoke insert on table "public"."diary_likes" from "service_role";

revoke references on table "public"."diary_likes" from "service_role";

revoke select on table "public"."diary_likes" from "service_role";

revoke trigger on table "public"."diary_likes" from "service_role";

revoke truncate on table "public"."diary_likes" from "service_role";

revoke update on table "public"."diary_likes" from "service_role";

revoke delete on table "public"."itinerary_items" from "anon";

revoke insert on table "public"."itinerary_items" from "anon";

revoke references on table "public"."itinerary_items" from "anon";

revoke select on table "public"."itinerary_items" from "anon";

revoke trigger on table "public"."itinerary_items" from "anon";

revoke truncate on table "public"."itinerary_items" from "anon";

revoke update on table "public"."itinerary_items" from "anon";

revoke delete on table "public"."itinerary_items" from "authenticated";

revoke insert on table "public"."itinerary_items" from "authenticated";

revoke references on table "public"."itinerary_items" from "authenticated";

revoke select on table "public"."itinerary_items" from "authenticated";

revoke trigger on table "public"."itinerary_items" from "authenticated";

revoke truncate on table "public"."itinerary_items" from "authenticated";

revoke update on table "public"."itinerary_items" from "authenticated";

revoke delete on table "public"."itinerary_items" from "service_role";

revoke insert on table "public"."itinerary_items" from "service_role";

revoke references on table "public"."itinerary_items" from "service_role";

revoke select on table "public"."itinerary_items" from "service_role";

revoke trigger on table "public"."itinerary_items" from "service_role";

revoke truncate on table "public"."itinerary_items" from "service_role";

revoke update on table "public"."itinerary_items" from "service_role";

revoke delete on table "public"."live_updates" from "anon";

revoke insert on table "public"."live_updates" from "anon";

revoke references on table "public"."live_updates" from "anon";

revoke select on table "public"."live_updates" from "anon";

revoke trigger on table "public"."live_updates" from "anon";

revoke truncate on table "public"."live_updates" from "anon";

revoke update on table "public"."live_updates" from "anon";

revoke delete on table "public"."live_updates" from "authenticated";

revoke insert on table "public"."live_updates" from "authenticated";

revoke references on table "public"."live_updates" from "authenticated";

revoke select on table "public"."live_updates" from "authenticated";

revoke trigger on table "public"."live_updates" from "authenticated";

revoke truncate on table "public"."live_updates" from "authenticated";

revoke update on table "public"."live_updates" from "authenticated";

revoke delete on table "public"."live_updates" from "service_role";

revoke insert on table "public"."live_updates" from "service_role";

revoke references on table "public"."live_updates" from "service_role";

revoke select on table "public"."live_updates" from "service_role";

revoke trigger on table "public"."live_updates" from "service_role";

revoke truncate on table "public"."live_updates" from "service_role";

revoke update on table "public"."live_updates" from "service_role";

revoke delete on table "public"."mood_options" from "anon";

revoke insert on table "public"."mood_options" from "anon";

revoke references on table "public"."mood_options" from "anon";

revoke select on table "public"."mood_options" from "anon";

revoke trigger on table "public"."mood_options" from "anon";

revoke truncate on table "public"."mood_options" from "anon";

revoke update on table "public"."mood_options" from "anon";

revoke delete on table "public"."mood_options" from "authenticated";

revoke insert on table "public"."mood_options" from "authenticated";

revoke references on table "public"."mood_options" from "authenticated";

revoke select on table "public"."mood_options" from "authenticated";

revoke trigger on table "public"."mood_options" from "authenticated";

revoke truncate on table "public"."mood_options" from "authenticated";

revoke update on table "public"."mood_options" from "authenticated";

revoke delete on table "public"."mood_options" from "service_role";

revoke insert on table "public"."mood_options" from "service_role";

revoke references on table "public"."mood_options" from "service_role";

revoke select on table "public"."mood_options" from "service_role";

revoke trigger on table "public"."mood_options" from "service_role";

revoke truncate on table "public"."mood_options" from "service_role";

revoke update on table "public"."mood_options" from "service_role";

revoke delete on table "public"."notification_settings" from "anon";

revoke insert on table "public"."notification_settings" from "anon";

revoke references on table "public"."notification_settings" from "anon";

revoke select on table "public"."notification_settings" from "anon";

revoke trigger on table "public"."notification_settings" from "anon";

revoke truncate on table "public"."notification_settings" from "anon";

revoke update on table "public"."notification_settings" from "anon";

revoke delete on table "public"."notification_settings" from "authenticated";

revoke insert on table "public"."notification_settings" from "authenticated";

revoke references on table "public"."notification_settings" from "authenticated";

revoke select on table "public"."notification_settings" from "authenticated";

revoke trigger on table "public"."notification_settings" from "authenticated";

revoke truncate on table "public"."notification_settings" from "authenticated";

revoke update on table "public"."notification_settings" from "authenticated";

revoke delete on table "public"."notification_settings" from "service_role";

revoke insert on table "public"."notification_settings" from "service_role";

revoke references on table "public"."notification_settings" from "service_role";

revoke select on table "public"."notification_settings" from "service_role";

revoke trigger on table "public"."notification_settings" from "service_role";

revoke truncate on table "public"."notification_settings" from "service_role";

revoke update on table "public"."notification_settings" from "service_role";

revoke delete on table "public"."post_collections" from "anon";

revoke insert on table "public"."post_collections" from "anon";

revoke references on table "public"."post_collections" from "anon";

revoke select on table "public"."post_collections" from "anon";

revoke trigger on table "public"."post_collections" from "anon";

revoke truncate on table "public"."post_collections" from "anon";

revoke update on table "public"."post_collections" from "anon";

revoke delete on table "public"."post_collections" from "authenticated";

revoke insert on table "public"."post_collections" from "authenticated";

revoke references on table "public"."post_collections" from "authenticated";

revoke select on table "public"."post_collections" from "authenticated";

revoke trigger on table "public"."post_collections" from "authenticated";

revoke truncate on table "public"."post_collections" from "authenticated";

revoke update on table "public"."post_collections" from "authenticated";

revoke delete on table "public"."post_collections" from "service_role";

revoke insert on table "public"."post_collections" from "service_role";

revoke references on table "public"."post_collections" from "service_role";

revoke select on table "public"."post_collections" from "service_role";

revoke trigger on table "public"."post_collections" from "service_role";

revoke truncate on table "public"."post_collections" from "service_role";

revoke update on table "public"."post_collections" from "service_role";

revoke delete on table "public"."post_reactions" from "anon";

revoke insert on table "public"."post_reactions" from "anon";

revoke references on table "public"."post_reactions" from "anon";

revoke select on table "public"."post_reactions" from "anon";

revoke trigger on table "public"."post_reactions" from "anon";

revoke truncate on table "public"."post_reactions" from "anon";

revoke update on table "public"."post_reactions" from "anon";

revoke delete on table "public"."post_reactions" from "authenticated";

revoke insert on table "public"."post_reactions" from "authenticated";

revoke references on table "public"."post_reactions" from "authenticated";

revoke select on table "public"."post_reactions" from "authenticated";

revoke trigger on table "public"."post_reactions" from "authenticated";

revoke truncate on table "public"."post_reactions" from "authenticated";

revoke update on table "public"."post_reactions" from "authenticated";

revoke delete on table "public"."post_reactions" from "service_role";

revoke insert on table "public"."post_reactions" from "service_role";

revoke references on table "public"."post_reactions" from "service_role";

revoke select on table "public"."post_reactions" from "service_role";

revoke trigger on table "public"."post_reactions" from "service_role";

revoke truncate on table "public"."post_reactions" from "service_role";

revoke update on table "public"."post_reactions" from "service_role";

revoke delete on table "public"."realtime_events" from "anon";

revoke insert on table "public"."realtime_events" from "anon";

revoke references on table "public"."realtime_events" from "anon";

revoke select on table "public"."realtime_events" from "anon";

revoke trigger on table "public"."realtime_events" from "anon";

revoke truncate on table "public"."realtime_events" from "anon";

revoke update on table "public"."realtime_events" from "anon";

revoke delete on table "public"."realtime_events" from "authenticated";

revoke insert on table "public"."realtime_events" from "authenticated";

revoke references on table "public"."realtime_events" from "authenticated";

revoke select on table "public"."realtime_events" from "authenticated";

revoke trigger on table "public"."realtime_events" from "authenticated";

revoke truncate on table "public"."realtime_events" from "authenticated";

revoke update on table "public"."realtime_events" from "authenticated";

revoke delete on table "public"."realtime_events" from "service_role";

revoke insert on table "public"."realtime_events" from "service_role";

revoke references on table "public"."realtime_events" from "service_role";

revoke select on table "public"."realtime_events" from "service_role";

revoke trigger on table "public"."realtime_events" from "service_role";

revoke truncate on table "public"."realtime_events" from "service_role";

revoke update on table "public"."realtime_events" from "service_role";

revoke delete on table "public"."saved_diary_entries" from "anon";

revoke insert on table "public"."saved_diary_entries" from "anon";

revoke references on table "public"."saved_diary_entries" from "anon";

revoke select on table "public"."saved_diary_entries" from "anon";

revoke trigger on table "public"."saved_diary_entries" from "anon";

revoke truncate on table "public"."saved_diary_entries" from "anon";

revoke update on table "public"."saved_diary_entries" from "anon";

revoke delete on table "public"."saved_diary_entries" from "authenticated";

revoke insert on table "public"."saved_diary_entries" from "authenticated";

revoke references on table "public"."saved_diary_entries" from "authenticated";

revoke select on table "public"."saved_diary_entries" from "authenticated";

revoke trigger on table "public"."saved_diary_entries" from "authenticated";

revoke truncate on table "public"."saved_diary_entries" from "authenticated";

revoke update on table "public"."saved_diary_entries" from "authenticated";

revoke delete on table "public"."saved_diary_entries" from "service_role";

revoke insert on table "public"."saved_diary_entries" from "service_role";

revoke references on table "public"."saved_diary_entries" from "service_role";

revoke select on table "public"."saved_diary_entries" from "service_role";

revoke trigger on table "public"."saved_diary_entries" from "service_role";

revoke truncate on table "public"."saved_diary_entries" from "service_role";

revoke update on table "public"."saved_diary_entries" from "service_role";

revoke delete on table "public"."spatial_ref_sys" from "anon";

revoke insert on table "public"."spatial_ref_sys" from "anon";

revoke references on table "public"."spatial_ref_sys" from "anon";

revoke select on table "public"."spatial_ref_sys" from "anon";

revoke trigger on table "public"."spatial_ref_sys" from "anon";

revoke truncate on table "public"."spatial_ref_sys" from "anon";

revoke update on table "public"."spatial_ref_sys" from "anon";

revoke delete on table "public"."spatial_ref_sys" from "authenticated";

revoke insert on table "public"."spatial_ref_sys" from "authenticated";

revoke references on table "public"."spatial_ref_sys" from "authenticated";

revoke select on table "public"."spatial_ref_sys" from "authenticated";

revoke trigger on table "public"."spatial_ref_sys" from "authenticated";

revoke truncate on table "public"."spatial_ref_sys" from "authenticated";

revoke update on table "public"."spatial_ref_sys" from "authenticated";

revoke delete on table "public"."spatial_ref_sys" from "postgres";

revoke insert on table "public"."spatial_ref_sys" from "postgres";

revoke references on table "public"."spatial_ref_sys" from "postgres";

revoke select on table "public"."spatial_ref_sys" from "postgres";

revoke trigger on table "public"."spatial_ref_sys" from "postgres";

revoke truncate on table "public"."spatial_ref_sys" from "postgres";

revoke update on table "public"."spatial_ref_sys" from "postgres";

revoke delete on table "public"."spatial_ref_sys" from "service_role";

revoke insert on table "public"."spatial_ref_sys" from "service_role";

revoke references on table "public"."spatial_ref_sys" from "service_role";

revoke select on table "public"."spatial_ref_sys" from "service_role";

revoke trigger on table "public"."spatial_ref_sys" from "service_role";

revoke truncate on table "public"."spatial_ref_sys" from "service_role";

revoke update on table "public"."spatial_ref_sys" from "service_role";

revoke delete on table "public"."stripe_webhook_events" from "anon";

revoke insert on table "public"."stripe_webhook_events" from "anon";

revoke references on table "public"."stripe_webhook_events" from "anon";

revoke select on table "public"."stripe_webhook_events" from "anon";

revoke trigger on table "public"."stripe_webhook_events" from "anon";

revoke truncate on table "public"."stripe_webhook_events" from "anon";

revoke update on table "public"."stripe_webhook_events" from "anon";

revoke delete on table "public"."stripe_webhook_events" from "authenticated";

revoke insert on table "public"."stripe_webhook_events" from "authenticated";

revoke references on table "public"."stripe_webhook_events" from "authenticated";

revoke select on table "public"."stripe_webhook_events" from "authenticated";

revoke trigger on table "public"."stripe_webhook_events" from "authenticated";

revoke truncate on table "public"."stripe_webhook_events" from "authenticated";

revoke update on table "public"."stripe_webhook_events" from "authenticated";

revoke delete on table "public"."stripe_webhook_events" from "service_role";

revoke insert on table "public"."stripe_webhook_events" from "service_role";

revoke references on table "public"."stripe_webhook_events" from "service_role";

revoke select on table "public"."stripe_webhook_events" from "service_role";

revoke trigger on table "public"."stripe_webhook_events" from "service_role";

revoke truncate on table "public"."stripe_webhook_events" from "service_role";

revoke update on table "public"."stripe_webhook_events" from "service_role";

revoke delete on table "public"."travel_expenses" from "anon";

revoke insert on table "public"."travel_expenses" from "anon";

revoke references on table "public"."travel_expenses" from "anon";

revoke select on table "public"."travel_expenses" from "anon";

revoke trigger on table "public"."travel_expenses" from "anon";

revoke truncate on table "public"."travel_expenses" from "anon";

revoke update on table "public"."travel_expenses" from "anon";

revoke delete on table "public"."travel_expenses" from "authenticated";

revoke insert on table "public"."travel_expenses" from "authenticated";

revoke references on table "public"."travel_expenses" from "authenticated";

revoke select on table "public"."travel_expenses" from "authenticated";

revoke trigger on table "public"."travel_expenses" from "authenticated";

revoke truncate on table "public"."travel_expenses" from "authenticated";

revoke update on table "public"."travel_expenses" from "authenticated";

revoke delete on table "public"."travel_expenses" from "service_role";

revoke insert on table "public"."travel_expenses" from "service_role";

revoke references on table "public"."travel_expenses" from "service_role";

revoke select on table "public"."travel_expenses" from "service_role";

revoke trigger on table "public"."travel_expenses" from "service_role";

revoke truncate on table "public"."travel_expenses" from "service_role";

revoke update on table "public"."travel_expenses" from "service_role";

revoke delete on table "public"."user_follows" from "anon";

revoke insert on table "public"."user_follows" from "anon";

revoke references on table "public"."user_follows" from "anon";

revoke select on table "public"."user_follows" from "anon";

revoke trigger on table "public"."user_follows" from "anon";

revoke truncate on table "public"."user_follows" from "anon";

revoke update on table "public"."user_follows" from "anon";

revoke delete on table "public"."user_follows" from "authenticated";

revoke insert on table "public"."user_follows" from "authenticated";

revoke references on table "public"."user_follows" from "authenticated";

revoke select on table "public"."user_follows" from "authenticated";

revoke trigger on table "public"."user_follows" from "authenticated";

revoke truncate on table "public"."user_follows" from "authenticated";

revoke update on table "public"."user_follows" from "authenticated";

revoke delete on table "public"."user_follows" from "service_role";

revoke insert on table "public"."user_follows" from "service_role";

revoke references on table "public"."user_follows" from "service_role";

revoke select on table "public"."user_follows" from "service_role";

revoke trigger on table "public"."user_follows" from "service_role";

revoke truncate on table "public"."user_follows" from "service_role";

revoke update on table "public"."user_follows" from "service_role";

revoke delete on table "public"."user_presence" from "anon";

revoke insert on table "public"."user_presence" from "anon";

revoke references on table "public"."user_presence" from "anon";

revoke select on table "public"."user_presence" from "anon";

revoke trigger on table "public"."user_presence" from "anon";

revoke truncate on table "public"."user_presence" from "anon";

revoke update on table "public"."user_presence" from "anon";

revoke delete on table "public"."user_presence" from "authenticated";

revoke insert on table "public"."user_presence" from "authenticated";

revoke references on table "public"."user_presence" from "authenticated";

revoke select on table "public"."user_presence" from "authenticated";

revoke trigger on table "public"."user_presence" from "authenticated";

revoke truncate on table "public"."user_presence" from "authenticated";

revoke update on table "public"."user_presence" from "authenticated";

revoke delete on table "public"."user_presence" from "service_role";

revoke insert on table "public"."user_presence" from "service_role";

revoke references on table "public"."user_presence" from "service_role";

revoke select on table "public"."user_presence" from "service_role";

revoke trigger on table "public"."user_presence" from "service_role";

revoke truncate on table "public"."user_presence" from "service_role";

revoke update on table "public"."user_presence" from "service_role";

revoke delete on table "public"."weekly_reflections" from "anon";

revoke insert on table "public"."weekly_reflections" from "anon";

revoke references on table "public"."weekly_reflections" from "anon";

revoke select on table "public"."weekly_reflections" from "anon";

revoke trigger on table "public"."weekly_reflections" from "anon";

revoke truncate on table "public"."weekly_reflections" from "anon";

revoke update on table "public"."weekly_reflections" from "anon";

revoke delete on table "public"."weekly_reflections" from "authenticated";

revoke insert on table "public"."weekly_reflections" from "authenticated";

revoke references on table "public"."weekly_reflections" from "authenticated";

revoke select on table "public"."weekly_reflections" from "authenticated";

revoke trigger on table "public"."weekly_reflections" from "authenticated";

revoke truncate on table "public"."weekly_reflections" from "authenticated";

revoke update on table "public"."weekly_reflections" from "authenticated";

revoke delete on table "public"."weekly_reflections" from "service_role";

revoke insert on table "public"."weekly_reflections" from "service_role";

revoke references on table "public"."weekly_reflections" from "service_role";

revoke select on table "public"."weekly_reflections" from "service_role";

revoke trigger on table "public"."weekly_reflections" from "service_role";

revoke truncate on table "public"."weekly_reflections" from "service_role";

revoke update on table "public"."weekly_reflections" from "service_role";

alter table "public"."account_security" drop constraint "account_security_user_id_fkey";

alter table "public"."account_security" drop constraint "account_security_user_id_key";

alter table "public"."active_sessions" drop constraint "active_sessions_device_type_check";

alter table "public"."active_sessions" drop constraint "active_sessions_user_id_fkey";

alter table "public"."activity_ratings" drop constraint "activity_ratings_stars_check";

alter table "public"."ai_recommendations" drop constraint "ai_recommendations_user_id_fkey";

alter table "public"."billing_payments" drop constraint "billing_payments_stripe_invoice_id_key";

alter table "public"."billing_payments" drop constraint "billing_payments_user_id_fkey";

alter table "public"."cached_places" drop constraint "cached_places_place_id_key";

alter table "public"."collection_items" drop constraint "collection_items_collection_id_diary_entry_id_key";

alter table "public"."collection_items" drop constraint "collection_items_collection_id_fkey";

alter table "public"."collection_items" drop constraint "collection_items_diary_entry_id_fkey";

alter table "public"."data_exports" drop constraint "data_exports_user_id_fkey";

alter table "public"."diary_comments" drop constraint "diary_comments_diary_entry_id_fkey";

alter table "public"."diary_comments" drop constraint "diary_comments_user_id_fkey";

alter table "public"."diary_entries" drop constraint "diary_entries_privacy_level_check";

alter table "public"."diary_entries" drop constraint "diary_entries_rating_check";

alter table "public"."diary_entries" drop constraint "diary_entries_user_id_fkey";

alter table "public"."diary_likes" drop constraint "diary_likes_diary_entry_id_fkey";

alter table "public"."diary_likes" drop constraint "diary_likes_user_id_diary_entry_id_key";

alter table "public"."diary_likes" drop constraint "diary_likes_user_id_fkey";

alter table "public"."itinerary_items" drop constraint "itinerary_items_diary_entry_id_fkey";

alter table "public"."itinerary_items" drop constraint "itinerary_items_rating_check";

alter table "public"."live_updates" drop constraint "live_updates_update_type_check";

alter table "public"."live_updates" drop constraint "live_updates_user_id_fkey";

alter table "public"."notification_settings" drop constraint "notification_settings_quiet_end_hour_check";

alter table "public"."notification_settings" drop constraint "notification_settings_quiet_start_hour_check";

alter table "public"."notification_settings" drop constraint "notification_settings_user_id_fkey";

alter table "public"."notification_settings" drop constraint "notification_settings_user_id_key";

alter table "public"."post_collections" drop constraint "post_collections_user_id_fkey";

alter table "public"."post_reactions" drop constraint "post_reactions_diary_entry_id_fkey";

alter table "public"."post_reactions" drop constraint "post_reactions_reaction_type_check";

alter table "public"."post_reactions" drop constraint "post_reactions_user_id_diary_entry_id_key";

alter table "public"."post_reactions" drop constraint "post_reactions_user_id_fkey";

alter table "public"."profiles" drop constraint "profiles_profile_visibility_check";

alter table "public"."realtime_events" drop constraint "realtime_events_related_post_id_fkey";

alter table "public"."realtime_events" drop constraint "realtime_events_related_user_id_fkey";

alter table "public"."realtime_events" drop constraint "realtime_events_type_check";

alter table "public"."realtime_events" drop constraint "realtime_events_user_id_fkey";

alter table "public"."saved_diary_entries" drop constraint "saved_diary_entries_diary_entry_id_fkey";

alter table "public"."saved_diary_entries" drop constraint "saved_diary_entries_user_id_diary_entry_id_key";

alter table "public"."saved_diary_entries" drop constraint "saved_diary_entries_user_id_fkey";

alter table "public"."stripe_webhook_events" drop constraint "stripe_webhook_events_stripe_event_id_key";

alter table "public"."travel_expenses" drop constraint "travel_expenses_diary_entry_id_fkey";

alter table "public"."user_follows" drop constraint "user_follows_check";

alter table "public"."user_follows" drop constraint "user_follows_follower_id_fkey";

alter table "public"."user_follows" drop constraint "user_follows_follower_id_following_id_key";

alter table "public"."user_follows" drop constraint "user_follows_following_id_fkey";

alter table "public"."user_preference_patterns" drop constraint "user_preference_patterns_id_fkey";

alter table "public"."user_presence" drop constraint "user_presence_activity_status_check";

alter table "public"."user_presence" drop constraint "user_presence_user_id_fkey";

alter table "public"."user_presence" drop constraint "user_presence_user_id_key";

alter table "public"."weekly_reflections" drop constraint "weekly_reflections_user_id_fkey";

alter table "public"."places_cache" drop constraint "places_cache_request_type_check";

alter table "public"."profiles" drop constraint "profiles_gender_check";

drop function if exists "public"."cleanup_expired_places_cache"();

drop function if exists "public"."cleanup_expired_weather_cache"();

drop function if exists "public"."cleanup_old_events"();

drop function if exists "public"."ensure_user_profile"(user_uuid uuid);

drop function if exists "public"."generate_unique_username"(base_name text);

drop type "public"."geometry_dump";

drop function if exists "public"."get_diary_entry_with_stats"(entry_id uuid);

drop function if exists "public"."get_post_with_full_stats"(post_id uuid);

drop function if exists "public"."get_trending_posts"(days_back integer, limit_count integer);

drop function if exists "public"."handle_diary_interaction"();

drop function if exists "public"."increment_post_view_count"(post_id uuid);

drop function if exists "public"."mark_events_as_read"(event_ids uuid[]);

drop function if exists "public"."send_realtime_notification"(target_user_id uuid, event_type text, event_title text, event_message text, event_data jsonb, source_user_id uuid, related_post_id uuid, priority_level integer);

drop function if exists "public"."trigger_set_timestamp"();

drop function if exists "public"."update_last_active"();

drop function if exists "public"."update_user_patterns_on_rating"();

drop function if exists "public"."update_user_presence"(activity_status text, location_data jsonb, share_location boolean);

drop type "public"."valid_detail";

alter table "public"."account_security" drop constraint "account_security_pkey";

alter table "public"."active_sessions" drop constraint "active_sessions_pkey";

alter table "public"."ai_recommendations" drop constraint "ai_recommendations_pkey";

alter table "public"."billing_payments" drop constraint "billing_payments_pkey";

alter table "public"."cached_places" drop constraint "cached_places_pkey";

alter table "public"."collection_items" drop constraint "collection_items_pkey";

alter table "public"."data_exports" drop constraint "data_exports_pkey";

alter table "public"."diary_comments" drop constraint "diary_comments_pkey";

alter table "public"."diary_entries" drop constraint "diary_entries_pkey";

alter table "public"."diary_likes" drop constraint "diary_likes_pkey";

alter table "public"."itinerary_items" drop constraint "itinerary_items_pkey";

alter table "public"."live_updates" drop constraint "live_updates_pkey";

alter table "public"."mood_options" drop constraint "mood_options_pkey";

alter table "public"."notification_settings" drop constraint "notification_settings_pkey";

alter table "public"."post_collections" drop constraint "post_collections_pkey";

alter table "public"."post_reactions" drop constraint "post_reactions_pkey";

alter table "public"."realtime_events" drop constraint "realtime_events_pkey";

alter table "public"."saved_diary_entries" drop constraint "saved_diary_entries_pkey";

alter table "public"."stripe_webhook_events" drop constraint "stripe_webhook_events_pkey";

alter table "public"."travel_expenses" drop constraint "travel_expenses_pkey";

alter table "public"."user_follows" drop constraint "user_follows_pkey";

alter table "public"."user_presence" drop constraint "user_presence_pkey";

alter table "public"."weekly_reflections" drop constraint "weekly_reflections_pkey";

drop index if exists "public"."account_security_pkey";

drop index if exists "public"."account_security_user_id_key";

drop index if exists "public"."active_sessions_pkey";

drop index if exists "public"."ai_recommendations_pkey";

drop index if exists "public"."billing_payments_paid_at_idx";

drop index if exists "public"."billing_payments_pkey";

drop index if exists "public"."billing_payments_stripe_invoice_id_key";

drop index if exists "public"."billing_payments_user_id_idx";

drop index if exists "public"."cached_places_pkey";

drop index if exists "public"."cached_places_place_id_key";

drop index if exists "public"."collection_items_collection_id_diary_entry_id_key";

drop index if exists "public"."collection_items_pkey";

drop index if exists "public"."data_exports_pkey";

drop index if exists "public"."diary_comments_pkey";

drop index if exists "public"."diary_entries_created_at_idx";

drop index if exists "public"."diary_entries_pkey";

drop index if exists "public"."diary_entries_user_id_idx";

drop index if exists "public"."diary_likes_pkey";

drop index if exists "public"."diary_likes_user_id_diary_entry_id_key";

drop index if exists "public"."idx_active_sessions_is_current";

drop index if exists "public"."idx_active_sessions_user_id";

drop index if exists "public"."idx_activities_category";

drop index if exists "public"."idx_activities_mood_tags";

drop index if exists "public"."idx_activity_ratings_activity_id";

drop index if exists "public"."idx_activity_ratings_completed_at";

drop index if exists "public"."idx_activity_ratings_mood";

drop index if exists "public"."idx_activity_ratings_stars";

drop index if exists "public"."idx_ai_recommendations_user_id";

drop index if exists "public"."idx_cached_places_location";

drop index if exists "public"."idx_cached_places_mood_tags";

drop index if exists "public"."idx_data_exports_created_at";

drop index if exists "public"."idx_data_exports_user_id";

drop index if exists "public"."idx_diary_comments_entry_id";

drop index if exists "public"."idx_diary_comments_user_id";

drop index if exists "public"."idx_diary_entries_activities";

drop index if exists "public"."idx_diary_entries_created_at";

drop index if exists "public"."idx_diary_entries_location";

drop index if exists "public"."idx_diary_entries_privacy";

drop index if exists "public"."idx_diary_entries_public";

drop index if exists "public"."idx_diary_entries_rating";

drop index if exists "public"."idx_diary_entries_tags";

drop index if exists "public"."idx_diary_entries_user_id";

drop index if exists "public"."idx_diary_entries_view_count";

drop index if exists "public"."idx_diary_entries_weather";

drop index if exists "public"."idx_diary_likes_entry_id";

drop index if exists "public"."idx_diary_likes_user_id";

drop index if exists "public"."idx_itinerary_items_category";

drop index if exists "public"."idx_itinerary_items_entry_id";

drop index if exists "public"."idx_itinerary_items_order";

drop index if exists "public"."idx_live_updates_processed";

drop index if exists "public"."idx_live_updates_table_name";

drop index if exists "public"."idx_live_updates_timestamp";

drop index if exists "public"."idx_mood_options_active";

drop index if exists "public"."idx_mood_options_display_order";

drop index if exists "public"."idx_moods_user_id_created_at";

drop index if exists "public"."idx_notification_settings_user_id";

drop index if exists "public"."idx_places_cache_expires_at";

drop index if exists "public"."idx_places_cache_key";

drop index if exists "public"."idx_places_cache_location";

drop index if exists "public"."idx_places_cache_request_type";

drop index if exists "public"."idx_places_cache_user_id";

drop index if exists "public"."idx_post_reactions_entry_id";

drop index if exists "public"."idx_post_reactions_type";

drop index if exists "public"."idx_preference_patterns_last_updated";

drop index if exists "public"."idx_preference_patterns_user_id";

drop index if exists "public"."idx_realtime_events_is_read";

drop index if exists "public"."idx_realtime_events_priority";

drop index if exists "public"."idx_realtime_events_timestamp";

drop index if exists "public"."idx_realtime_events_type";

drop index if exists "public"."idx_realtime_events_user_id";

drop index if exists "public"."idx_saved_entries_user_id";

drop index if exists "public"."idx_travel_expenses_category";

drop index if exists "public"."idx_travel_expenses_entry_id";

drop index if exists "public"."idx_user_follows_follower";

drop index if exists "public"."idx_user_follows_following";

drop index if exists "public"."idx_user_preferences_interests";

drop index if exists "public"."idx_user_preferences_mood_preferences";

drop index if exists "public"."idx_user_preferences_travel_styles";

drop index if exists "public"."idx_user_preferences_user_id";

drop index if exists "public"."idx_user_presence_is_online";

drop index if exists "public"."idx_user_presence_last_seen";

drop index if exists "public"."idx_user_presence_user_id";

drop index if exists "public"."idx_weather_cache_location";

drop index if exists "public"."idx_weekly_reflections_user_id";

drop index if exists "public"."idx_weekly_reflections_week_start";

drop index if exists "public"."itinerary_items_pkey";

drop index if exists "public"."live_updates_pkey";

drop index if exists "public"."mood_options_pkey";

drop index if exists "public"."notification_settings_pkey";

drop index if exists "public"."notification_settings_user_id_key";

drop index if exists "public"."post_collections_pkey";

drop index if exists "public"."post_reactions_pkey";

drop index if exists "public"."post_reactions_user_id_diary_entry_id_key";

drop index if exists "public"."profiles_created_at_idx";

drop index if exists "public"."profiles_email_idx";

drop index if exists "public"."profiles_is_public_idx";

drop index if exists "public"."profiles_travel_style_idx";

drop index if exists "public"."profiles_username_idx";

drop index if exists "public"."realtime_events_pkey";

drop index if exists "public"."saved_diary_entries_pkey";

drop index if exists "public"."saved_diary_entries_user_id_diary_entry_id_key";

drop index if exists "public"."stripe_webhook_events_pkey";

drop index if exists "public"."stripe_webhook_events_stripe_event_id_key";

drop index if exists "public"."subscriptions_stripe_customer_id_key";

drop index if exists "public"."subscriptions_stripe_subscription_id_key";

drop index if exists "public"."travel_expenses_pkey";

drop index if exists "public"."user_check_ins_timestamp_idx";

drop index if exists "public"."user_check_ins_user_id_idx";

drop index if exists "public"."user_check_ins_user_timestamp_idx";

drop index if exists "public"."user_follows_follower_id_following_id_key";

drop index if exists "public"."user_follows_follower_idx";

drop index if exists "public"."user_follows_following_idx";

drop index if exists "public"."user_follows_pkey";

drop index if exists "public"."user_presence_pkey";

drop index if exists "public"."user_presence_user_id_key";

drop index if exists "public"."weekly_reflections_pkey";

drop index if exists "public"."user_check_ins_pkey";

drop table "public"."account_security";

drop table "public"."active_sessions";

drop table "public"."ai_recommendations";

drop table "public"."billing_payments";

drop table "public"."cached_places";

drop table "public"."collection_items";

drop table "public"."data_exports";

drop table "public"."diary_comments";

drop table "public"."diary_entries";

drop table "public"."diary_likes";

drop table "public"."itinerary_items";

drop table "public"."live_updates";

drop table "public"."mood_options";

drop table "public"."notification_settings";

drop table "public"."post_collections";

drop table "public"."post_reactions";

drop table "public"."realtime_events";

drop table "public"."saved_diary_entries";

drop table "public"."stripe_webhook_events";

drop table "public"."travel_expenses";

drop table "public"."user_follows";

drop table "public"."user_presence";

drop table "public"."weekly_reflections";


  create table "public"."ai_conversations" (
    "id" uuid not null default gen_random_uuid(),
    "conversation_id" text not null,
    "user_id" uuid not null,
    "role" text not null,
    "content" text not null,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."ai_conversations" enable row level security;


  create table "public"."api_usage_alerts" (
    "id" uuid not null default gen_random_uuid(),
    "checked_at" timestamp with time zone default now(),
    "places_calls_last_hour" integer default 0,
    "moody_calls_last_hour" integer default 0,
    "cache_misses_last_hour" integer default 0,
    "alert_sent" boolean default false,
    "alert_reason" text
      );


alter table "public"."api_usage_alerts" enable row level security;


  create table "public"."business_checkins" (
    "id" uuid not null default gen_random_uuid(),
    "business_listing_id" uuid not null,
    "user_id" uuid not null,
    "place_id" text not null,
    "mood" text,
    "came_from_day_plan" boolean default false,
    "came_from_push_notification" boolean default false,
    "came_from_explore" boolean default false,
    "checked_in_at" timestamp with time zone default now(),
    "checked_out_at" timestamp with time zone,
    "left_review" boolean default false,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."business_checkins" enable row level security;


  create table "public"."business_listings" (
    "id" uuid not null default gen_random_uuid(),
    "business_name" text not null,
    "contact_email" text not null,
    "city" text not null,
    "country" text not null default 'NL'::text,
    "place_id" text,
    "subscription_tier" text not null default 'basic'::text,
    "subscription_status" text not null default 'active'::text,
    "subscription_started_at" timestamp with time zone default now(),
    "subscription_expires_at" timestamp with time zone,
    "target_moods" text[] default '{}'::text[],
    "target_filters" text[] default '{}'::text[],
    "is_halal" boolean default false,
    "is_vegan_friendly" boolean default false,
    "is_vegetarian_friendly" boolean default false,
    "is_lgbtq_friendly" boolean default false,
    "is_black_owned" boolean default false,
    "is_family_friendly" boolean default false,
    "is_kids_friendly" boolean default false,
    "is_wheelchair_accessible" boolean default false,
    "custom_description" text,
    "custom_photos" text[] default '{}'::text[],
    "active_offer" text,
    "offer_expires_at" timestamp with time zone,
    "notify_on_signup" boolean default true,
    "last_push_sent_at" timestamp with time zone,
    "total_views" integer default 0,
    "total_taps" integer default 0,
    "total_offer_redemptions" integer default 0,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "notes" text
      );


alter table "public"."business_listings" enable row level security;


  create table "public"."collection_places" (
    "id" uuid not null default gen_random_uuid(),
    "collection_id" uuid not null,
    "user_id" uuid not null,
    "place_id" text not null,
    "place_name" text not null,
    "place_data" jsonb not null,
    "added_at" timestamp with time zone not null default now()
      );


alter table "public"."collection_places" enable row level security;


  create table "public"."gyg_links" (
    "id" bigint generated by default as identity not null,
    "created_at" timestamp with time zone not null default now(),
    "destination" text not null,
    "type" text not null,
    "url" text not null,
    "is_active" boolean
      );


alter table "public"."gyg_links" enable row level security;


  create table "public"."place_interactions" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "place_id" text not null,
    "place_name" text,
    "place_types" text[] default '{}'::text[],
    "price_level" integer,
    "interaction_type" text not null,
    "mood_context" text,
    "time_slot" text,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."place_interactions" enable row level security;


  create table "public"."place_reviews_cache" (
    "place_id" text not null,
    "reviews" jsonb not null default '[]'::jsonb,
    "last_updated" timestamp with time zone default now(),
    "expires_at" timestamp with time zone not null,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."place_reviews_cache" enable row level security;


  create table "public"."trip_collections" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "name" text not null,
    "emoji" text not null default '📍'::text,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."trip_collections" enable row level security;


  create table "public"."user_saved_places" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "place_id" text not null,
    "saved_at" timestamp with time zone default now(),
    "place_name" text,
    "place_data" jsonb
      );


alter table "public"."user_saved_places" enable row level security;


  create table "public"."user_stamp_milestones" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "milestone_key" text not null,
    "milestone_label" text not null,
    "unlocked_at" timestamp with time zone default now(),
    "reward_type" text,
    "reward_claimed" boolean default false
      );


alter table "public"."user_stamp_milestones" enable row level security;


  create table "public"."user_stamps" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "place_id" text not null,
    "place_name" text not null,
    "city" text,
    "business_listing_id" uuid,
    "mood" text,
    "scheduled_activity_id" integer,
    "earned_at" timestamp with time zone default now(),
    "created_at" timestamp with time zone default now()
      );


alter table "public"."user_stamps" enable row level security;


  create table "public"."visited_places" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "place_name" text not null,
    "city" text,
    "country" text,
    "lat" double precision not null,
    "lng" double precision not null,
    "mood" text,
    "mood_emoji" text,
    "energy_level" numeric,
    "notes" text,
    "visited_at" timestamp with time zone default now(),
    "created_at" timestamp with time zone default now()
      );


alter table "public"."visited_places" enable row level security;

alter table "public"."activities" drop column "duration_minutes";

alter table "public"."activities" drop column "energy_level_required";

alter table "public"."activities" drop column "image_url";

alter table "public"."activities" drop column "indoor_outdoor";

alter table "public"."activities" drop column "updated_at";

alter table "public"."activities" drop column "weather_suitability";

alter table "public"."activities" add column "energy_level" text;

alter table "public"."activities" alter column "category" drop not null;

alter table "public"."activities" alter column "mood_tags" drop default;

alter table "public"."activity_ratings" alter column "activity_name" drop not null;

alter table "public"."activity_ratings" alter column "completed_at" drop not null;

alter table "public"."activity_ratings" alter column "completed_at" set data type timestamp with time zone using "completed_at"::timestamp with time zone;

alter table "public"."activity_ratings" alter column "created_at" set data type timestamp with time zone using "created_at"::timestamp with time zone;

alter table "public"."activity_ratings" alter column "id" set default gen_random_uuid();

alter table "public"."activity_ratings" alter column "mood" drop not null;

alter table "public"."activity_ratings" alter column "stars" drop not null;

alter table "public"."activity_ratings" alter column "tags" drop default;

alter table "public"."activity_ratings" alter column "user_id" set not null;

alter table "public"."places_cache" drop column "location_lat";

alter table "public"."places_cache" drop column "location_lng";

alter table "public"."places_cache" drop column "query";

alter table "public"."places_cache" drop column "updated_at";

alter table "public"."places_cache" alter column "request_type" drop not null;

alter table "public"."profiles" drop column "avatar_url";

alter table "public"."profiles" drop column "last_active_at";

alter table "public"."profiles" drop column "level";

alter table "public"."profiles" drop column "location";

alter table "public"."profiles" drop column "location_sharing";

alter table "public"."profiles" drop column "mood_sharing";

alter table "public"."profiles" drop column "profile_visibility";

alter table "public"."profiles" drop column "show_age";

alter table "public"."profiles" drop column "show_email";

alter table "public"."profiles" drop column "total_points";

alter table "public"."profiles" add column "date_of_birth" date;

alter table "public"."profiles" add column "interests" text[] default ARRAY[]::text[];

alter table "public"."profiles" add column "places_visited_count" integer default 0;

alter table "public"."profiles" alter column "achievements" set default ARRAY[]::text[];

alter table "public"."profiles" alter column "notification_preferences" set default '{"push": true, "email": true}'::jsonb;

alter table "public"."profiles" alter column "travel_vibes" set default ARRAY['Spontaneous'::text, 'Social'::text, 'Relaxed'::text];

alter table "public"."scheduled_activities" add column "arrived_at" timestamp with time zone;

alter table "public"."scheduled_activities" add column "completed_at" timestamp with time zone;

alter table "public"."scheduled_activities" add column "scheduled_date" date;

alter table "public"."scheduled_activities" add column "status" text default 'planned'::text;

alter table "public"."subscriptions" drop column "cancel_at_period_end";

alter table "public"."subscriptions" drop column "current_period_end";

alter table "public"."subscriptions" drop column "stripe_customer_id";

alter table "public"."subscriptions" drop column "stripe_price_id";

alter table "public"."subscriptions" drop column "stripe_subscription_id";

alter table "public"."user_check_ins" alter column "activities" drop default;

alter table "public"."user_check_ins" alter column "id" set default gen_random_uuid();

alter table "public"."user_check_ins" alter column "id" set data type uuid using "id"::uuid;

alter table "public"."user_check_ins" alter column "mood" set not null;

alter table "public"."user_check_ins" alter column "timestamp" drop not null;

alter table "public"."user_preference_patterns" drop column "created_at";

alter table "public"."user_preference_patterns" add column "chat_interests" text[] default '{}'::text[];

alter table "public"."user_preference_patterns" add column "completed_activity_types" jsonb default '{}'::jsonb;

alter table "public"."user_preference_patterns" add column "mood_frequency" jsonb default '{}'::jsonb;

alter table "public"."user_preference_patterns" add column "price_level_preference" jsonb default '{}'::jsonb;

alter table "public"."user_preference_patterns" add column "saved_place_types" jsonb default '{}'::jsonb;

alter table "public"."user_preference_patterns" add column "skipped_place_types" jsonb default '{}'::jsonb;

alter table "public"."user_preference_patterns" add column "time_slot_preference" jsonb default '{}'::jsonb;

alter table "public"."user_preference_patterns" add column "total_interactions" integer default 0;

alter table "public"."user_preference_patterns" alter column "id" set default gen_random_uuid();

alter table "public"."user_preference_patterns" alter column "last_updated" set not null;

alter table "public"."user_preference_patterns" alter column "last_updated" set data type timestamp with time zone using "last_updated"::timestamp with time zone;

alter table "public"."user_preference_patterns" alter column "mood_activity_scores" set not null;

alter table "public"."user_preference_patterns" alter column "tag_counts" set not null;

alter table "public"."user_preference_patterns" alter column "time_preferences" set not null;

alter table "public"."user_preference_patterns" alter column "top_rated_activities" set not null;

alter table "public"."user_preference_patterns" alter column "top_rated_places" set not null;

alter table "public"."user_preference_patterns" alter column "user_id" set not null;

alter table "public"."user_preferences" drop column "auto_detect_location";

alter table "public"."user_preferences" drop column "default_latitude";

alter table "public"."user_preferences" drop column "default_location";

alter table "public"."user_preferences" drop column "default_longitude";

alter table "public"."user_preferences" drop column "gender";

alter table "public"."user_preferences" drop column "location";

alter table "public"."user_preferences" drop column "mood";

alter table "public"."user_preferences" add column "budget_level" text default 'Mid-Range'::text;

alter table "public"."user_preferences" add column "communication_style" text default 'friendly'::text;

alter table "public"."user_preferences" add column "favorite_moods" jsonb default '[]'::jsonb;

alter table "public"."user_preferences" add column "has_completed_onboarding" boolean default false;

alter table "public"."user_preferences" add column "has_completed_preferences" boolean default false;

alter table "public"."user_preferences" add column "home_base" text default 'Local Explorer'::text;

alter table "public"."user_preferences" add column "language_preference" text default 'en'::text;

alter table "public"."user_preferences" add column "mobility_requirements" jsonb default '[]'::jsonb;

alter table "public"."user_preferences" add column "planning_pace" text default 'Same Day Planner'::text;

alter table "public"."user_preferences" add column "preferred_time_slots" jsonb default '["morning", "afternoon", "evening"]'::jsonb;

alter table "public"."user_preferences" add column "selected_moods" jsonb default '[]'::jsonb;

alter table "public"."user_preferences" add column "travel_interests" jsonb default '[]'::jsonb;

alter table "public"."user_preferences" alter column "dietary_restrictions" set default '[]'::jsonb;

alter table "public"."user_preferences" alter column "dietary_restrictions" set data type jsonb using "dietary_restrictions"::jsonb;

alter table "public"."user_preferences" alter column "interests" set default '[]'::jsonb;

alter table "public"."user_preferences" alter column "interests" set data type jsonb using "interests"::jsonb;

alter table "public"."user_preferences" alter column "social_vibe" set default '[]'::jsonb;

alter table "public"."user_preferences" alter column "social_vibe" set data type jsonb using "social_vibe"::jsonb;

alter table "public"."user_preferences" alter column "travel_styles" set default '[]'::jsonb;

alter table "public"."user_preferences" alter column "travel_styles" set data type jsonb using "travel_styles"::jsonb;

alter table "public"."weather_cache" drop column "created_at";

alter table "public"."weather_cache" drop column "current_weather";

alter table "public"."weather_cache" drop column "forecast";

alter table "public"."weather_cache" drop column "latitude";

alter table "public"."weather_cache" drop column "longitude";

alter table "public"."weather_cache" add column "cached_at" timestamp with time zone default now();

alter table "public"."weather_cache" add column "weather_data" jsonb not null;

alter table "public"."weather_cache" alter column "expires_at" drop default;

alter table "public"."weather_cache" alter column "expires_at" set not null;

drop extension if exists "postgis";

CREATE UNIQUE INDEX activity_ratings_user_id_activity_id_key ON public.activity_ratings USING btree (user_id, activity_id);

CREATE INDEX ai_conversations_conversation_id_idx ON public.ai_conversations USING btree (conversation_id);

CREATE INDEX ai_conversations_created_at_idx ON public.ai_conversations USING btree (created_at);

CREATE UNIQUE INDEX ai_conversations_pkey ON public.ai_conversations USING btree (id);

CREATE INDEX ai_conversations_user_id_idx ON public.ai_conversations USING btree (user_id);

CREATE UNIQUE INDEX api_usage_alerts_pkey ON public.api_usage_alerts USING btree (id);

CREATE UNIQUE INDEX business_checkins_pkey ON public.business_checkins USING btree (id);

CREATE UNIQUE INDEX business_listings_pkey ON public.business_listings USING btree (id);

CREATE UNIQUE INDEX collection_places_collection_id_place_id_key ON public.collection_places USING btree (collection_id, place_id);

CREATE UNIQUE INDEX collection_places_pkey ON public.collection_places USING btree (id);

CREATE UNIQUE INDEX gyg_links_pkey ON public.gyg_links USING btree (id, destination, type, url);

CREATE INDEX idx_ai_conversations_thread ON public.ai_conversations USING btree (user_id, conversation_id, created_at);

CREATE INDEX idx_ai_conversations_user_conv ON public.ai_conversations USING btree (user_id, conversation_id);

CREATE INDEX idx_api_invocations_user_id ON public.api_invocations USING btree (user_id);

CREATE INDEX idx_business_checkins_business ON public.business_checkins USING btree (business_listing_id);

CREATE INDEX idx_business_checkins_date ON public.business_checkins USING btree (checked_in_at);

CREATE INDEX idx_business_checkins_place ON public.business_checkins USING btree (place_id);

CREATE INDEX idx_business_checkins_user ON public.business_checkins USING btree (user_id);

CREATE INDEX idx_business_listings_city ON public.business_listings USING btree (city);

CREATE INDEX idx_business_listings_place_id ON public.business_listings USING btree (place_id);

CREATE INDEX idx_business_listings_status ON public.business_listings USING btree (subscription_status);

CREATE INDEX idx_business_listings_tier ON public.business_listings USING btree (subscription_tier);

CREATE INDEX idx_collection_places_collection_id ON public.collection_places USING btree (collection_id);

CREATE INDEX idx_collection_places_user_id ON public.collection_places USING btree (user_id);

CREATE INDEX idx_moods_user_id ON public.moods USING btree (user_id);

CREATE INDEX idx_place_interactions_place_id ON public.place_interactions USING btree (place_id);

CREATE INDEX idx_place_interactions_user_id ON public.place_interactions USING btree (user_id, created_at DESC);

CREATE INDEX idx_place_reviews_cache_expires_at ON public.place_reviews_cache USING btree (expires_at);

CREATE INDEX idx_places_cache_key_expires ON public.places_cache USING btree (cache_key, expires_at);

CREATE INDEX idx_places_cache_user_id_fk ON public.places_cache USING btree (user_id);

CREATE INDEX idx_scheduled_activities_status ON public.scheduled_activities USING btree (user_id, status, scheduled_date);

CREATE INDEX idx_stamp_milestones_user ON public.user_stamp_milestones USING btree (user_id);

CREATE INDEX idx_trip_collections_user_id ON public.trip_collections USING btree (user_id);

CREATE INDEX idx_user_check_ins_user_id ON public.user_check_ins USING btree (user_id);

CREATE INDEX idx_user_preferences_completed ON public.user_preferences USING btree (has_completed_preferences);

CREATE INDEX idx_user_preferences_home_base ON public.user_preferences USING btree (home_base);

CREATE INDEX idx_user_preferences_selected_moods ON public.user_preferences USING gin (selected_moods);

CREATE INDEX idx_user_preferences_travel_interests ON public.user_preferences USING gin (travel_interests);

CREATE INDEX idx_user_stamps_business ON public.user_stamps USING btree (business_listing_id);

CREATE INDEX idx_user_stamps_earned_at ON public.user_stamps USING btree (earned_at);

CREATE INDEX idx_user_stamps_place_id ON public.user_stamps USING btree (place_id);

CREATE INDEX idx_user_stamps_scheduled_activity_id ON public.user_stamps USING btree (scheduled_activity_id);

CREATE INDEX idx_user_stamps_user_id ON public.user_stamps USING btree (user_id);

CREATE UNIQUE INDEX place_interactions_pkey ON public.place_interactions USING btree (id);

CREATE UNIQUE INDEX place_reviews_cache_pkey ON public.place_reviews_cache USING btree (place_id);

CREATE INDEX places_cache_cache_key_idx ON public.places_cache USING btree (cache_key);

CREATE INDEX places_cache_expires_at_idx ON public.places_cache USING btree (expires_at);

CREATE UNIQUE INDEX trip_collections_pkey ON public.trip_collections USING btree (id);

CREATE INDEX user_check_ins_user_created_idx ON public.user_check_ins USING btree (user_id, created_at);

CREATE UNIQUE INDEX user_preference_patterns_user_id_idx ON public.user_preference_patterns USING btree (user_id);

CREATE UNIQUE INDEX user_saved_places_pkey ON public.user_saved_places USING btree (id);

CREATE INDEX user_saved_places_user_id_idx ON public.user_saved_places USING btree (user_id);

CREATE UNIQUE INDEX user_saved_places_user_id_place_id_key ON public.user_saved_places USING btree (user_id, place_id);

CREATE UNIQUE INDEX user_stamp_milestones_pkey ON public.user_stamp_milestones USING btree (id);

CREATE UNIQUE INDEX user_stamp_milestones_user_id_milestone_key_key ON public.user_stamp_milestones USING btree (user_id, milestone_key);

CREATE UNIQUE INDEX user_stamps_pkey ON public.user_stamps USING btree (id);

CREATE UNIQUE INDEX visited_places_pkey ON public.visited_places USING btree (id);

CREATE INDEX visited_places_user_id_idx ON public.visited_places USING btree (user_id);

CREATE UNIQUE INDEX weather_cache_location_key ON public.weather_cache USING btree (location);

CREATE UNIQUE INDEX user_check_ins_pkey ON public.user_check_ins USING btree (id);

alter table "public"."ai_conversations" add constraint "ai_conversations_pkey" PRIMARY KEY using index "ai_conversations_pkey";

alter table "public"."api_usage_alerts" add constraint "api_usage_alerts_pkey" PRIMARY KEY using index "api_usage_alerts_pkey";

alter table "public"."business_checkins" add constraint "business_checkins_pkey" PRIMARY KEY using index "business_checkins_pkey";

alter table "public"."business_listings" add constraint "business_listings_pkey" PRIMARY KEY using index "business_listings_pkey";

alter table "public"."collection_places" add constraint "collection_places_pkey" PRIMARY KEY using index "collection_places_pkey";

alter table "public"."gyg_links" add constraint "gyg_links_pkey" PRIMARY KEY using index "gyg_links_pkey";

alter table "public"."place_interactions" add constraint "place_interactions_pkey" PRIMARY KEY using index "place_interactions_pkey";

alter table "public"."place_reviews_cache" add constraint "place_reviews_cache_pkey" PRIMARY KEY using index "place_reviews_cache_pkey";

alter table "public"."trip_collections" add constraint "trip_collections_pkey" PRIMARY KEY using index "trip_collections_pkey";

alter table "public"."user_saved_places" add constraint "user_saved_places_pkey" PRIMARY KEY using index "user_saved_places_pkey";

alter table "public"."user_stamp_milestones" add constraint "user_stamp_milestones_pkey" PRIMARY KEY using index "user_stamp_milestones_pkey";

alter table "public"."user_stamps" add constraint "user_stamps_pkey" PRIMARY KEY using index "user_stamps_pkey";

alter table "public"."visited_places" add constraint "visited_places_pkey" PRIMARY KEY using index "visited_places_pkey";

alter table "public"."activity_ratings" add constraint "activity_ratings_activity_id_not_empty" CHECK ((TRIM(BOTH FROM activity_id) <> ''::text)) not valid;

alter table "public"."activity_ratings" validate constraint "activity_ratings_activity_id_not_empty";

alter table "public"."activity_ratings" add constraint "activity_ratings_rating_check" CHECK (((stars >= 1) AND (stars <= 5))) not valid;

alter table "public"."activity_ratings" validate constraint "activity_ratings_rating_check";

alter table "public"."activity_ratings" add constraint "activity_ratings_user_id_activity_id_key" UNIQUE using index "activity_ratings_user_id_activity_id_key";

alter table "public"."ai_conversations" add constraint "ai_conversations_role_check" CHECK ((role = ANY (ARRAY['user'::text, 'assistant'::text, 'system'::text]))) not valid;

alter table "public"."ai_conversations" validate constraint "ai_conversations_role_check";

alter table "public"."ai_conversations" add constraint "ai_conversations_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."ai_conversations" validate constraint "ai_conversations_user_id_fkey";

alter table "public"."business_checkins" add constraint "business_checkins_business_listing_id_fkey" FOREIGN KEY (business_listing_id) REFERENCES public.business_listings(id) ON DELETE CASCADE not valid;

alter table "public"."business_checkins" validate constraint "business_checkins_business_listing_id_fkey";

alter table "public"."business_checkins" add constraint "business_checkins_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."business_checkins" validate constraint "business_checkins_user_id_fkey";

alter table "public"."business_listings" add constraint "business_listings_subscription_status_check" CHECK ((subscription_status = ANY (ARRAY['active'::text, 'inactive'::text, 'trial'::text, 'cancelled'::text]))) not valid;

alter table "public"."business_listings" validate constraint "business_listings_subscription_status_check";

alter table "public"."business_listings" add constraint "business_listings_subscription_tier_check" CHECK ((subscription_tier = ANY (ARRAY['basic'::text, 'featured'::text, 'premium'::text]))) not valid;

alter table "public"."business_listings" validate constraint "business_listings_subscription_tier_check";

alter table "public"."collection_places" add constraint "collection_places_collection_id_fkey" FOREIGN KEY (collection_id) REFERENCES public.trip_collections(id) ON DELETE CASCADE not valid;

alter table "public"."collection_places" validate constraint "collection_places_collection_id_fkey";

alter table "public"."collection_places" add constraint "collection_places_collection_id_place_id_key" UNIQUE using index "collection_places_collection_id_place_id_key";

alter table "public"."collection_places" add constraint "collection_places_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."collection_places" validate constraint "collection_places_user_id_fkey";

alter table "public"."moods" add constraint "moods_mood_not_empty" CHECK ((TRIM(BOTH FROM mood) <> ''::text)) not valid;

alter table "public"."moods" validate constraint "moods_mood_not_empty";

alter table "public"."place_interactions" add constraint "place_interactions_interaction_type_check" CHECK ((interaction_type = ANY (ARRAY['tapped'::text, 'saved'::text, 'added_to_day'::text, 'completed'::text, 'skipped'::text, 'rated_positive'::text, 'rated_negative'::text]))) not valid;

alter table "public"."place_interactions" validate constraint "place_interactions_interaction_type_check";

alter table "public"."place_interactions" add constraint "place_interactions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."place_interactions" validate constraint "place_interactions_user_id_fkey";

alter table "public"."scheduled_activities" add constraint "scheduled_activities_status_check" CHECK ((status = ANY (ARRAY['planned'::text, 'arrived'::text, 'completed'::text, 'skipped'::text]))) not valid;

alter table "public"."scheduled_activities" validate constraint "scheduled_activities_status_check";

alter table "public"."trip_collections" add constraint "trip_collections_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."trip_collections" validate constraint "trip_collections_user_id_fkey";

alter table "public"."user_check_ins" add constraint "user_check_ins_mood_not_empty" CHECK ((TRIM(BOTH FROM mood) <> ''::text)) not valid;

alter table "public"."user_check_ins" validate constraint "user_check_ins_mood_not_empty";

alter table "public"."user_saved_places" add constraint "user_saved_places_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_saved_places" validate constraint "user_saved_places_user_id_fkey";

alter table "public"."user_saved_places" add constraint "user_saved_places_user_id_place_id_key" UNIQUE using index "user_saved_places_user_id_place_id_key";

alter table "public"."user_stamp_milestones" add constraint "user_stamp_milestones_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_stamp_milestones" validate constraint "user_stamp_milestones_user_id_fkey";

alter table "public"."user_stamp_milestones" add constraint "user_stamp_milestones_user_id_milestone_key_key" UNIQUE using index "user_stamp_milestones_user_id_milestone_key_key";

alter table "public"."user_stamps" add constraint "user_stamps_business_listing_id_fkey" FOREIGN KEY (business_listing_id) REFERENCES public.business_listings(id) ON DELETE SET NULL not valid;

alter table "public"."user_stamps" validate constraint "user_stamps_business_listing_id_fkey";

alter table "public"."user_stamps" add constraint "user_stamps_scheduled_activity_id_fkey" FOREIGN KEY (scheduled_activity_id) REFERENCES public.scheduled_activities(id) ON DELETE SET NULL not valid;

alter table "public"."user_stamps" validate constraint "user_stamps_scheduled_activity_id_fkey";

alter table "public"."user_stamps" add constraint "user_stamps_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_stamps" validate constraint "user_stamps_user_id_fkey";

alter table "public"."visited_places" add constraint "visited_places_energy_level_check" CHECK (((energy_level >= (1)::numeric) AND (energy_level <= (10)::numeric))) not valid;

alter table "public"."visited_places" validate constraint "visited_places_energy_level_check";

alter table "public"."visited_places" add constraint "visited_places_place_name_not_empty" CHECK ((TRIM(BOTH FROM place_name) <> ''::text)) not valid;

alter table "public"."visited_places" validate constraint "visited_places_place_name_not_empty";

alter table "public"."visited_places" add constraint "visited_places_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."visited_places" validate constraint "visited_places_user_id_fkey";

alter table "public"."weather_cache" add constraint "weather_cache_location_key" UNIQUE using index "weather_cache_location_key";

alter table "public"."places_cache" add constraint "places_cache_request_type_check" CHECK ((request_type = ANY (ARRAY['search'::text, 'autocomplete'::text, 'details'::text, 'photos'::text, 'nearby'::text, 'explore'::text]))) not valid;

alter table "public"."places_cache" validate constraint "places_cache_request_type_check";

alter table "public"."profiles" add constraint "profiles_gender_check" CHECK ((gender = ANY (ARRAY['man'::text, 'woman'::text, 'non_binary'::text, 'prefer_not_to_say'::text]))) not valid;

alter table "public"."profiles" validate constraint "profiles_gender_check";

set check_function_bodies = off;

create or replace view "public"."api_usage_summary" as  SELECT date_trunc('hour'::text, created_at) AS hour,
    function_slug,
    operation,
    count(*) AS total_calls,
    count(*) FILTER (WHERE (http_status = 200)) AS successful_calls,
    count(*) FILTER (WHERE (http_status >= 400)) AS failed_calls,
    round(avg(duration_ms)) AS avg_duration_ms
   FROM public.api_invocations
  WHERE (created_at > (now() - '24:00:00'::interval))
  GROUP BY (date_trunc('hour'::text, created_at)), function_slug, operation
  ORDER BY (date_trunc('hour'::text, created_at)) DESC, (count(*)) DESC;


CREATE OR REPLACE FUNCTION public.check_api_usage_spike()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  places_calls_1h integer;
  moody_calls_1h integer;
  warning_msg text := '';
BEGIN
  -- Count places calls in last hour
  SELECT COUNT(*) INTO places_calls_1h
  FROM public.api_invocations
  WHERE function_slug = 'places'
    AND created_at > now() - interval '1 hour';

  -- Count moody calls in last hour  
  SELECT COUNT(*) INTO moody_calls_1h
  FROM public.api_invocations
  WHERE function_slug = 'moody'
    AND operation = 'get_explore'
    AND created_at > now() - interval '1 hour';

  -- Alert thresholds
  -- places: more than 50/hour suggests cache is broken
  -- moody explore: more than 20/hour suggests cache is broken
  IF places_calls_1h > 50 THEN
    warning_msg := warning_msg || 'ALERT: places function called ' || places_calls_1h || ' times in last hour (threshold: 50). Cache may be broken. ';
  END IF;

  IF moody_calls_1h > 20 THEN
    warning_msg := warning_msg || 'ALERT: moody get_explore called ' || moody_calls_1h || ' times in last hour (threshold: 20). Cache may be broken. ';
  END IF;

  IF warning_msg = '' THEN
    RETURN 'OK: places=' || places_calls_1h || '/hr moody_explore=' || moody_calls_1h || '/hr — all within normal range';
  END IF;

  -- Log the alert
  INSERT INTO public.api_usage_alerts (
    places_calls_last_hour,
    moody_calls_last_hour,
    alert_reason
  ) VALUES (
    places_calls_1h,
    moody_calls_1h,
    warning_msg
  );

  RETURN warning_msg;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.enforce_cache_expiry()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.expires_at IS NULL OR NEW.expires_at < NOW() + INTERVAL '29 days' THEN
    NEW.expires_at := NOW() + INTERVAL '30 days';
  END IF;
  NEW.user_id := NULL;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.enforce_reviews_cache_expiry()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.expires_at IS NULL OR NEW.expires_at < NOW() + INTERVAL '2 days' THEN
    NEW.expires_at := NOW() + INTERVAL '3 days';
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.enforce_weather_cache_expiry()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.expires_at IS NULL OR NEW.expires_at < NOW() + INTERVAL '23 hours' THEN
    NEW.expires_at := NOW() + INTERVAL '24 hours';
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_traveler_count()
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT count(*)::int FROM public.profiles;
$function$
;

CREATE OR REPLACE FUNCTION public.increment_business_taps(listing_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN UPDATE public.business_listings SET total_taps = total_taps + 1, updated_at = now() WHERE id = listing_id; END;
$function$
;

CREATE OR REPLACE FUNCTION public.increment_business_views(listing_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN UPDATE public.business_listings SET total_views = total_views + 1, updated_at = now() WHERE id = listing_id; END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_business_listings_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_taste_profile(p_user_id uuid, p_place_id text, p_place_name text, p_place_types text[], p_price_level integer, p_interaction_type text, p_mood_context text DEFAULT NULL::text, p_time_slot text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_weight numeric;
  v_type text;
BEGIN
  -- Weight per interaction type
  -- Positive signals
  v_weight := CASE p_interaction_type
    WHEN 'completed'       THEN 3.0  -- strongest: they actually went
    WHEN 'rated_positive'  THEN 2.5
    WHEN 'saved'           THEN 2.0  -- strong: they saved it
    WHEN 'added_to_day'    THEN 1.5  -- good: added to plan
    WHEN 'tapped'          THEN 0.5  -- weak: just looked
    WHEN 'skipped'         THEN -1.0 -- negative: not interested
    WHEN 'rated_negative'  THEN -2.0 -- strong negative
    ELSE 0
  END;

  -- Log the raw interaction
  INSERT INTO public.place_interactions (
    user_id, place_id, place_name, place_types,
    price_level, interaction_type, mood_context, time_slot
  ) VALUES (
    p_user_id, p_place_id, p_place_name, p_place_types,
    p_price_level, p_interaction_type, p_mood_context, p_time_slot
  );

  -- Upsert preference patterns
  INSERT INTO public.user_preference_patterns (user_id, last_updated)
  VALUES (p_user_id, now())
  ON CONFLICT (user_id) DO NOTHING;

  -- Update place type scores
  IF array_length(p_place_types, 1) > 0 THEN
    FOREACH v_type IN ARRAY p_place_types LOOP
      IF v_weight > 0 THEN
        UPDATE public.user_preference_patterns
        SET saved_place_types = jsonb_set(
          COALESCE(saved_place_types, '{}'::jsonb),
          ARRAY[v_type],
          to_jsonb(COALESCE((saved_place_types->>v_type)::numeric, 0) + v_weight)
        ),
        total_interactions = total_interactions + 1,
        last_updated = now()
        WHERE user_id = p_user_id;
      ELSE
        UPDATE public.user_preference_patterns
        SET skipped_place_types = jsonb_set(
          COALESCE(skipped_place_types, '{}'::jsonb),
          ARRAY[v_type],
          to_jsonb(COALESCE((skipped_place_types->>v_type)::numeric, 0) + abs(v_weight))
        ),
        last_updated = now()
        WHERE user_id = p_user_id;
      END IF;
    END LOOP;
  END IF;

  -- Update mood frequency
  IF p_mood_context IS NOT NULL AND v_weight > 0 THEN
    UPDATE public.user_preference_patterns
    SET mood_frequency = jsonb_set(
      COALESCE(mood_frequency, '{}'::jsonb),
      ARRAY[p_mood_context],
      to_jsonb(COALESCE((mood_frequency->>p_mood_context)::integer, 0) + 1)
    ),
    last_updated = now()
    WHERE user_id = p_user_id;
  END IF;

  -- Update price level preference
  IF p_price_level IS NOT NULL AND v_weight > 0 THEN
    UPDATE public.user_preference_patterns
    SET price_level_preference = jsonb_set(
      COALESCE(price_level_preference, '{}'::jsonb),
      ARRAY[p_price_level::text],
      to_jsonb(COALESCE((price_level_preference->>p_price_level::text)::numeric, 0) + v_weight)
    ),
    last_updated = now()
    WHERE user_id = p_user_id;
  END IF;

  -- Track top rated places (keep last 50)
  IF p_interaction_type IN ('saved', 'completed', 'rated_positive') THEN
    UPDATE public.user_preference_patterns
    SET top_rated_places = (
      SELECT array_agg(DISTINCT place) 
      FROM (
        SELECT unnest(array_append(top_rated_places, p_place_id)) as place
        LIMIT 50
      ) t
    ),
    last_updated = now()
    WHERE user_id = p_user_id;
  END IF;

END;
$function$
;

create or replace view "public"."user_taste_summary" as  SELECT user_id,
    total_interactions,
    mood_frequency,
    saved_place_types,
    skipped_place_types,
    price_level_preference,
    top_rated_places,
    chat_interests,
    last_updated,
    ( SELECT jsonb_agg(jsonb_each_text.key ORDER BY (jsonb_each_text.value)::numeric DESC) AS jsonb_agg
           FROM jsonb_each_text(COALESCE(upr.saved_place_types, '{}'::jsonb)) jsonb_each_text(key, value)
         LIMIT 5) AS top_place_types,
    ( SELECT jsonb_each_text.key
           FROM jsonb_each_text(COALESCE(upr.mood_frequency, '{}'::jsonb)) jsonb_each_text(key, value)
          ORDER BY (jsonb_each_text.value)::integer DESC
         LIMIT 1) AS dominant_mood,
    ( SELECT count(*) AS count
           FROM public.user_saved_places
          WHERE (user_saved_places.user_id = upr.user_id)) AS total_saves,
    ( SELECT count(*) AS count
           FROM public.scheduled_activities
          WHERE ((scheduled_activities.user_id = upr.user_id) AND (scheduled_activities.status = 'completed'::text))) AS total_completed
   FROM public.user_preference_patterns upr;


CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Create profile row
  INSERT INTO public.profiles (id, username, email, full_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  )
  ON CONFLICT (id) DO NOTHING;

  -- Create user_preferences row
  INSERT INTO public.user_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$function$
;

grant delete on table "public"."ai_conversations" to "anon";

grant insert on table "public"."ai_conversations" to "anon";

grant references on table "public"."ai_conversations" to "anon";

grant select on table "public"."ai_conversations" to "anon";

grant trigger on table "public"."ai_conversations" to "anon";

grant truncate on table "public"."ai_conversations" to "anon";

grant update on table "public"."ai_conversations" to "anon";

grant delete on table "public"."ai_conversations" to "authenticated";

grant insert on table "public"."ai_conversations" to "authenticated";

grant references on table "public"."ai_conversations" to "authenticated";

grant select on table "public"."ai_conversations" to "authenticated";

grant trigger on table "public"."ai_conversations" to "authenticated";

grant truncate on table "public"."ai_conversations" to "authenticated";

grant update on table "public"."ai_conversations" to "authenticated";

grant delete on table "public"."ai_conversations" to "service_role";

grant insert on table "public"."ai_conversations" to "service_role";

grant references on table "public"."ai_conversations" to "service_role";

grant select on table "public"."ai_conversations" to "service_role";

grant trigger on table "public"."ai_conversations" to "service_role";

grant truncate on table "public"."ai_conversations" to "service_role";

grant update on table "public"."ai_conversations" to "service_role";

grant delete on table "public"."api_usage_alerts" to "anon";

grant insert on table "public"."api_usage_alerts" to "anon";

grant references on table "public"."api_usage_alerts" to "anon";

grant select on table "public"."api_usage_alerts" to "anon";

grant trigger on table "public"."api_usage_alerts" to "anon";

grant truncate on table "public"."api_usage_alerts" to "anon";

grant update on table "public"."api_usage_alerts" to "anon";

grant delete on table "public"."api_usage_alerts" to "authenticated";

grant insert on table "public"."api_usage_alerts" to "authenticated";

grant references on table "public"."api_usage_alerts" to "authenticated";

grant select on table "public"."api_usage_alerts" to "authenticated";

grant trigger on table "public"."api_usage_alerts" to "authenticated";

grant truncate on table "public"."api_usage_alerts" to "authenticated";

grant update on table "public"."api_usage_alerts" to "authenticated";

grant delete on table "public"."api_usage_alerts" to "service_role";

grant insert on table "public"."api_usage_alerts" to "service_role";

grant references on table "public"."api_usage_alerts" to "service_role";

grant select on table "public"."api_usage_alerts" to "service_role";

grant trigger on table "public"."api_usage_alerts" to "service_role";

grant truncate on table "public"."api_usage_alerts" to "service_role";

grant update on table "public"."api_usage_alerts" to "service_role";

grant delete on table "public"."business_checkins" to "anon";

grant insert on table "public"."business_checkins" to "anon";

grant references on table "public"."business_checkins" to "anon";

grant select on table "public"."business_checkins" to "anon";

grant trigger on table "public"."business_checkins" to "anon";

grant truncate on table "public"."business_checkins" to "anon";

grant update on table "public"."business_checkins" to "anon";

grant delete on table "public"."business_checkins" to "authenticated";

grant insert on table "public"."business_checkins" to "authenticated";

grant references on table "public"."business_checkins" to "authenticated";

grant select on table "public"."business_checkins" to "authenticated";

grant trigger on table "public"."business_checkins" to "authenticated";

grant truncate on table "public"."business_checkins" to "authenticated";

grant update on table "public"."business_checkins" to "authenticated";

grant delete on table "public"."business_checkins" to "service_role";

grant insert on table "public"."business_checkins" to "service_role";

grant references on table "public"."business_checkins" to "service_role";

grant select on table "public"."business_checkins" to "service_role";

grant trigger on table "public"."business_checkins" to "service_role";

grant truncate on table "public"."business_checkins" to "service_role";

grant update on table "public"."business_checkins" to "service_role";

grant delete on table "public"."business_listings" to "anon";

grant insert on table "public"."business_listings" to "anon";

grant references on table "public"."business_listings" to "anon";

grant select on table "public"."business_listings" to "anon";

grant trigger on table "public"."business_listings" to "anon";

grant truncate on table "public"."business_listings" to "anon";

grant update on table "public"."business_listings" to "anon";

grant delete on table "public"."business_listings" to "authenticated";

grant insert on table "public"."business_listings" to "authenticated";

grant references on table "public"."business_listings" to "authenticated";

grant select on table "public"."business_listings" to "authenticated";

grant trigger on table "public"."business_listings" to "authenticated";

grant truncate on table "public"."business_listings" to "authenticated";

grant update on table "public"."business_listings" to "authenticated";

grant delete on table "public"."business_listings" to "service_role";

grant insert on table "public"."business_listings" to "service_role";

grant references on table "public"."business_listings" to "service_role";

grant select on table "public"."business_listings" to "service_role";

grant trigger on table "public"."business_listings" to "service_role";

grant truncate on table "public"."business_listings" to "service_role";

grant update on table "public"."business_listings" to "service_role";

grant delete on table "public"."collection_places" to "anon";

grant insert on table "public"."collection_places" to "anon";

grant references on table "public"."collection_places" to "anon";

grant select on table "public"."collection_places" to "anon";

grant trigger on table "public"."collection_places" to "anon";

grant truncate on table "public"."collection_places" to "anon";

grant update on table "public"."collection_places" to "anon";

grant delete on table "public"."collection_places" to "authenticated";

grant insert on table "public"."collection_places" to "authenticated";

grant references on table "public"."collection_places" to "authenticated";

grant select on table "public"."collection_places" to "authenticated";

grant trigger on table "public"."collection_places" to "authenticated";

grant truncate on table "public"."collection_places" to "authenticated";

grant update on table "public"."collection_places" to "authenticated";

grant delete on table "public"."collection_places" to "service_role";

grant insert on table "public"."collection_places" to "service_role";

grant references on table "public"."collection_places" to "service_role";

grant select on table "public"."collection_places" to "service_role";

grant trigger on table "public"."collection_places" to "service_role";

grant truncate on table "public"."collection_places" to "service_role";

grant update on table "public"."collection_places" to "service_role";

grant delete on table "public"."gyg_links" to "anon";

grant insert on table "public"."gyg_links" to "anon";

grant references on table "public"."gyg_links" to "anon";

grant select on table "public"."gyg_links" to "anon";

grant trigger on table "public"."gyg_links" to "anon";

grant truncate on table "public"."gyg_links" to "anon";

grant update on table "public"."gyg_links" to "anon";

grant delete on table "public"."gyg_links" to "authenticated";

grant insert on table "public"."gyg_links" to "authenticated";

grant references on table "public"."gyg_links" to "authenticated";

grant select on table "public"."gyg_links" to "authenticated";

grant trigger on table "public"."gyg_links" to "authenticated";

grant truncate on table "public"."gyg_links" to "authenticated";

grant update on table "public"."gyg_links" to "authenticated";

grant delete on table "public"."gyg_links" to "service_role";

grant insert on table "public"."gyg_links" to "service_role";

grant references on table "public"."gyg_links" to "service_role";

grant select on table "public"."gyg_links" to "service_role";

grant trigger on table "public"."gyg_links" to "service_role";

grant truncate on table "public"."gyg_links" to "service_role";

grant update on table "public"."gyg_links" to "service_role";

grant delete on table "public"."place_interactions" to "anon";

grant insert on table "public"."place_interactions" to "anon";

grant references on table "public"."place_interactions" to "anon";

grant select on table "public"."place_interactions" to "anon";

grant trigger on table "public"."place_interactions" to "anon";

grant truncate on table "public"."place_interactions" to "anon";

grant update on table "public"."place_interactions" to "anon";

grant delete on table "public"."place_interactions" to "authenticated";

grant insert on table "public"."place_interactions" to "authenticated";

grant references on table "public"."place_interactions" to "authenticated";

grant select on table "public"."place_interactions" to "authenticated";

grant trigger on table "public"."place_interactions" to "authenticated";

grant truncate on table "public"."place_interactions" to "authenticated";

grant update on table "public"."place_interactions" to "authenticated";

grant delete on table "public"."place_interactions" to "service_role";

grant insert on table "public"."place_interactions" to "service_role";

grant references on table "public"."place_interactions" to "service_role";

grant select on table "public"."place_interactions" to "service_role";

grant trigger on table "public"."place_interactions" to "service_role";

grant truncate on table "public"."place_interactions" to "service_role";

grant update on table "public"."place_interactions" to "service_role";

grant delete on table "public"."place_reviews_cache" to "anon";

grant insert on table "public"."place_reviews_cache" to "anon";

grant references on table "public"."place_reviews_cache" to "anon";

grant select on table "public"."place_reviews_cache" to "anon";

grant trigger on table "public"."place_reviews_cache" to "anon";

grant truncate on table "public"."place_reviews_cache" to "anon";

grant update on table "public"."place_reviews_cache" to "anon";

grant delete on table "public"."place_reviews_cache" to "authenticated";

grant insert on table "public"."place_reviews_cache" to "authenticated";

grant references on table "public"."place_reviews_cache" to "authenticated";

grant select on table "public"."place_reviews_cache" to "authenticated";

grant trigger on table "public"."place_reviews_cache" to "authenticated";

grant truncate on table "public"."place_reviews_cache" to "authenticated";

grant update on table "public"."place_reviews_cache" to "authenticated";

grant delete on table "public"."place_reviews_cache" to "service_role";

grant insert on table "public"."place_reviews_cache" to "service_role";

grant references on table "public"."place_reviews_cache" to "service_role";

grant select on table "public"."place_reviews_cache" to "service_role";

grant trigger on table "public"."place_reviews_cache" to "service_role";

grant truncate on table "public"."place_reviews_cache" to "service_role";

grant update on table "public"."place_reviews_cache" to "service_role";

grant delete on table "public"."trip_collections" to "anon";

grant insert on table "public"."trip_collections" to "anon";

grant references on table "public"."trip_collections" to "anon";

grant select on table "public"."trip_collections" to "anon";

grant trigger on table "public"."trip_collections" to "anon";

grant truncate on table "public"."trip_collections" to "anon";

grant update on table "public"."trip_collections" to "anon";

grant delete on table "public"."trip_collections" to "authenticated";

grant insert on table "public"."trip_collections" to "authenticated";

grant references on table "public"."trip_collections" to "authenticated";

grant select on table "public"."trip_collections" to "authenticated";

grant trigger on table "public"."trip_collections" to "authenticated";

grant truncate on table "public"."trip_collections" to "authenticated";

grant update on table "public"."trip_collections" to "authenticated";

grant delete on table "public"."trip_collections" to "service_role";

grant insert on table "public"."trip_collections" to "service_role";

grant references on table "public"."trip_collections" to "service_role";

grant select on table "public"."trip_collections" to "service_role";

grant trigger on table "public"."trip_collections" to "service_role";

grant truncate on table "public"."trip_collections" to "service_role";

grant update on table "public"."trip_collections" to "service_role";

grant delete on table "public"."user_saved_places" to "anon";

grant insert on table "public"."user_saved_places" to "anon";

grant references on table "public"."user_saved_places" to "anon";

grant select on table "public"."user_saved_places" to "anon";

grant trigger on table "public"."user_saved_places" to "anon";

grant truncate on table "public"."user_saved_places" to "anon";

grant update on table "public"."user_saved_places" to "anon";

grant delete on table "public"."user_saved_places" to "authenticated";

grant insert on table "public"."user_saved_places" to "authenticated";

grant references on table "public"."user_saved_places" to "authenticated";

grant select on table "public"."user_saved_places" to "authenticated";

grant trigger on table "public"."user_saved_places" to "authenticated";

grant truncate on table "public"."user_saved_places" to "authenticated";

grant update on table "public"."user_saved_places" to "authenticated";

grant delete on table "public"."user_saved_places" to "service_role";

grant insert on table "public"."user_saved_places" to "service_role";

grant references on table "public"."user_saved_places" to "service_role";

grant select on table "public"."user_saved_places" to "service_role";

grant trigger on table "public"."user_saved_places" to "service_role";

grant truncate on table "public"."user_saved_places" to "service_role";

grant update on table "public"."user_saved_places" to "service_role";

grant delete on table "public"."user_stamp_milestones" to "anon";

grant insert on table "public"."user_stamp_milestones" to "anon";

grant references on table "public"."user_stamp_milestones" to "anon";

grant select on table "public"."user_stamp_milestones" to "anon";

grant trigger on table "public"."user_stamp_milestones" to "anon";

grant truncate on table "public"."user_stamp_milestones" to "anon";

grant update on table "public"."user_stamp_milestones" to "anon";

grant delete on table "public"."user_stamp_milestones" to "authenticated";

grant insert on table "public"."user_stamp_milestones" to "authenticated";

grant references on table "public"."user_stamp_milestones" to "authenticated";

grant select on table "public"."user_stamp_milestones" to "authenticated";

grant trigger on table "public"."user_stamp_milestones" to "authenticated";

grant truncate on table "public"."user_stamp_milestones" to "authenticated";

grant update on table "public"."user_stamp_milestones" to "authenticated";

grant delete on table "public"."user_stamp_milestones" to "service_role";

grant insert on table "public"."user_stamp_milestones" to "service_role";

grant references on table "public"."user_stamp_milestones" to "service_role";

grant select on table "public"."user_stamp_milestones" to "service_role";

grant trigger on table "public"."user_stamp_milestones" to "service_role";

grant truncate on table "public"."user_stamp_milestones" to "service_role";

grant update on table "public"."user_stamp_milestones" to "service_role";

grant delete on table "public"."user_stamps" to "anon";

grant insert on table "public"."user_stamps" to "anon";

grant references on table "public"."user_stamps" to "anon";

grant select on table "public"."user_stamps" to "anon";

grant trigger on table "public"."user_stamps" to "anon";

grant truncate on table "public"."user_stamps" to "anon";

grant update on table "public"."user_stamps" to "anon";

grant delete on table "public"."user_stamps" to "authenticated";

grant insert on table "public"."user_stamps" to "authenticated";

grant references on table "public"."user_stamps" to "authenticated";

grant select on table "public"."user_stamps" to "authenticated";

grant trigger on table "public"."user_stamps" to "authenticated";

grant truncate on table "public"."user_stamps" to "authenticated";

grant update on table "public"."user_stamps" to "authenticated";

grant delete on table "public"."user_stamps" to "service_role";

grant insert on table "public"."user_stamps" to "service_role";

grant references on table "public"."user_stamps" to "service_role";

grant select on table "public"."user_stamps" to "service_role";

grant trigger on table "public"."user_stamps" to "service_role";

grant truncate on table "public"."user_stamps" to "service_role";

grant update on table "public"."user_stamps" to "service_role";

grant delete on table "public"."visited_places" to "anon";

grant insert on table "public"."visited_places" to "anon";

grant references on table "public"."visited_places" to "anon";

grant select on table "public"."visited_places" to "anon";

grant trigger on table "public"."visited_places" to "anon";

grant truncate on table "public"."visited_places" to "anon";

grant update on table "public"."visited_places" to "anon";

grant delete on table "public"."visited_places" to "authenticated";

grant insert on table "public"."visited_places" to "authenticated";

grant references on table "public"."visited_places" to "authenticated";

grant select on table "public"."visited_places" to "authenticated";

grant trigger on table "public"."visited_places" to "authenticated";

grant truncate on table "public"."visited_places" to "authenticated";

grant update on table "public"."visited_places" to "authenticated";

grant delete on table "public"."visited_places" to "service_role";

grant insert on table "public"."visited_places" to "service_role";

grant references on table "public"."visited_places" to "service_role";

grant select on table "public"."visited_places" to "service_role";

grant trigger on table "public"."visited_places" to "service_role";

grant truncate on table "public"."visited_places" to "service_role";

grant update on table "public"."visited_places" to "service_role";


  create policy "Users can delete own ratings"
  on "public"."activity_ratings"
  as permissive
  for delete
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can insert own ratings"
  on "public"."activity_ratings"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can update own ratings"
  on "public"."activity_ratings"
  as permissive
  for update
  to public
using ((( SELECT auth.uid() AS uid) = user_id))
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can view own ratings"
  on "public"."activity_ratings"
  as permissive
  for select
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can delete own conversations"
  on "public"."ai_conversations"
  as permissive
  for delete
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can insert own conversations"
  on "public"."ai_conversations"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can view own conversations"
  on "public"."ai_conversations"
  as permissive
  for select
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "No direct user access to api_invocations"
  on "public"."api_invocations"
  as permissive
  for all
  to public
using (false);



  create policy "No direct user access to api_rate_buckets"
  on "public"."api_rate_buckets"
  as permissive
  for all
  to public
using (false);



  create policy "Service role only"
  on "public"."api_usage_alerts"
  as permissive
  for all
  to public
using ((auth.role() = 'service_role'::text));



  create policy "Users can insert own checkins"
  on "public"."business_checkins"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can read own checkins"
  on "public"."business_checkins"
  as permissive
  for select
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can update own checkins"
  on "public"."business_checkins"
  as permissive
  for update
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Active listings are publicly readable"
  on "public"."business_listings"
  as permissive
  for select
  to public
using ((subscription_status = ANY (ARRAY['active'::text, 'trial'::text])));



  create policy "Users manage own collection places"
  on "public"."collection_places"
  as permissive
  for all
  to public
using ((( SELECT auth.uid() AS uid) IN ( SELECT trip_collections.user_id
   FROM public.trip_collections
  WHERE (trip_collections.id = collection_places.collection_id))))
with check ((( SELECT auth.uid() AS uid) IN ( SELECT trip_collections.user_id
   FROM public.trip_collections
  WHERE (trip_collections.id = collection_places.collection_id))));



  create policy "Allow public read"
  on "public"."gyg_links"
  as permissive
  for select
  to public
using (true);



  create policy "Users can delete own moods"
  on "public"."moods"
  as permissive
  for delete
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can insert own moods"
  on "public"."moods"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can update own moods"
  on "public"."moods"
  as permissive
  for update
  to public
using ((( SELECT auth.uid() AS uid) = user_id))
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can view own moods"
  on "public"."moods"
  as permissive
  for select
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can manage own interactions"
  on "public"."place_interactions"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "Anyone can read review cache"
  on "public"."place_reviews_cache"
  as permissive
  for select
  to public
using (true);



  create policy "Authenticated users can delete review cache"
  on "public"."place_reviews_cache"
  as permissive
  for delete
  to public
using ((( SELECT auth.uid() AS uid) IS NOT NULL));



  create policy "Authenticated users can insert review cache"
  on "public"."place_reviews_cache"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) IS NOT NULL));



  create policy "Authenticated users can update review cache"
  on "public"."place_reviews_cache"
  as permissive
  for update
  to public
using ((( SELECT auth.uid() AS uid) IS NOT NULL));



  create policy "Anyone can view places cache"
  on "public"."places_cache"
  as permissive
  for select
  to public
using (true);



  create policy "Authenticated users can insert places cache"
  on "public"."places_cache"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) IS NOT NULL));



  create policy "Service role can delete places cache"
  on "public"."places_cache"
  as permissive
  for delete
  to service_role
using (true);



  create policy "Service role can update places cache"
  on "public"."places_cache"
  as permissive
  for update
  to service_role
using (true)
with check (true);



  create policy "Anyone can view public profiles"
  on "public"."profiles"
  as permissive
  for select
  to public
using (((( SELECT auth.uid() AS uid) = id) OR (is_public = true)));



  create policy "Users can insert own profile"
  on "public"."profiles"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) = id));



  create policy "Users can update own profile"
  on "public"."profiles"
  as permissive
  for update
  to public
using ((( SELECT auth.uid() AS uid) = id));



  create policy "Users can delete own activities"
  on "public"."scheduled_activities"
  as permissive
  for delete
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can insert own activities"
  on "public"."scheduled_activities"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can update own activities"
  on "public"."scheduled_activities"
  as permissive
  for update
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can view own activities"
  on "public"."scheduled_activities"
  as permissive
  for select
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users manage own collections"
  on "public"."trip_collections"
  as permissive
  for all
  to public
using ((( SELECT auth.uid() AS uid) = user_id))
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can delete own check-ins"
  on "public"."user_check_ins"
  as permissive
  for delete
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can insert own check-ins"
  on "public"."user_check_ins"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can update own check-ins"
  on "public"."user_check_ins"
  as permissive
  for update
  to public
using ((( SELECT auth.uid() AS uid) = user_id))
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can view own check-ins"
  on "public"."user_check_ins"
  as permissive
  for select
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can insert their own patterns"
  on "public"."user_preference_patterns"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can select their own patterns"
  on "public"."user_preference_patterns"
  as permissive
  for select
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can update their own patterns"
  on "public"."user_preference_patterns"
  as permissive
  for update
  to public
using ((( SELECT auth.uid() AS uid) = user_id))
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can delete own preferences"
  on "public"."user_preferences"
  as permissive
  for delete
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can insert own preferences"
  on "public"."user_preferences"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can update own preferences"
  on "public"."user_preferences"
  as permissive
  for update
  to public
using ((( SELECT auth.uid() AS uid) = user_id))
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can view own preferences"
  on "public"."user_preferences"
  as permissive
  for select
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can delete own saved places"
  on "public"."user_saved_places"
  as permissive
  for delete
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can insert own saved places"
  on "public"."user_saved_places"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can update own saved places"
  on "public"."user_saved_places"
  as permissive
  for update
  to public
using ((( SELECT auth.uid() AS uid) = user_id))
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can view own saved places"
  on "public"."user_saved_places"
  as permissive
  for select
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can insert own milestones"
  on "public"."user_stamp_milestones"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can read own milestones"
  on "public"."user_stamp_milestones"
  as permissive
  for select
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can update own milestones"
  on "public"."user_stamp_milestones"
  as permissive
  for update
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can insert own stamps"
  on "public"."user_stamps"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can read own stamps"
  on "public"."user_stamps"
  as permissive
  for select
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can delete own visited places"
  on "public"."visited_places"
  as permissive
  for delete
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can insert own visited places"
  on "public"."visited_places"
  as permissive
  for insert
  to public
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can update own visited places"
  on "public"."visited_places"
  as permissive
  for update
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Users can view own visited places"
  on "public"."visited_places"
  as permissive
  for select
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Service role can insert weather cache"
  on "public"."weather_cache"
  as permissive
  for insert
  to service_role
with check (true);



  create policy "Service role can update weather cache"
  on "public"."weather_cache"
  as permissive
  for update
  to service_role
using (true)
with check (true);



  create policy "Anyone can view activities"
  on "public"."activities"
  as permissive
  for select
  to public
using (true);



  create policy "Users can manage own subscriptions"
  on "public"."subscriptions"
  as permissive
  for all
  to public
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "Anyone can view weather cache"
  on "public"."weather_cache"
  as permissive
  for select
  to public
using (true);


CREATE TRIGGER business_listings_updated_at BEFORE UPDATE ON public.business_listings FOR EACH ROW EXECUTE FUNCTION public.update_business_listings_updated_at();

CREATE TRIGGER enforce_reviews_cache_expiry_trigger BEFORE INSERT OR UPDATE ON public.place_reviews_cache FOR EACH ROW EXECUTE FUNCTION public.enforce_reviews_cache_expiry();

CREATE TRIGGER enforce_cache_expiry_trigger BEFORE INSERT OR UPDATE ON public.places_cache FOR EACH ROW EXECUTE FUNCTION public.enforce_cache_expiry();

CREATE TRIGGER set_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_scheduled_activities_updated_at BEFORE UPDATE ON public.scheduled_activities FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER enforce_weather_cache_expiry_trigger BEFORE INSERT OR UPDATE ON public.weather_cache FOR EACH ROW EXECUTE FUNCTION public.enforce_weather_cache_expiry();

drop policy "Diary photos are publicly accessible" on "storage"."objects";

drop policy "Travel photos are publicly accessible" on "storage"."objects";

drop policy "Users can delete their own travel photos" on "storage"."objects";

drop policy "Users can update their own travel photos" on "storage"."objects";

drop policy "Users can upload diary photos" on "storage"."objects";

drop policy "Users can upload their own avatar" on "storage"."objects";

drop policy "Users can upload their own travel photos" on "storage"."objects";

drop policy "Users can update their own avatar" on "storage"."objects";


  create policy "Authenticated users can upload avatars"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'avatars'::text) AND (auth.role() = 'authenticated'::text)));



  create policy "Users can delete their own avatar"
  on "storage"."objects"
  as permissive
  for delete
  to public
using (((bucket_id = 'avatars'::text) AND (auth.role() = 'authenticated'::text) AND (name ~~ ((auth.uid())::text || '/%'::text))));



  create policy "Users can update their own avatar"
  on "storage"."objects"
  as permissive
  for update
  to public
using (((bucket_id = 'avatars'::text) AND (auth.role() = 'authenticated'::text) AND (name ~~ ((auth.uid())::text || '/%'::text))));



