# Premium Upgrade & Location Picker Implementation

## ✅ What's Been Implemented

### 1. Location Picker Screen
**File**: `lib/features/profile/presentation/screens/location_picker_screen.dart`

**Features**:
- ✅ Real-time location search using Google Places API
- ✅ Autocomplete suggestions as you type
- ✅ Uses user's current location for better suggestions
- ✅ Saves selected location to `user_preferences` table
- ✅ Updates `default_location`, `default_latitude`, and `default_longitude`
- ✅ Beautiful UI with selection indicators

**Route**: `/settings/location/picker`

**Usage**:
```dart
final result = await context.push<String>('/settings/location/picker', extra: {
  'currentLocation': currentLocation,
});
```

### 2. Premium Upgrade Screen
**File**: `lib/features/profile/presentation/screens/premium_upgrade_screen.dart`

**Features**:
- ✅ Premium benefits display
- ✅ Payment method selection (Card, PayPal, Apple Pay)
- ✅ Card form with validation
- ✅ Updates subscription in Supabase database
- ✅ Sets subscription to 'premium' with 30-day expiry

**Route**: `/settings/premium-upgrade`

**Current Implementation**:
- Currently simulates payment processing
- Updates subscription in database after 2-second delay
- Ready for Stripe integration (see below)

## 🔧 Next Steps: Stripe Integration

### Option 1: Stripe Payment Intents (Recommended)

1. **Install Stripe Flutter Package**:
```yaml
dependencies:
  flutter_stripe: ^10.1.1
```

2. **Add Stripe Keys to `.env`**:
```env
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
```

3. **Create Supabase Edge Function for Payment**:
Create `supabase/functions/create-payment-intent/index.ts`:
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Stripe from "https://esm.sh/stripe@14.10.0?target=deno"

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
  apiVersion: "2023-10-16",
})

serve(async (req) => {
  try {
    const { amount, currency = "eur" } = await req.json()
    
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount * 100, // Convert to cents
      currency,
      metadata: {
        userId: req.headers.get("x-user-id") ?? "",
      },
    })

    return new Response(
      JSON.stringify({ clientSecret: paymentIntent.client_secret }),
      { headers: { "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    )
  }
})
```

4. **Update Premium Upgrade Screen**:
```dart
import 'package:flutter_stripe/flutter_stripe.dart';

// Initialize Stripe
await Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;

// In _processPayment method:
// 1. Create payment intent via Supabase Edge Function
final response = await supabase.functions.invoke('create-payment-intent', 
  body: {'amount': 4.99, 'currency': 'eur'}
);

// 2. Confirm payment with Stripe
await Stripe.instance.confirmPayment(
  paymentIntentClientSecret: response.data['clientSecret'],
  data: PaymentMethodParams.card(
    paymentMethodData: PaymentMethodData(
      billingDetails: BillingDetails(
        name: _nameController.text,
      ),
    ),
  ),
);

// 3. On success, update subscription
```

### Option 2: Stripe Subscriptions (Better for Recurring)

1. **Create Subscription Product in Stripe Dashboard**
2. **Create Supabase Edge Function for Subscription**:
```typescript
const subscription = await stripe.subscriptions.create({
  customer: customerId,
  items: [{ price: 'price_xxx' }], // Your premium price ID
  payment_behavior: 'default_incomplete',
  payment_settings: { save_default_payment_method: 'on_subscription' },
  expand: ['latest_invoice.payment_intent'],
})
```

3. **Handle Webhooks** for subscription status updates

## 📋 Database Schema

The subscription table already exists:
```sql
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  plan_type TEXT DEFAULT 'free', -- 'free' or 'premium'
  status TEXT DEFAULT 'active', -- 'active', 'cancelled', 'expired'
  started_at TIMESTAMP,
  expires_at TIMESTAMP,
  stripe_subscription_id TEXT, -- Add this for Stripe integration
  created_at TIMESTAMP DEFAULT NOW()
);
```

## 🎯 Testing

### Location Picker:
1. Go to Settings → Location
2. Click "Change" on Default Location
3. Type a city name
4. Select from suggestions
5. Verify it saves to database

### Premium Upgrade:
1. Go to Settings → Subscription
2. Click "Upgrade to Premium"
3. Fill in payment details
4. Complete payment
5. Verify subscription updates in database

## 🔐 Security Notes

- Never store payment details in Supabase
- Use Stripe's secure payment methods
- Validate payment on server-side (Edge Functions)
- Use webhooks to sync subscription status
- Implement proper error handling

## 📝 Additional Features to Consider

1. **Subscription Management**:
   - Cancel subscription
   - View billing history
   - Update payment method

2. **Trial Period**:
   - 7-day free trial
   - Track trial status

3. **Usage Limits**:
   - Track premium feature usage
   - Show upgrade prompts when limits reached

