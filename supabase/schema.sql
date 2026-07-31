-- Rebuild the Supabase schema for the current app.
-- Run this in the Supabase SQL editor when you need a clean reset.

begin;

create extension if not exists pgcrypto;

-- Remove dependent objects first so the tables can be rebuilt cleanly.
drop table if exists public.events cascade;
drop table if exists public.children cascade;
drop table if exists public.events cascade;

create table public.children (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, name)
);

create table public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  child_id uuid not null references public.children (id) on delete cascade,
  type text not null check (type in ('milestone', 'learning_note')),
  title text not null,
  category text not null default '里程碑',
  content text,
  tags text[] not null default '{}'::text[],
  event_date date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger children_set_updated_at
before update on public.children
for each row
execute function public.set_updated_at();

create trigger events_set_updated_at
before update on public.events
for each row
execute function public.set_updated_at();

alter table public.children enable row level security;
alter table public.events enable row level security;

create policy "children_select_own"
on public.children
for select
to authenticated
using (auth.uid() = user_id);

create policy "children_insert_own"
on public.children
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "children_update_own"
on public.children
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "children_delete_own"
on public.children
for delete
to authenticated
using (auth.uid() = user_id);

create policy "events_select_own"
on public.events
for select
to authenticated
using (auth.uid() = user_id);

create policy "events_insert_own"
on public.events
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "events_update_own"
on public.events
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "events_delete_own"
on public.events
for delete
to authenticated
using (auth.uid() = user_id);

grant select, insert, update, delete on table public.events to authenticated;
grant select, insert, update, delete on table public.children to authenticated;
grant all privileges on table public.events to service_role;
grant all privileges on table public.children to service_role;

commit;
