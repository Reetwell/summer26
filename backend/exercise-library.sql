-- ============================================================================
-- Build Your Body — exercise library (recommended exercises + swaps for the
-- training onboarding). Run in Supabase SQL editor. Safe to re-run (upserts).
-- Read with the public anon key; falls back to the bundled copy in index.html
-- (EXERCISE_LIBRARY) if empty/unreachable.
-- ============================================================================

create table if not exists public.exercise_library (
  id        text primary key,
  name      text   not null,
  muscle    text   not null,                 -- chest|back|shoulders|biceps|triceps|legs|core
  location  text[] not null default '{}',    -- which settings suit it: gym|home|bodyweight
  sets      text   default '3×10–12'
);

alter table public.exercise_library enable row level security;
drop policy if exists "exercise_library public read" on public.exercise_library;
create policy "exercise_library public read" on public.exercise_library for select using (true);

insert into public.exercise_library (id,name,muscle,location,sets) values
('ex_ch1','Barbell bench press','chest','{gym}','4×8–10'),
('ex_ch2','Dumbbell bench press','chest','{gym,home}','4×8–12'),
('ex_ch3','Incline dumbbell press','chest','{gym,home}','3×10–12'),
('ex_ch4','Press-ups','chest','{home,bodyweight}','3×max'),
('ex_ch5','Cable fly','chest','{gym}','3×12–15'),
('ex_ch6','Chest press machine','chest','{gym}','3×10–12'),
('ex_bk1','Lat pulldown','back','{gym}','4×10–12'),
('ex_bk2','Pull-ups','back','{gym,bodyweight}','4×max'),
('ex_bk3','Bent-over row','back','{gym,home}','4×8–10'),
('ex_bk4','Seated cable row','back','{gym}','3×10–12'),
('ex_bk5','Dumbbell row','back','{gym,home}','3×10–12'),
('ex_bk6','Inverted row','back','{home,bodyweight}','3×max'),
('ex_sh1','Overhead press','shoulders','{gym,home}','4×8–10'),
('ex_sh2','Dumbbell shoulder press','shoulders','{gym,home}','3×10–12'),
('ex_sh3','Lateral raises','shoulders','{gym,home}','3×12–15'),
('ex_sh4','Face pulls','shoulders','{gym}','3×15'),
('ex_sh5','Pike press-ups','shoulders','{home,bodyweight}','3×max'),
('ex_bi1','Barbell curl','biceps','{gym}','3×10–12'),
('ex_bi2','Dumbbell curl','biceps','{gym,home}','3×10–12'),
('ex_bi3','Hammer curl','biceps','{gym,home}','3×10–12'),
('ex_bi4','Cable curl','biceps','{gym}','3×12–15'),
('ex_bi5','Chin-ups','biceps','{gym,bodyweight}','3×max'),
('ex_tr1','Tricep pushdown','triceps','{gym}','3×12–15'),
('ex_tr2','Overhead extension','triceps','{gym,home}','3×10–12'),
('ex_tr3','Dips','triceps','{gym,bodyweight}','3×max'),
('ex_tr4','Close-grip press-ups','triceps','{home,bodyweight}','3×max'),
('ex_tr5','Skull crushers','triceps','{gym,home}','3×10–12'),
('ex_lg1','Barbell squat','legs','{gym}','4×8–10'),
('ex_lg2','Leg press','legs','{gym}','4×10–12'),
('ex_lg3','Romanian deadlift','legs','{gym,home}','3×10–12'),
('ex_lg4','Walking lunges','legs','{gym,home,bodyweight}','3×12 each'),
('ex_lg5','Leg extension','legs','{gym}','3×12–15'),
('ex_lg6','Goblet squat','legs','{home}','3×12–15'),
('ex_lg7','Bodyweight squat','legs','{bodyweight}','3×20'),
('ex_co1','Plank','core','{gym,home,bodyweight}','3×45s'),
('ex_co2','Hanging leg raise','core','{gym,bodyweight}','3×12'),
('ex_co3','Cable crunch','core','{gym}','3×15'),
('ex_co4','Bicycle crunch','core','{home,bodyweight}','3×20'),
('ex_co5','Russian twist','core','{home,bodyweight}','3×20')
on conflict (id) do update set
  name=excluded.name, muscle=excluded.muscle, location=excluded.location, sets=excluded.sets;
