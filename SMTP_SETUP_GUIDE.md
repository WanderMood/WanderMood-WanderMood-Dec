# SMTP Setup Guide for TestFlight/Production

## Why Set Up Custom SMTP?

- ✅ **No rate limits** - Send unlimited emails
- ✅ **Better deliverability** - Emails less likely to go to spam
- ✅ **Professional** - Uses your own email domain
- ✅ **Reliable** - Production-grade email service
- ✅ **Essential for TestFlight** - Multiple testers need emails

## Recommended: SendGrid (Free Tier Available)

SendGrid offers:
- **Free tier**: 100 emails/day (perfect for testing)
- **Paid plans**: Start at $15/month for 40,000 emails
- Easy setup
- Great deliverability
- Works well with Supabase

## Step-by-Step: SendGrid Setup

### Step 1: Create SendGrid Account

1. Go to [sendgrid.com](https://sendgrid.com)
2. Click **"Start for free"**
3. Sign up with your email
4. Verify your email address
5. Complete account setup

### Step 2: Create API Key

1. In SendGrid Dashboard, go to **Settings** → **API Keys**
2. Click **"Create API Key"**
3. Name it: `WanderMood Supabase`
4. Select **"Full Access"** (or "Restricted Access" with Mail Send permissions)
5. Click **"Create & View"**
6. **Copy the API key immediately** (you won't see it again!)
   - It looks like: `SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### Step 3: Verify Sender Identity (Required)

1. Go to **Settings** → **Sender Authentication**
2. Choose one:
   
   **Option A: Single Sender Verification (Easiest)**
   - Click **"Verify a Single Sender"**
   - Enter your email (e.g., `noreply@wandermood.com`)
   - Fill in required details
   - Verify via email link
   
   **Option B: Domain Authentication (Better for Production)**
   - Click **"Authenticate Your Domain"**
   - Follow DNS setup instructions
   - Add DNS records to your domain

### Step 4: Configure in Supabase

1. Go to **Supabase Dashboard** → **Authentication** → **Email** → **SMTP Settings**
2. Turn **"Enable custom SMTP"** toggle **ON**
3. Fill in the settings:

```
Host: smtp.sendgrid.net
Port: 587
Username: apikey
Password: [Paste your SendGrid API key here]
Sender email: [Your verified sender email, e.g., noreply@wandermood.com]
Sender name: WanderMood
```

4. Click **"Save changes"**

### Step 5: Test Email Sending

1. Go to **Authentication** → **Users**
2. Find a test user
3. Click **"Resend confirmation email"**
4. Check if email is received
5. Check SendGrid Dashboard → **Activity** to see email status

## Alternative: Mailgun (Also Good)

If you prefer Mailgun:

1. Sign up at [mailgun.com](https://www.mailgun.com)
2. Free tier: 5,000 emails/month for 3 months
3. Get API key from Dashboard
4. Configure in Supabase:

```
Host: smtp.mailgun.org
Port: 587
Username: postmaster@[your-domain].mailgun.org
Password: [Your Mailgun SMTP password]
Sender email: noreply@[your-domain]
Sender name: WanderMood
```

## Alternative: AWS SES (For Production Scale)

If you need enterprise-level email:

1. Set up AWS SES
2. Verify domain/email
3. Get SMTP credentials
4. Configure in Supabase

## Quick Setup Checklist

- [ ] Create SendGrid account
- [ ] Create API key
- [ ] Verify sender identity (email or domain)
- [ ] Enable custom SMTP in Supabase
- [ ] Enter SMTP credentials
- [ ] Save changes
- [ ] Test email sending
- [ ] Verify email received

## Important Notes

### For TestFlight Testing:
- **Free tier (100 emails/day) is enough** for initial testing
- Monitor usage in SendGrid Dashboard
- Upgrade if you exceed limits

### For Production:
- Consider paid plan (40,000 emails/month = $15)
- Or use domain authentication for better deliverability
- Monitor email delivery rates

### Security:
- **Never share your API key**
- Store it securely
- Rotate keys periodically
- Use environment variables in production

## Troubleshooting

### "Authentication failed"
- Check API key is correct
- Ensure sender email is verified in SendGrid
- Verify username is exactly `apikey` (lowercase)

### "Emails not sending"
- Check SendGrid Activity logs
- Verify sender identity is approved
- Check rate limits in SendGrid (if on free tier)

### "Emails going to spam"
- Verify sender identity properly
- Use domain authentication (better than single sender)
- Warm up your sending domain gradually

## Cost Estimate

**SendGrid Free Tier:**
- 100 emails/day
- Perfect for TestFlight testing
- Free forever

**SendGrid Essentials ($15/month):**
- 40,000 emails/month
- Good for production
- ~1,300 emails/day

## Next Steps

1. **Set up SendGrid now** (takes 10-15 minutes)
2. **Configure in Supabase**
3. **Test with one email**
4. **Ready for TestFlight!**

The setup is quick and will save you headaches during TestFlight testing!

