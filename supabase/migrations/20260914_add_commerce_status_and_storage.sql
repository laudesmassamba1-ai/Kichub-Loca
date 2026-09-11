-- Images, statut direct sur les prospects, notes et cohérence des stats.

-- ============================================================
-- 1) Bucket storage public pour les photos
-- ============================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('commerce-photos', 'commerce-photos', true, 52428800, null)
on conflict (id) do update set public = true;

drop policy if exists commerce_photos_read on storage.objects;
create policy "commerce_photos_read" on storage.objects
for select using (bucket_id = 'commerce-photos');

drop policy if exists commerce_photos_insert on storage.objects;
create policy "commerce_photos_insert" on storage.objects
for insert to authenticated
with check (bucket_id = 'commerce-photos');

drop policy if exists commerce_photos_update on storage.objects;
create policy "commerce_photos_update" on storage.objects
for update to authenticated
using (bucket_id = 'commerce-photos');

-- ============================================================
-- 2) Statut et notes directement sur les prospects (commerces)
-- ============================================================
alter table public.commerces add column if not exists statut text not null default 'nouveau';
alter table public.commerces add column if not exists notes text;

create index if not exists commerces_statut_idx
  on public.commerces (statut);

-- Cohérence : le statut d'un commerce reprend le dernier statut de visite existant.
update public.commerces c
set statut = v.statut
from (
  select distinct on (commerce_id) commerce_id, statut
  from public.visites
  order by commerce_id, date_visite desc
) v
where v.commerce_id = c.id;

-- ============================================================
-- 3) Stats recalculées sur commerces.statut (correlation ecosysteme)
-- ============================================================
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
    (select count(*) from public.profiles where role <> 'admin'),
    (select count(*) from public.commerces where statut = 'nouveau'),
    (select count(*) from public.commerces where statut = 'accepte'),
    (select count(*) from public.commerces where statut = 'refuse'),
    (select count(*) from public.commerces where statut = 'a_recontacter'),
    (select count(*) from public.visites where date_visite >= now() - interval '7 days');
$$;

create or replace function public.get_agents_summary()
returns table (
  id uuid,
  nom text,
  email text,
  role text,
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
    p.role,
    coalesce((select count(*) from public.commerces c where c.cree_par = p.id), 0),
    coalesce((select count(*) from public.visites v where v.agent_id = p.id), 0),
    coalesce((select count(*) from public.commerces c where c.cree_par = p.id and c.statut = 'accepte'), 0),
    coalesce((select count(*) from public.commerces c where c.cree_par = p.id and c.statut = 'refuse'), 0),
    coalesce((select count(*) from public.commerces c where c.cree_par = p.id and c.statut = 'a_recontacter'), 0),
    coalesce((select count(*) from public.visites v where v.agent_id = p.id and v.date_visite >= date_trunc('week', now())), 0),
    coalesce(
      (select count(*) from public.commerces c where c.cree_par = p.id and c.statut = 'accepte') * 10
      + (select count(*) from public.commerces c where c.cree_par = p.id and c.statut = 'a_recontacter') * 5
      + (select count(*) from public.visites v where v.agent_id = p.id) * 2
      - (select count(*) from public.commerces c where c.cree_par = p.id and c.statut = 'refuse') * 2,
      0
    )
  from public.profiles p
  where p.role <> 'admin'
  order by 11 desc;
$$;