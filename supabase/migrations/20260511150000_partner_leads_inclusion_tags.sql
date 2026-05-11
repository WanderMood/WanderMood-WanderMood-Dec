-- Optional filter / inclusivity tags from partner apply form (multi-select chips)

ALTER TABLE public.partner_leads
  ADD COLUMN IF NOT EXISTS inclusion_tags text[] NOT NULL DEFAULT '{}';

COMMENT ON COLUMN public.partner_leads.inclusion_tags IS 'User-selected inclusion/filter tags from website apply form.';
