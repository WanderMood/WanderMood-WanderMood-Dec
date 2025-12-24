# Email Verification Fix Guide

## ✅ Code Fixes Applied

### 1. **Removed Bypass Button** ✅
- Removed the "Continue" button that allowed skipping email verification
- Now users must verify their email before proceeding

### 2. **Added Verification Status Checking** ✅
- Email verification screen now checks if email is already verified
- Shows appropriate UI based on verification status
- Properly handles both verified and unverified states

### 3. **Improved Signup Flow** ✅
- Signup now checks if email is already verified (auto-confirm mode)
- If verified → Goes directly to onboarding
- If not verified → Shows verification screen
- No longer forces sign-out unnecessarily

### 4. **Enhanced Deep Link Handler** ✅
- Router now properly checks `emailConfirmedAt` timestamp
- Verifies email is actually confirmed before proceeding
- Better error handling and user feedback

### 5. **Deep Links Already Configured** ✅
- iOS: `Info.plist` has `io.supabase.wandermood` URL scheme
- Android: `AndroidManifest.xml` has intent filter configured
- Deep links should work when email verification is enabled

## 🔧 Supabase Configuration (REQUIRED)

### Step 1: Enable Email Confirmations

1. **Go to Supabase Dashboard**
   - Navigate to your project
   - Click **Authentication** in the left sidebar
   - Click **Settings** (or **Email Templates**)

2. **Enable Email Confirmations**
   - Find **"Enable email confirmations"** toggle
   - Turn it **ON** ✅
   - This requires users to verify their email before signing in

3. **Configure Email Templates** (Optional but Recommended)
   - Go to **Authentication → Email Templates**
   - Customize the **"Confirm signup"** template
   - Make sure the redirect URL is: `io.supabase.wandermood://auth-callback`

### Step 2: Configure Redirect URLs

1. **Go to Authentication → URL Configuration**
2. **Add Redirect URLs:**
   - `io.supabase.wandermood://auth-callback`
   - `io.supabase.wandermood://`
   - (Add any other redirect URLs you need)

3. **Site URL:**
   - Set to your app's main URL or `io.supabase.wandermood://`

### Step 3: Configure SMTP (For Production)

**Option A: Use Supabase Default Email Service**
- Works out of the box
- Limited to 3 emails per hour per user
- Good for development/testing

**Option B: Use Custom SMTP (Recommended for Production)**
1. Go to **Authentication → Email Templates → SMTP Settings**
2. Enable custom SMTP
3. Configure with your email service:
   - **SendGrid** (recommended)
   - **Mailgun**
   - **AWS SES**
   - **Gmail SMTP** (for testing)

**Example SendGrid Configuration:**
```
Host: smtp.sendgrid.net
Port: 587
User: apikey
Password: [Your SendGrid API Key]
Sender Email: noreply@wandermood.com
Sender Name: WanderMood
```

### Step 4: Test Email Verification

1. **Create a test account**
2. **Check email inbox** (and spam folder)
3. **Click verification link**
4. **App should open** and navigate to onboarding

## 📋 Current Flow (After Fixes)

### Signup Flow:
1. User fills signup form → Clicks "Sign Up"
2. Supabase creates user account
3. **If email confirmations enabled:**
   - User receives verification email
   - User is NOT signed in yet
   - App shows verification screen
4. **If email confirmations disabled (auto-confirm):**
   - User is immediately signed in
   - App goes directly to onboarding

### Email Verification Flow:
1. User sees "Check Your Email" screen
2. User clicks link in email
3. Deep link opens app → `/auth-callback`
4. Router verifies email is confirmed
5. Sets `hasCompletedAuth = true`
6. Navigates to `/preferences/communication`

### If User Doesn't Verify:
- User stays on verification screen
- Can click "Resend Email"
- Cannot proceed to app until verified

## 🐛 Troubleshooting

### Problem: "No email received"
**Solutions:**
- Check spam folder
- Verify email address is correct
- Check Supabase email logs (Dashboard → Logs → Auth)
- Ensure SMTP is configured (if using custom SMTP)
- Check if email confirmations are enabled

### Problem: "Deep link doesn't open app"
**Solutions:**
- Verify URL scheme in `Info.plist` (iOS) and `AndroidManifest.xml` (Android)
- Test deep link: `io.supabase.wandermood://auth-callback`
- Rebuild app after changing manifest files
- Check if redirect URL is added in Supabase Dashboard

### Problem: "User can still bypass verification"
**Solutions:**
- Ensure `enable_confirmations = true` in Supabase
- Verify the bypass button is removed (already done)
- Check that router redirects unverified users

### Problem: "Email sent but verification doesn't work"
**Solutions:**
- Check if redirect URL matches in Supabase settings
- Verify deep link is configured correctly
- Check router logs for errors
- Ensure `emailRedirectTo` in code matches Supabase settings

## ✅ Verification Checklist

After applying fixes, verify:

- [ ] Email confirmations enabled in Supabase Dashboard
- [ ] Redirect URLs configured in Supabase
- [ ] Deep links work (test with `io.supabase.wandermood://auth-callback`)
- [ ] Verification email is received
- [ ] Clicking email link opens app
- [ ] App navigates to onboarding after verification
- [ ] User cannot proceed without verification
- [ ] "Resend Email" button works

## 🚀 Next Steps

1. **Enable email confirmations in Supabase Dashboard** (Critical!)
2. **Test the full flow** with a new account
3. **Configure SMTP** for production (if needed)
4. **Monitor email delivery** in Supabase logs

The code is now fixed - you just need to enable email confirmations in Supabase Dashboard!

