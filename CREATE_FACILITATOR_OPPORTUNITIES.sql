-- Facilitator Opportunities schema and policies
-- Run this in Supabase SQL editor

-- 1) Base table for facilitator-posted opportunities
create table if not exists public.incubation_opportunities (
  id uuid primary key default gen_random_uuid(),
  facilitator_id uuid not null references auth.users(id) on delete cascade,
  program_name text not null,
  description text not null,
  deadline date not null,
  poster_url text,
  video_url text,
  created_at timestamptz not null default now()
);

-- 2) Applications from startups for opportunities
create table if not exists public.opportunity_applications (
  id uuid primary key default gen_random_uuid(),
  opportunity_id uuid not null references public.incubation_opportunities(id) on delete cascade,
  startup_id bigint not null references public.startups(id) on delete cascade,
  status text not null default 'pending',
  agreement_url text,
  diligence_status text,
  created_at timestamptz not null default now()
);

-- 3) Enable RLS
alter table public.incubation_opportunities enable row level security;
alter table public.opportunity_applications enable row level security;

-- 4) Basic helper to read role from users table (if not present already)
-- create or replace view public.user_profiles as
--   select id, role from public.users;

-- 5) Policies: facilitators can CRUD their own opportunities; everyone can read
drop policy if exists opps_select_all on public.incubation_opportunities;
drop policy if exists opps_insert_own on public.incubation_opportunities;
drop policy if exists opps_update_own on public.incubation_opportunities;
drop policy if exists opps_delete_own on public.incubation_opportunities;

create policy opps_select_all on public.incubation_opportunities
  for select
  to authenticated
  using (true);

create policy opps_insert_own on public.incubation_opportunities
  for insert
  to authenticated
  with check (auth.uid() = facilitator_id);

create policy opps_update_own on public.incubation_opportunities
  for update
  to authenticated
  using (auth.uid() = facilitator_id);

create policy opps_delete_own on public.incubation_opportunities
  for delete
  to authenticated
  using (auth.uid() = facilitator_id);

-- 6) Policies for applications: startup owners can insert/select their own; facilitators can read apps to their opps
drop policy if exists apps_select_startup_or_facilitator on public.opportunity_applications;
drop policy if exists apps_insert_startup on public.opportunity_applications;
drop policy if exists apps_update_facilitator on public.opportunity_applications;

create policy apps_select_startup_or_facilitator on public.opportunity_applications
  for select
  to authenticated
  using (
    auth.uid() = (select user_id from public.startups s where s.id = startup_id)
    or exists (
      select 1 from public.incubation_opportunities o
      where o.id = opportunity_id and o.facilitator_id = auth.uid()
    )
  );

create policy apps_insert_startup on public.opportunity_applications
  for insert
  to authenticated
  with check (
    auth.uid() = (select user_id from public.startups s where s.id = startup_id)
  );

-- Allow facilitator to update status/agreement for apps to their opps
create policy apps_update_facilitator on public.opportunity_applications
  for update
  to authenticated
  using (
    exists (
      select 1 from public.incubation_opportunities o
      where o.id = opportunity_id and o.facilitator_id = auth.uid()
    )
  );


