# WanderMood AI Edge Function Setup Guide

This guide walks you through setting up the complete WanderMood AI integration with Supabase Edge Functions and OpenAI.

## 🚀 Quick Start

### 1. **Supabase Project Setup**

First, make sure you have the Supabase CLI installed:
```bash
npm install -g supabase
```

Initialize your project (if not already done):
```bash
supabase init
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

### 2. **Database Migration**

Apply the database schema for AI functionality:
```bash
supabase db reset
# or if you have existing data:
supabase migration new wandermood_ai_tables
# Then copy the SQL from supabase/migrations/20240101000000_wandermood_ai_tables.sql
supabase db push
```

### 3. **Environment Variables**

Set up your environment variables in the Supabase dashboard:

**Go to:** Settings → Edge Functions → Environment Variables

Add these variables:
```
OPENAI_API_KEY=sk-your-openai-api-key-here
SUPABASE_URL=your-supabase-project-url
SUPABASE_ANON_KEY=your-supabase-anon-key
```

### 4. **Deploy Edge Function**

Deploy the WanderMood AI function:
```bash
supabase functions deploy wandermood-ai
```

### 5. **Flutter Integration**

The Flutter service is already created at `lib/core/services/wandermood_ai_service.dart`. Make sure you have the required dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  # ... other dependencies
```

## 📊 **Database Schema Overview**

The setup creates these tables:

### `user_preferences`
- Stores user preferences for AI personalization
- Budget ranges, favorite moods, dietary restrictions
- RLS enabled for user privacy

### `user_activity_history` 
- Tracks completed activities for AI learning
- User ratings and feedback
- Location and mood data for pattern recognition

### `ai_conversations`
- Stores chat conversation history
- Supports multi-turn conversations
- Context preservation across sessions

### `cached_places`
- Enhanced place data with AI insights
- Mood associations for smart recommendations
- Performance optimized with indexes

### `ai_recommendations`
- Tracks recommendation performance
- User feedback and selection patterns
- A/B testing support for AI improvements

## 🤖 **Usage Examples**

### Get AI Recommendations
```dart
import 'package:wandermood/core/services/wandermood_ai_service.dart';

// Get personalized recommendations
final response = await WanderMoodAIService.getRecommendations(
  moods: ['Foody', 'Romantic'],
  latitude: 51.9244,
  longitude: 4.4777,
  city: 'Rotterdam',
  preferences: {
    'budget': 150,
    'timeSlot': 'evening',
    'groupSize': 2,
  },
);

print('Got ${response.recommendations.length} recommendations');
for (final rec in response.recommendations) {
  print('${rec.name}: ${rec.moodMatch}');
}
```

### Start AI Chat
```dart
// Start a conversation
final chatResponse = await WanderMoodAIService.chat(
  message: "I'm feeling adventurous in Rotterdam, what should I do?",
  moods: ['Adventurous'],
  latitude: 51.9244,
  longitude: 4.4777,
  city: 'Rotterdam',
);

print('AI Response: ${chatResponse.message}');
```

### Create Complete Day Plan
```dart
// Generate a full day itinerary
final planResponse = await WanderMoodAIService.createDayPlan(
  moods: ['Cultural', 'Foody'],
  latitude: 51.9244,
  longitude: 4.4777,
  city: 'Rotterdam',
  preferences: {
    'budget': 200,
    'startTime': '09:00',
    'endTime': '22:00',
  },
);

print('Day Plan: ${planResponse.message}');
```

## 🔧 **Configuration Options**

### OpenAI Model Configuration
The Edge Function uses `gpt-4o-mini` by default for cost-effectiveness. You can modify this in the `callOpenAI` function:

```typescript
model: 'gpt-4o-mini', // Options: gpt-4o-mini, gpt-4o, gpt-3.5-turbo
max_tokens: 1000,     // Adjust based on your needs
temperature: 0.7,     // Creativity level (0.0 - 1.0)
```

### Supabase RLS Policies
Row Level Security is enabled for all user tables. Users can only access their own data, while cached places are publicly readable for performance.

### Performance Optimization
- Database indexes on frequently queried columns
- Connection pooling via Supabase
- Cached place data to reduce API calls
- Optimized SQL queries for user context

## 🚨 **Troubleshooting**

### Common Issues:

**1. "AI service temporarily unavailable"**
- Check OpenAI API key is correctly set
- Verify Edge Function deployed successfully
- Check Supabase function logs: `supabase functions logs`

**2. "Unauthorized" error**
- Ensure user is authenticated before calling AI service
- Check RLS policies are correctly configured
- Verify JWT token is valid

**3. Empty recommendations**
- Check if `cached_places` table has data
- Verify Google Places API is populating place cache
- Check mood associations in cached places

**4. Slow responses**
- Monitor OpenAI API response times
- Consider upgrading to faster OpenAI models
- Optimize database queries with EXPLAIN ANALYZE

### Debug Commands:
```bash
# Check function logs
supabase functions logs wandermood-ai

# Test function locally
supabase functions serve wandermood-ai

# Check database connections
supabase db inspect
```

## 🔐 **Security Considerations**

1. **API Key Security**: OpenAI keys are stored server-side only
2. **User Privacy**: RLS ensures data isolation
3. **Rate Limiting**: Implement client-side throttling
4. **Input Validation**: Edge Function validates all inputs
5. **CORS**: Configured for your app domain only

## 💰 **Cost Optimization**

### OpenAI Usage:
- `gpt-4o-mini`: ~$0.00015 per recommendation
- Average recommendation: 500 tokens
- Daily cost for 1000 users: ~$75

### Supabase Usage:
- Edge Function: $0.375 per 1M requests
- Database: Free tier supports ~1000 daily active users
- Storage: Negligible for text data

### Caching Strategy:
- Place data cached for 24 hours
- User preferences cached in-memory
- Conversation history limited to 10 messages

## 📈 **Monitoring & Analytics**

Track AI performance with:
- Recommendation click-through rates
- User satisfaction ratings
- Response time metrics
- Cost per user interaction

Access analytics via:
```sql
-- Recommendation performance
SELECT 
  recommendation_type,
  AVG(user_feedback) as avg_rating,
  COUNT(*) as total_recommendations
FROM ai_recommendations 
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY recommendation_type;

-- User engagement
SELECT 
  DATE(created_at) as date,
  COUNT(DISTINCT user_id) as active_users,
  COUNT(*) as total_interactions
FROM ai_conversations
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at);
```

## 🎯 **Next Steps**

1. **Deploy and Test**: Start with basic recommendations
2. **Gather Feedback**: Monitor user satisfaction scores
3. **Iterate**: Improve prompts based on user behavior
4. **Scale**: Add more AI capabilities (image analysis, voice)
5. **Optimize**: Fine-tune based on usage patterns

---

## ✅ **Deployment Checklist**

- [ ] Database migration applied
- [ ] Environment variables configured
- [ ] Edge Function deployed successfully
- [ ] Flutter service integrated
- [ ] Authentication working
- [ ] Test recommendations with sample data
- [ ] RLS policies verified
- [ ] Error handling tested
- [ ] Performance monitoring setup
- [ ] Cost tracking enabled

Your WanderMood AI is now ready to provide intelligent, personalized travel recommendations! 🎉 