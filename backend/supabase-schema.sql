-- SummerBody — Supabase schema for cross-device sync.
-- Safe to run multiple times (idempotent). Paste into the Supabase
-- dashboard → SQL Editor → Run.

-- ───────────────────────────────────────────────────────────────────
-- Tables
-- ───────────────────────────────────────────────────────────────────

-- One profile row per authenticated user (auto-created on sign-up below).
create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  email      text,
  created_at timestamptz not null default now()
);

-- Per-user key/value store that mirrors the app's localStorage keys
-- (sbp-today, sbp-weight, sbp-workouts, sbp-session-logs, sbp-shop,
-- sbp-mealplan). One row per (user, key); newer updated_at wins.
create table if not exists public.app_data (
  user_id    uuid        not null references auth.users (id) on delete cascade,
  key        text        not null,
  value      jsonb       not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, key)
);

-- ───────────────────────────────────────────────────────────────────
-- updated_at auto-refresh
-- ───────────────────────────────────────────────────────────────────
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists app_data_set_updated_at on public.app_data;
create trigger app_data_set_updated_at
  before update on public.app_data
  for each row execute function public.set_updated_at();

-- ───────────────────────────────────────────────────────────────────
-- Auto-create a profile when a new auth user signs up
-- ───────────────────────────────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ───────────────────────────────────────────────────────────────────
-- Row Level Security — every row is private to its owner
-- ───────────────────────────────────────────────────────────────────
alter table public.profiles enable row level security;
alter table public.app_data enable row level security;

drop policy if exists "profiles are private to their owner" on public.profiles;
create policy "profiles are private to their owner"
  on public.profiles
  for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "app_data is private to its owner" on public.app_data;
create policy "app_data is private to its owner"
  on public.app_data
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
