# Finding Your Google Places API Key

## Current Status

I found a **fallback key** in your code:
```
AIzaSyAzmi2Z4Y0Z4ZMLTtiZcbZseOHwAlMux60
```

This is used as a development fallback, but you should verify if this is your actual key or if you have a different one.

## How to Find Your Google Places API Key

### Option 1: Check Your .env File

Open your `.env` file and look for:
```env
GOOGLE_PLACES_API_KEY=your_key_here
```

### Option 2: Check Google Cloud Console

1. Go to: https://console.cloud.google.com/
2. Select your project (or create one if needed)
3. Go to **APIs & Services** → **Credentials**
4. Look for **API Keys** section
5. Find the key with **Places API** enabled

### Option 3: Create a New Key (If You Don't Have One)

1. Go to: https://console.cloud.google.com/
2. Create a new project or select existing
3. Enable **Places API**:
   - Go to **APIs & Services** → **Library**
   - Search for "Places API"
   - Click **Enable**
4. Create API Key:
   - Go to **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **API Key**
   - Copy the key
5. Restrict the key (recommended):
   - Click on the key to edit
   - Under **API restrictions**, select **Restrict key**
   - Choose **Places API**
   - Under **Application restrictions**, choose **iOS apps** or **None** for testing

## Important Notes

⚠️ **The fallback key** (`AIzaSyAzmi2Z4Y0Z4ZMLTtiZcbZseOHwAlMux60`) might:
- Be a shared/development key
- Have usage limits
- Not be suitable for production

✅ **For production/TestFlight**, you should:
- Use your own Google Cloud project
- Create your own API key
- Set proper restrictions
- Monitor usage in Google Cloud Console

## Where to Add Your Key

### For Development (.env file):
```env
GOOGLE_PLACES_API_KEY=your_actual_key_here
```

### For TestFlight Build:
```bash
flutter build ipa --release \
  --dart-define=GOOGLE_PLACES_API_KEY=your_actual_key_here \
  ...
```

## Quick Check

To see what key is currently being used, run:
```bash
flutter run
```

Then check the logs for:
```
📍 Using Places API key: AIzaSyA...
```

This will show you which key is active.



