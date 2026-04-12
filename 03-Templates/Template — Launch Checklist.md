# Template — Launch Checklist

> The last mile before users touch your product. Run this after [[Template — Audit Checklist|the audit passes]].

---

## Infrastructure
- [ ] Production database provisioned and migrated
- [ ] Production env vars set in deployment platform (not copy-pasted from dev)
- [ ] SSL/TLS configured (HTTPS only, no mixed content)
- [ ] Custom domain pointed and propagated
- [ ] CDN configured for static assets

## Monitoring & Alerting
- [ ] Sentry configured for production environment (separate from staging)
- [ ] Uptime monitor pinging health check endpoint every 60 seconds
- [ ] Alert channel set up (Slack/SMS/email) for errors and downtime
- [ ] Structured logging flowing to Axiom/Datadog (not just console.log)
- [ ] First error trigger: manually trigger an error and confirm it appears in Sentry

## Security
- [ ] CORS configured — only your domain(s), not `*`
- [ ] Rate limiting on auth endpoints (login, signup, password reset)
- [ ] Rate limiting on public API endpoints
- [ ] CSP headers configured
- [ ] No secrets in client bundle (check with `grep` on build output)
- [ ] OAuth redirect URIs updated for production domain
- [ ] Admin/internal routes not publicly accessible

## Data
- [ ] Database backups configured (automated, daily minimum)
- [ ] Tested backup restore process at least once
- [ ] Seed data removed from production (no test@test.com accounts)
- [ ] Soft delete working (verify `deleted_at` is set, not hard deleted)

## Payments (if applicable)
- [ ] Stripe switched from test mode to live mode
- [ ] Webhook endpoint registered in Stripe dashboard (production URL)
- [ ] Webhook signature verification enabled
- [ ] Test a real payment end-to-end (use a real card, refund after)
- [ ] Failed payment → grace period → downgrade flow tested

## Email (if applicable)
- [ ] Domain verified in Resend/Postmark
- [ ] SPF, DKIM, DMARC records configured
- [ ] Test email delivery to Gmail, Outlook, Yahoo (check spam folder)
- [ ] Unsubscribe links working
- [ ] Plain-text fallback renders correctly

## Analytics
- [ ] PostHog/Plausible initialized for production
- [ ] Core loop funnel tracking events firing
- [ ] Signup → first core action → retention events defined
- [ ] Verify events appear in analytics dashboard

## Performance
- [ ] Lighthouse score ≥ 90 on core pages (Performance, Accessibility)
- [ ] Largest Contentful Paint < 2.5s
- [ ] No unoptimized images (use Next.js Image or similar)
- [ ] Database queries on hot paths have indexes

## Legal (if public product)
- [ ] Privacy policy page exists
- [ ] Terms of service page exists
- [ ] Cookie consent banner (if required in target market)
- [ ] GDPR data export/deletion capability (if EU users)

## Launch Day
- [ ] Preview deploy tested by at least one person who isn't you
- [ ] Rollback plan documented: "If X breaks, do Y"
- [ ] Support channel ready (email, Discord, whatever)
- [ ] Launch announcement drafted

---

#templates #launch #checklist
