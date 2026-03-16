# Fix Vercel "committer not associated with GitHub" block

Your commits are currently authored as `Your Name <your.email@example.com>`.  
GitHub doesn’t recognize that, so Vercel blocks the deployment.

**Do this once in the repo root (WanderMood-WanderMood-Dec):**

1. **Set your real Git identity** (use the **same email** as in GitHub → Settings → Emails):

   ```bash
   cd /Users/edviennemerencia/WanderMood-WanderMood-Dec
   git config user.name "Your GitHub Username or Full Name"
   git config user.email "your-real-email@example.com"
   ```

2. **Create and push a new commit** (this one will have the correct author):

   ```bash
   git commit --allow-empty -m "Deploy: use GitHub-linked Git author"
   git push origin WanderMood_dec18_23pm
   ```

3. In Vercel → Deployments, the new deployment should no longer be blocked.

You can delete this file after it’s fixed: `rm wandermood-landing/DEPLOY_FIX_README.md`
