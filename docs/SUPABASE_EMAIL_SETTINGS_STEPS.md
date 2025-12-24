# How to Enable Email Confirmations in Supabase

## Step-by-Step Guide

### Step 1: Click on "Email" (Already Selected)
You're currently on the Authentication page. The "Email" option is highlighted in the NOTIFICATIONS section. **Click on it** to open the email settings.

### Step 2: Find "Enable email confirmations" Toggle
Once you click "Email", you should see a settings page with:

**Look for these settings:**
- ✅ **"Enable email confirmations"** - This is the main toggle you need
- "Enable signup" - Should already be ON
- "Double confirm email changes" - Optional
- "Secure password change" - Optional
- Email templates section
- SMTP settings (if you want custom email service)

### Step 3: Enable the Toggle
1. Find the **"Enable email confirmations"** toggle/switch
2. Turn it **ON** ✅
3. Click **"Save"** or the toggle should auto-save

### Step 4: Configure Redirect URL (Important!)
While you're in Email settings, also check:

1. Scroll down to find **"Redirect URLs"** or go to **CONFIGURATION → URL Configuration**
2. Make sure this URL is added:
   ```
   io.supabase.wandermood://auth-callback
   ```
3. If it's not there, click "Add URL" and add it

### Step 5: Verify Email Template
1. In the Email settings, look for **"Email Templates"** section
2. Click on **"Confirm signup"** template
3. Make sure the redirect URL in the template is:
   ```
   io.supabase.wandermood://auth-callback
   ```

## What You Should See

After clicking "Email", you should see a page with:

**Settings Section:**
- Enable signup: ✅ ON
- **Enable email confirmations: ⚠️ OFF** ← Turn this ON
- Double confirm email changes: (optional)
- Secure password change: (optional)

**Email Templates Section:**
- Confirm signup
- Magic Link
- Change Email Address
- Reset Password
- etc.

**SMTP Settings** (if you want custom email service)

## If You Don't See "Enable email confirmations"

**Option 1: Check URL Configuration**
- Go to **CONFIGURATION → URL Configuration**
- The setting might be there

**Option 2: Check Sign In / Providers**
- Go to **CONFIGURATION → Sign In / Providers**
- Look for email provider settings

**Option 3: Check Project Settings**
- Sometimes it's in **Settings → Authentication** (different from the left sidebar)

## Quick Checklist

- [ ] Clicked on "Email" in NOTIFICATIONS section
- [ ] Found "Enable email confirmations" toggle
- [ ] Turned it ON
- [ ] Saved changes
- [ ] Added redirect URL: `io.supabase.wandermood://auth-callback`
- [ ] Verified email template has correct redirect URL

## After Enabling

Once you enable email confirmations:
1. New signups will receive verification emails
2. Users must click the link to verify
3. Users cannot sign in until email is verified
4. The app will properly handle the verification flow

Try clicking on "Email" now and let me know what you see!

