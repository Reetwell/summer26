-- ============================================================================
-- Build Your Body — recipe library (the catalog people pick from in onboarding)
-- Run this in the Supabase SQL editor (Dashboard → SQL → New query → Run).
-- Safe to re-run: it upserts, so editing a row here and re-running updates it.
-- The app reads this table with the public anon key; if it's empty/unreachable
-- the app falls back to the bundled copy in index.html (RECIPE_LIBRARY).
-- ============================================================================

create table if not exists public.recipe_library (
  id        text primary key,
  type      text    not null,                 -- breakfast | snack | lunch | dinner
  name      text    not null,
  kcal      int     not null default 0,
  p         int     not null default 0,        -- protein (g)
  c         int     not null default 0,        -- carbs (g)
  f         int     not null default 0,        -- fat (g)
  veg       boolean not null default false,    -- vegetarian-friendly
  cuisines  text[]  not null default '{}',     -- e.g. {mexican,italian}; 'simple' = always eligible
  tags      text[]  not null default '{}',     -- avoid-filters: dairy,gluten,egg,fish,nuts,spicy,meat,beef
  body      text    default '',                -- ingredients
  note      text    default ''                 -- method / tip
);

-- Catalog is non-sensitive and shared by everyone → allow public read only.
alter table public.recipe_library enable row level security;
drop policy if exists "recipe_library public read" on public.recipe_library;
create policy "recipe_library public read" on public.recipe_library for select using (true);

insert into public.recipe_library (id,type,name,kcal,p,c,f,veg,cuisines,tags,body,note) values
('rb1','breakfast','Overnight weetabix',440,46,54,8,true,'{british,simple}','{dairy,gluten}','3 weetabix · 200ml semi-skimmed milk · 150g Greek yogurt (0%) · 1 scoop whey · 1 tbsp honey · blueberries','Mix the night before, fridge overnight, top with honey and berries.'),
('rb2','breakfast','Scrambled eggs on toast',380,28,30,16,true,'{british,simple}','{egg,gluten,dairy}','3 eggs · 2 slices wholemeal toast · splash of milk · knob of butter','Scramble low and slow for creamy eggs.'),
('rb3','breakfast','Greek yogurt protein bowl',350,30,40,6,true,'{simple}','{dairy}','250g Greek yogurt · 1 scoop whey · 40g granola · honey · berries','Stir whey into the yogurt, top with granola and fruit.'),
('rb4','breakfast','Peanut butter banana oats',420,18,60,14,true,'{american}','{nuts,gluten}','60g oats · 250ml milk · 1 banana · 1 tbsp peanut butter','Microwave the oats, stir in PB, slice banana on top.'),
('rb5','breakfast','Veggie breakfast burrito',450,26,45,18,true,'{mexican}','{egg,gluten,dairy}','2 eggs · 1 tortilla · black beans · cheese · salsa · peppers','Scramble eggs with peppers, wrap with beans, cheese and salsa.'),
('rs1','snack','Cottage cheese + apple',180,18,20,2,true,'{simple}','{dairy}','150g cottage cheese · 1 tbsp honey · 1 apple (sliced)',''),
('rs2','snack','Protein shake + banana',190,25,20,2,true,'{simple}','{dairy}','1 scoop whey in water · 1 banana',''),
('rs3','snack','Rice cakes + tuna',200,22,18,4,false,'{simple}','{fish}','2 rice cakes · 1 tin tuna · squeeze of lemon',''),
('rs4','snack','Nuts + dark chocolate',220,6,16,16,true,'{simple}','{nuts}','30g mixed nuts · 2 squares dark chocolate',''),
('rs5','snack','Hummus + veg sticks',160,6,18,8,true,'{simple}','{}','80g hummus · carrot + cucumber + pepper sticks',''),
('rl1','lunch','Chicken honey wrap',490,52,48,10,false,'{british}','{gluten,meat}','2 wholemeal wraps · 180g chicken · honey mustard · lettuce + cucumber + sweetcorn',''),
('rl2','lunch','Tuna pasta',520,40,70,10,false,'{italian}','{fish,gluten}','90g pasta · 1 tin tuna · sweetcorn · light mayo · black pepper','Cook pasta, mix through tuna, sweetcorn and a little mayo.'),
('rl3','lunch','Chicken burrito bowl',560,48,62,14,false,'{mexican}','{meat,dairy}','150g chicken · 120g rice · black beans · salsa · cheese · lettuce',''),
('rl4','lunch','Halloumi couscous salad',480,24,50,20,true,'{simple}','{dairy,gluten}','100g halloumi · 80g couscous · cherry tomatoes · cucumber · olive oil','Fry halloumi, toss through couscous and salad.'),
('rl5','lunch','Beef + rice stir fry',580,45,65,14,false,'{asian}','{meat,beef,gluten,spicy}','150g beef strips · 120g rice · mixed veg · soy sauce · chilli','Stir fry beef and veg, serve over rice.'),
('rd1','dinner','Proper chicken fajitas',790,54,78,18,false,'{mexican}','{meat,gluten,dairy,spicy}','220g chicken strips · 3 tortillas · peppers + onion · fajita seasoning · salsa · yogurt','Fry chicken with peppers and seasoning ~15 mins, serve in warm tortillas.'),
('rd2','dinner','Spaghetti bolognese',720,45,80,20,false,'{italian}','{beef,meat,gluten}','150g beef mince · 100g spaghetti · tomato sauce · onion + garlic','Brown mince, simmer in sauce, serve over spaghetti.'),
('rd3','dinner','Salmon + sweet potato',620,42,50,24,false,'{british}','{fish}','1 salmon fillet · 1 sweet potato · broccoli · olive oil','Bake salmon and sweet potato ~25 mins, steam the broccoli.'),
('rd4','dinner','Chicken curry + rice',700,48,75,18,false,'{asian}','{meat,dairy,spicy}','180g chicken · 120g rice · curry sauce · onion · yogurt','Simmer chicken in sauce, serve over rice.'),
('rd5','dinner','Veggie chilli + rice',560,22,90,10,true,'{mexican}','{spicy}','kidney beans + black beans · 120g rice · peppers · tomato · chilli + cumin','Simmer beans, tomato and spices ~20 mins, serve over rice.')
on conflict (id) do update set
  type=excluded.type, name=excluded.name, kcal=excluded.kcal, p=excluded.p, c=excluded.c, f=excluded.f,
  veg=excluded.veg, cuisines=excluded.cuisines, tags=excluded.tags, body=excluded.body, note=excluded.note;
