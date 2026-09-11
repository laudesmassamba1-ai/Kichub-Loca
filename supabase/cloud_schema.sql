-- Final shared schema for Kichub Loca
-- Execute this script in the Supabase SQL editor of the shared cloud project.

create extension if not exists postgis;
create extension if not exists pgcrypto;

-- ============================================================
-- PROFILES
-- ============================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nom text not null default '',
  email text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- COMMERCES
-- ============================================================
create table if not exists public.commerces (
  id uuid primary key default gen_random_uuid(),
  nom text not null,
  description text,
  adresse text,
  latitude double precision,
  longitude double precision,
  position geography(point, 4326),
  photo_url text,
  cree_par uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- ============================================================
-- VISITES
-- ============================================================
create table if not exists public.visites (
  id uuid primary key default gen_random_uuid(),
  commerce_id uuid not null references public.commerces(id) on delete cascade,
  agent_id uuid not null references public.profiles(id) on delete cascade,
  statut text not null default 'nouveau',
  notes text,
  date_visite timestamptz not null default now(),
  date_rappel timestamptz,
  created_at timestamptz not null default now()
);

-- ============================================================
-- INDEX
-- ============================================================
create index if not exists commerces_position_idx
  on public.commerces using gist (position);

create index if not exists visites_agent_idx
  on public.visites (agent_id, date_visite desc);

create index if not exists visites_commerce_idx
  on public.visites (commerce_id, date_visite desc);

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Auto-create profile on user signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  insert into public.profiles (id, nom, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nom', split_part(new.email, '@', 1)),
    new.email
  )
  on conflict (id) do update
  set email = excluded.email,
      nom = coalesce(public.profiles.nom, excluded.nom);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Auto-set geography point from lat/lng
create or replace function public.set_commerce_position()
returns trigger
language plpgsql
as $$
begin
  if new.latitude is not null and new.longitude is not null then
    new.position = st_setsrid(st_makepoint(new.longitude, new.latitude), 4326)::geography;
  end if;
  return new;
end;
$$;

drop trigger if exists set_commerce_coordinates on public.commerces;
create trigger set_commerce_coordinates
before insert or update on public.commerces
for each row execute procedure public.set_commerce_position();

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- Vérifie si un email existe déjà (évite les doublons de compte)
create or replace function public.email_exists(p_email text)
returns boolean
language sql
security definer
set search_path = auth, public
as $$
  select exists(
    select 1 from auth.users u
    where lower(u.email) = lower(p_email)
  );
$$;

-- Classement des agents avec scores et patrouilles hebdomadaires
create or replace function public.get_agents_summary()
returns table (
  id uuid,
  nom text,
  email text,
  total_commerces bigint,
  total_visites bigint,
  acceptes bigint,
  refuses bigint,
  a_recontacter bigint,
  visites_semaine bigint,
  score bigint
)
language sql
stable
as $$
  select
    p.id,
    p.nom,
    p.email,
    coalesce((select count(*) from public.commerces c where c.cree_par = p.id), 0),
    coalesce((select count(*) from public.visites v where v.agent_id = p.id), 0),
    coalesce((select count(*) from public.visites v where v.agent_id = p.id and v.statut = 'accepte'), 0),
    coalesce((select count(*) from public.visites v where v.agent_id = p.id and v.statut = 'refuse'), 0),
    coalesce((select count(*) from public.visites v where v.agent_id = p.id and v.statut = 'a_recontacter'), 0),
    coalesce((select count(*) from public.visites v where v.agent_id = p.id and v.date_visite >= date_trunc('week', now())), 0),
    coalesce(
      (select count(*) from public.visites v where v.agent_id = p.id and v.statut = 'accepte') * 10
      + (select count(*) from public.visites v where v.agent_id = p.id and v.statut = 'a_recontacter') * 5
      + (select count(*) from public.visites v where v.agent_id = p.id) * 2
      - (select count(*) from public.visites v where v.agent_id = p.id and v.statut = 'refuse') * 2,
      0
    )
  from public.profiles p
  order by 10 desc;
$$;

-- Statistiques globales du dashboard
create or replace function public.get_dashboard_stats()
returns table (
  total_commerces bigint,
  total_visites bigint,
  total_agents bigint,
  nouveau bigint,
  accepte bigint,
  refuse bigint,
  a_recontacter bigint,
  visites_7j bigint
)
language sql
stable
as $$
  select
    (select count(*) from public.commerces),
    (select count(*) from public.visites),
    (select count(*) from public.profiles),
    (select count(*) from public.visites where statut = 'nouveau'),
    (select count(*) from public.visites where statut = 'accepte'),
    (select count(*) from public.visites where statut = 'refuse'),
    (select count(*) from public.visites where statut = 'a_recontacter'),
    (select count(*) from public.visites where date_visite >= now() - interval '7 days');
$$;

-- Série hebdomadaire de patrouilles (histogramme)
create or replace function public.get_weekly_series(p_weeks integer default 6)
returns table (semaine text, total bigint)
language sql
stable
as $$
  with weeks as (
    select date_trunc('week', now() - (gs || ' weeks')::interval) as w
    from generate_series(p_weeks - 1, 0, -1) gs
  )
  select
    to_char(w, 'DD/MM') as semaine,
    count(v.id) as total
  from weeks
  left join public.visites v
    on v.date_visite >= w and v.date_visite < w + interval '7 days'
  group by w
  order by w;
$$;

-- Nearby businesses within radius
create or replace function public.commerces_proches(
  lat double precision,
  lng double precision,
  rayon_m integer default 100
)
returns table (
  id uuid,
  nom text,
  description text,
  latitude double precision,
  longitude double precision,
  distance_m double precision
)
language sql
stable
as $$
  select
    c.id,
    c.nom,
    c.description,
    c.latitude,
    c.longitude,
    st_distance(c.position, st_setsrid(st_makepoint(lng, lat), 4326)::geography) as distance_m
  from public.commerces c
  where c.position is not null
    and st_dwithin(c.position, st_setsrid(st_makepoint(lng, lat), 4326)::geography, rayon_m)
  order by distance_m asc;
$$;

-- Profile summary with stats
create or replace function public.get_profile_summary()
returns table (
  id uuid,
  nom text,
  email text,
  role text,
  total_commerces bigint,
  total_visites bigint
)
language sql
stable
as $$
  select
    p.id,
    p.nom,
    p.email,
    p.role,
    count(distinct c.id) as total_commerces,
    count(distinct v.id) as total_visites
  from public.profiles p
  left join public.commerces c on c.cree_par = p.id
  left join public.visites v on v.agent_id = p.id
  group by p.id, p.nom, p.email, p.role;
$$;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table public.profiles enable row level security;
alter table public.commerces enable row level security;
alter table public.visites enable row level security;

-- Profiles: read by all authenticated users, write only own
create policy "profiles_select_authenticated" on public.profiles
for select using (auth.role() = 'authenticated');

create policy "profiles_insert_own" on public.profiles
for insert with check (auth.uid() = id);

create policy "profiles_update_own" on public.profiles
for update using (auth.uid() = id);

-- Commerces: read by all, write only by creator
create policy "commerces_read_all" on public.commerces
for select using (auth.role() = 'authenticated');

create policy "commerces_insert_own" on public.commerces
for insert with check (cree_par = auth.uid());

-- Tout membre authentifié peut mettre à jour un commerce :
-- un agent B qualifie un commerce créé par l'agent A.
create policy "commerces_update_all" on public.commerces
for update using (auth.role() = 'authenticated');

create policy "commerces_delete_own" on public.commerces
for delete using (cree_par = auth.uid());

-- Visites: read by all authenticated, write only own
create policy "visites_select_authenticated" on public.visites
for select using (auth.role() = 'authenticated');

create policy "visites_insert_own" on public.visites
for insert with check (agent_id = auth.uid());

create policy "visites_update_own" on public.visites
for update using (agent_id = auth.uid());

create policy "visites_delete_own" on public.visites
for delete using (agent_id = auth.uid());

-- ============================================================
-- PASSAGES (lieux de passage marqués par les agents)
-- ============================================================
create table if not exists public.passages (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid not null references public.profiles(id) on delete cascade,
  nom text not null default 'Passage',
  note text,
  latitude double precision,
  longitude double precision,
  position geography(point, 4326),
  created_at timestamptz not null default now()
);

create index if not exists passages_agent_idx
  on public.passages (agent_id, created_at desc);

create index if not exists passages_position_idx
  on public.passages using gist (position);

create or replace function public.set_passage_position()
returns trigger
language plpgsql
as $$
begin
  if new.latitude is not null and new.longitude is not null then
    new.position = st_setsrid(st_makepoint(new.longitude, new.latitude), 4326)::geography;
  end if;
  return new;
end;
$$;

drop trigger if exists set_passage_coordinates on public.passages;
create trigger set_passage_coordinates
before insert or update on public.passages
for each row execute procedure public.set_passage_position();

alter table public.passages enable row level security;

drop policy if exists passages_select_authenticated on public.passages;
create policy "passages_select_authenticated" on public.passages
for select using (auth.role() = 'authenticated');

drop policy if exists passages_insert_own on public.passages;
create policy "passages_insert_own" on public.passages
for insert with check (agent_id = auth.uid());

drop policy if exists passages_delete_own on public.passages;
create policy "passages_delete_own" on public.passages
for delete using (agent_id = auth.uid());
