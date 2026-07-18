-- ============================================================================
-- Build Your Body — wearable OAuth token store.
-- Run in the Supabase SQL editor after supabase-schema.sql.
-- Safe to re-run (idempotent). Pairs with backend/wearables.js.
-- ============================================================================

create table if not exists public.wearable_tokens (
  user_id       uuid        not null references auth.users (id) on delete cascade,
  provider      text        not null,  -- 'oura' | 'whoop' | 'fitbit'
  access_token  text        not null,
  refresh_token text,
  expires_at    timestamptz,           -- null = non-expiring (Oura long-lived tokens)
  scope         text,
  updated_at    timestamptz not null default now(),
  primary key (user_id, provider)
);

-- Keep updated_at current on every write.
create or replace function public.set_wearable_tokens_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists wearable_tokens_set_updated_at on public.wearable_tokens;
create trigger wearable_tokens_set_updated_at
  before update on public.wearable_tokens
  for each row execute function public.set_wearable_tokens_updated_at();

-- RLS: each user can only see and write their own tokens.
alter table public.wearable_tokens enable row level security;

drop policy if exists "wearable_tokens private to owner" on public.wearable_tokens;
create policy "wearable_tokens private to owner"
  on public.wearable_tokens
  for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);
