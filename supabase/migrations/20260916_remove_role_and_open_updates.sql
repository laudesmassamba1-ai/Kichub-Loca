-- ============================================================
-- 20260916 : Outil interne collaboratif — tout le monde peut agir
-- ============================================================
-- 1) RLS : n'importe quel membre authentifié peut mettre à jour un commerce
--    (un agent B doit pouvoir qualifier un commerce créé par l'agent A).
-- 2) Suppression de la distinction agent/admin (colonne profiles.role).

-- ------------------------------------------------------------
-- 1) RLS COMMERCES : UPDATE ouvert à tous les authentifiés
-- ------------------------------------------------------------
drop policy if exists "commerces_update_own" on public.commerces;
create policy "commerces_update_all" on public.commerces
  for update using (auth.role() = 'authenticated');

-- ------------------------------------------------------------
-- 2) SUPPRESSION DU RÔLE (agent/admin)
-- ------------------------------------------------------------
alter table public.profiles drop column if exists role;

drop trigger if exists on_auth_user_created on auth.users;
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
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Classement des agents : tous les membres, plus de filtre par rôle
drop function if exists public.get_agents_summary();
create function public.get_agents_summary()
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

-- Statistiques globales : tous les membres comptent
drop function if exists public.get_dashboard_stats();
create function public.get_dashboard_stats()
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