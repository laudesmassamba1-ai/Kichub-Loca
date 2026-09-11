-- Backfill profiles for auth.users created before the schema existed.
insert into public.profiles (id, nom, email, role)
select
  u.id,
  coalesce(u.raw_user_meta_data ->> 'nom', split_part(u.email, '@', 1)),
  u.email,
  'agent'
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id);