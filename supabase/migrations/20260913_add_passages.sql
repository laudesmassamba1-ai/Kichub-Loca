-- Passages: marquer des lieux de passage des agents sur la carte.
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