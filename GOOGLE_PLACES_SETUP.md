# 🗺️ Google Places API Setup Guide

Your WanderMood app now uses **real Google Places data** instead of hardcoded activities! Here's how to set it up:

## 🔑 Getting Your Google Places API Key

### 1. **Create a Google Cloud Project**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Name it "WanderMood" or similar

### 2. **Enable Google Places API**
1. In your project, go to **APIs & Services > Library**
2. Search for "Places API"
3. Enable **Places API (New)**
4. Also enable **Maps JavaScript API** and **Geocoding API**

### 3. **Create API Key**
1. Go to **APIs & Services > Credentials**
2. Click **+ CREATE CREDENTIALS > API Key**
3. Copy your new API key
4. Click **Restrict Key** for security:
   - **Application restrictions**: Choose appropriate option
   - **API restrictions**: Select only the APIs you enabled

## 🔧 Configure Your App

### Option 1: Environment Variable (Recommended)
Create a `.env` file in your project root:
```bash
GOOGLE_MAPS_API_KEY=your_api_key_here
```

### Option 2: Build-time Variable
Run your app with:
```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_api_key_here
```

## 🎯 What You Get

### **Instead of Hardcoded:**
- ❌ "Morning Yoga in the Park" (static)
- ❌ "Café Fleur" (fake)
- ❌ Stock photos

### **You Now Get Real:**
- ✅ **"Morning Coffee at Café Central"** (real place in Rotterdam)
- ✅ **"Lunch at Restaurant FG"** (actual restaurant with real rating)
- ✅ **Real photos** from Google Places Photo API
- ✅ **Actual ratings** and reviews
- ✅ **Real addresses** and contact info
- ✅ **Opening hours** and pricing

## 🧠 How It Works

### **Mood-Based Search**
Your selected moods are automatically converted to Google Places searches:

- **Relaxed** → Spas, yoga studios, parks, meditation centers
- **Energetic** → Gyms, fitness centers, sports clubs, hiking trails  
- **Romantic** → Romantic restaurants, rooftop bars, scenic viewpoints
- **Foody** → Restaurants, food markets, cafes, bakeries
- **Creative** → Art galleries, museums, pottery studios, craft workshops
- **Adventure** → Adventure parks, climbing gyms, escape rooms
- **Festive** → Amusement parks, zoos, family entertainment

### **Smart Activity Generation**
- **Morning Activities**: Cafes, parks, gyms, yoga studios
- **Afternoon Activities**: Restaurants, museums, shopping, attractions  
- **Evening Activities**: Restaurants, bars, entertainment venues

### **Real Location Integration**
- Uses your actual current location (Rotterdam)
- Searches within 15km radius
- Filters results by time appropriateness
- Generates contextual descriptions

## 🚀 Testing

1. Set up your API key using one of the methods above
2. Select moods like "Romantic" + "Foody"
3. Watch as the app fetches real restaurants for romantic dining
4. See real photos and ratings from Google Places

## 💡 Fallback System

If the API fails or no key is provided:
- App gracefully falls back to local activities
- Still shows beautiful UI
- Activities are themed to your selected moods

## 🔒 Security Notes

- Never commit your API key to version control
- Use the `.env` file method for development
- Restrict your API key to specific APIs only
- Set usage quotas to prevent unexpected charges

## 💰 Cost Management

Google Places API pricing:
- **Place Search**: $0.032 per request
- **Place Details**: $0.017 per request  
- **Place Photos**: $0.007 per request

For typical usage, costs are very low, but set quotas for safety.

---

Your app now provides **real, location-based experiences** that match your users' moods! 🎉 