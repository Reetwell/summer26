// ==================== NAV ====================
function showSection(id, el) {
  if(id === 'shopping'){ showSection('meals'); mealTab('shop'); return; }   // folded into Meals
  document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  document.getElementById('sec-' + id).classList.add('active');
  document.querySelectorAll('.nav-link').forEach(n => n.classList.remove('active'));
  document.querySelectorAll('.bnav-item').forEach(n => n.classList.remove('active'));
  document.querySelectorAll('[data-bnav]').forEach(n => { if(n.onclick.toString().includes("'" + id + "'")) n.classList.add('active'); });
  document.querySelectorAll('.desk-side button').forEach(n => n.classList.remove('active'));
  document.querySelectorAll('.desk-side [data-dside="' + id + '"]').forEach(n => n.classList.add('active'));
  if(el) el.classList.add('active');
  document.documentElement.classList.toggle('view-today', id === 'today');
  if(id === 'shopping') { updateShopProgress('sp1'); updateShopProgress('sp2'); }
  if(id === 'progress') { renderWorkoutGrid(); renderWeightChart(); renderSessionHistory(); updateLogSessionButton(); }
  if(id === 'today') { renderToday(); }
  if(id === 'meals') { mealTab('plan'); }
  if(id === 'recipes') { renderRecipes(); }
}

// Account page (reached via the floating top-right button, not the main nav).
function openAccount() {
  document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  document.getElementById('sec-account').classList.add('active');
  document.querySelectorAll('.nav-link, .bnav-item').forEach(n => n.classList.remove('active'));
  window.scrollTo(0, 0);
  initAccountSettings();
}
function goHome() {
  const navBtn = document.querySelector('.bottom-nav [data-bnav]') || document.querySelector('.nav-link');
  showSection('today', navBtn);
}

// Date
const d = new Date();
document.getElementById('nav-date').textContent = d.toLocaleDateString('en-GB', {weekday:'short',day:'numeric',month:'short'});

// ==================== MEALS ====================
function switchMealPhase(id, el) {
  document.querySelectorAll('.meal-phase').forEach(p => p.style.display = 'none');
  document.getElementById(id).style.display = 'block';
  el.parentElement.querySelectorAll('.ptoggle').forEach(t => t.classList.remove('on'));
  el.classList.add('on');
}
function switchMealDay(phase, day, el) {
  document.querySelectorAll('#' + phase + ' .dc').forEach(d => d.classList.remove('show'));
  document.getElementById(phase + '-' + day).classList.add('show');
  document.querySelectorAll('#' + phase + ' .dtab').forEach(t => t.classList.remove('on'));
  el.classList.add('on');
}

// ==================== EDITABLE MEAL PLAN ====================
// The static meal cards are the seed. On first run we parse them into a data
// model (sbp-mealplan, auto-synced per user), then render every day from data
// with edit/add/delete controls. Each user edits their own copy.
let MP_DATA = null;
let _mpEdit = null;   // { pid, dayKey, id }  — id null = adding a new meal
const MP_TYPES = { breakfast:{cls:'tag-b',label:'Breakfast'}, snack:{cls:'tag-s',label:'Snack'}, lunch:{cls:'tag-l',label:'Lunch'}, dinner:{cls:'tag-d',label:'Dinner'} };
function mpUid(){ return 'm' + Date.now().toString(36) + Math.random().toString(36).slice(2,6); }
function mpTypeFromTag(cls){ if(/tag-b/.test(cls)) return 'breakfast'; if(/tag-l/.test(cls)) return 'lunch'; if(/tag-d/.test(cls)) return 'dinner'; return 'snack'; }
function mpDigits(el){ if(!el) return 0; const n = parseInt((el.textContent||'').replace(/[^0-9]/g,''),10); return isNaN(n) ? 0 : n; }

function seedMealPlanFromDOM(){
  const data = { v:1, phases:{} };
  document.querySelectorAll('#sec-meals .meal-phase').forEach(ph => {
    const pid = ph.id;
    const btn = document.querySelector('.ptoggle[onclick*="' + pid + '"]');
    const days = {};
    ph.querySelectorAll('.dc').forEach(dc => {
      const dayKey = dc.id.replace(pid + '-', '');
      const meals = [];
      dc.querySelectorAll('.card').forEach(card => {
        const tagEl = card.querySelector('.tag');
        const titleEl = card.querySelector('.card-title');
        let name = '';
        if(titleEl){
          name = Array.from(titleEl.childNodes).filter(n => n.nodeType === 3).map(n => n.textContent).join(' ').replace(/\s+/g,' ').trim();
          if(!name) name = titleEl.textContent.replace(tagEl ? tagEl.textContent : '', '').trim();
        }
        const noteEl = card.querySelector('.card-note');
        const bodyEl = card.querySelector('.card-body');
        meals.push({
          id: mpUid(),
          type: tagEl ? mpTypeFromTag(tagEl.className) : 'snack',
          name,
          kcal: mpDigits(card.querySelector('.card-kcal')),
          body: bodyEl ? bodyEl.textContent.trim() : '',
          note: noteEl ? noteEl.textContent.trim() : '',
          p: mpDigits(card.querySelector('.pill-p')), c: mpDigits(card.querySelector('.pill-c')), f: mpDigits(card.querySelector('.pill-f'))
        });
      });
      const tipEl = dc.querySelector('.tip');
      days[dayKey] = { meals, tip: tipEl ? tipEl.textContent.trim() : '' };
    });
    data.phases[pid] = { label: btn ? btn.textContent.trim() : pid, days };
  });
  return data;
}
function mpSave(){ localStorage.setItem('sbp-mealplan', JSON.stringify(MP_DATA)); }
// Upgrade an existing saved meal plan to the current shape (mirrors tpInit/migrateSplit).
// v2 adds: stable meal ids (needed to key the meal log) + guaranteed arrays. Non-destructive.
function migrateMealPlan(mp){
  if(!mp || !mp.phases) return mp;
  Object.values(mp.phases).forEach(ph => {
    ph.days = ph.days || {};
    Object.values(ph.days).forEach(day => {
      if(!Array.isArray(day.meals)) day.meals = [];
      day.meals.forEach(m => { if(!m.id) m.id = mpUid(); });
    });
  });
  mp.v = 2;
  return mp;
}
function mpInit(){
  MP_DATA = loadStore('sbp-mealplan', null);
  if(MP_DATA && MP_DATA.phases){
    if(MP_DATA.v !== 2){ MP_DATA = migrateMealPlan(MP_DATA); mpSave(); }
    renderMealPlan(); return;
  }
  // No plan yet. Seed a sensible default so the page isn't empty, then — if this
  // is a genuine first run (not just a returning user who skipped) — offer the
  // friendly onboarding that builds a personalised plan from the recipe library.
  MP_DATA = seedMealPlanFromDOM();
  mpSave();
  renderMealPlan();
  if(localStorage.getItem('sbp-mealplan-onboarded') !== '1'){ setTimeout(openMealOnboarding, 600); }
}
function mpTbox(label, val){ return '<div class="tbox"><div class="tbox-label">' + label + '</div><div class="tbox-val">' + esc(String(val)) + '</div></div>'; }
function mpLogBar(pid, dayKey, m){
  const log = mealLogFor(dayKey, m.id);
  const a = (fn, icon, label) => '<button class="mp-log-btn" onclick="event.stopPropagation();' + fn + '"><i class="fa-solid ' + icon + '" aria-hidden="true"></i> ' + label + '</button>';
  let status = '';
  if(log){
    const lbl = log.status === 'eaten' ? '<span class="mp-log-status ate">✓ Ate it</span>'
      : log.status === 'skipped' ? '<span class="mp-log-status skip">⊘ Skipped</span>'
      : '<span class="mp-log-status swap">↺ Had ' + esc(log.name || 'something else') + '</span>';
    status = lbl + a("mealClearLog('" + pid + "','" + dayKey + "','" + m.id + "')", 'fa-rotate-left', 'Undo');
  } else {
    status = a("mealMarkEaten('" + pid + "','" + dayKey + "','" + m.id + "')", 'fa-check', 'Ate it')
      + a("mealOpenSwap('" + pid + "','" + dayKey + "','" + m.id + "')", 'fa-arrows-rotate', 'Had something else')
      + a("mealMarkSkipped('" + pid + "','" + dayKey + "','" + m.id + "')", 'fa-ban', 'Skip');
  }
  return '<div class="mp-logbar">' + status + '</div>';
}
function mpCardHtml(pid, dayKey, m){
  const t = MP_TYPES[m.type] || MP_TYPES.snack;
  const opts = Object.keys(MP_TYPES).map(k => '<option value="' + k + '"' + (k === m.type ? ' selected' : '') + '>' + MP_TYPES[k].label + '</option>').join('');
  const eff = mealEffective(dayKey, m);
  const statusCls = eff.status ? ' mp-logged mp-' + eff.status : '';
  return '<div class="mp-card' + statusCls + '" data-pid="' + pid + '" data-day="' + dayKey + '" data-id="' + m.id + '">'
    + '<div class="mp-view" onclick="mpOpenEdit(this)">'
      + '<div class="mp-vhead"><span class="tag ' + t.cls + '">' + t.label + '</span><span class="mp-vname">' + esc(m.name || 'Untitled') + '</span>'
        + '<span class="mp-reorder"><button class="mp-icon" title="Move up" aria-label="Move up" onclick="event.stopPropagation();mpMoveMeal(\'' + pid + '\',\'' + dayKey + '\',\'' + m.id + '\',-1)">↑</button>'
        + '<button class="mp-icon" title="Move down" aria-label="Move down" onclick="event.stopPropagation();mpMoveMeal(\'' + pid + '\',\'' + dayKey + '\',\'' + m.id + '\',1)">↓</button></span>'
        + '<span class="mp-vkcal">~' + (+m.kcal||0) + ' kcal</span></div>'
      + (m.body ? '<div class="mp-vbody">' + esc(m.body) + '</div>' : '')
      + (m.note ? '<div class="card-note">' + esc(m.note) + '</div>' : '')
      + '<div class="mpills"><span class="pill pill-p">P: ' + (+m.p||0) + 'g</span><span class="pill pill-c">C: ' + (+m.c||0) + 'g</span><span class="pill pill-f">F: ' + (+m.f||0) + 'g</span></div>'
      + mpLogBar(pid, dayKey, m)
      + '<div class="mp-edithint"><i class="fa-solid fa-pen" aria-hidden="true"></i> tap to edit</div>'
    + '</div>'
    + '<div class="mp-edit">'
      + '<select class="food-input mp-e-type">' + opts + '</select>'
      + '<input class="food-input mp-e-name" value="' + esc(m.name || '') + '" placeholder="Name" autocomplete="off">'
      + '<textarea class="food-input mp-e-body" placeholder="Ingredients">' + esc(m.body || '') + '</textarea>'
      + '<textarea class="food-input mp-e-note" placeholder="Method / note (optional)">' + esc(m.note || '') + '</textarea>'
      + '<div class="mp-emac"><input class="food-input mp-e-kcal" type="number" min="0" value="' + (+m.kcal||0) + '" aria-label="kcal"><input class="food-input mp-e-p" type="number" min="0" value="' + (+m.p||0) + '" aria-label="protein"><input class="food-input mp-e-c" type="number" min="0" value="' + (+m.c||0) + '" aria-label="carbs"><input class="food-input mp-e-f" type="number" min="0" value="' + (+m.f||0) + '" aria-label="fat"></div>'
      + '<div class="mp-eact"><button class="sigate-cta sv" onclick="mpInlineSave(this)">Save</button><button class="mp-icon" title="Delete" aria-label="Delete meal" onclick="mpInlineDelete(this)">✕</button></div>'
    + '</div>'
    + '</div>';
}
// Keep the (static) phase tabs + subtitle in sync with the actual plan data, so
// build-your-own (one "My plan" phase) doesn't show an empty Phase 2, and custom
// labels show through.
function mpSyncPhaseTabs(){
  const wrap = document.querySelector('#meal-plan-view .phase-toggle');
  if(!wrap || !MP_DATA || !MP_DATA.phases) return;
  const ids = Object.keys(MP_DATA.phases);
  let firstVisible = null;
  wrap.querySelectorAll('.ptoggle').forEach(btn => {
    const mm = /switchMealPhase\('([^']+)'/.exec(btn.getAttribute('onclick') || '');
    const pid = mm && mm[1];
    if(!pid) return;
    const ph = MP_DATA.phases[pid];
    if(ph){ btn.style.display = ''; btn.textContent = ph.label || pid; if(!firstVisible) firstVisible = { pid, btn }; }
    else { btn.style.display = 'none'; btn.classList.remove('on'); const p = document.getElementById(pid); if(p) p.style.display = 'none'; }
  });
  // Ensure a visible phase is active if the previously-active one is now hidden.
  if(firstVisible && !wrap.querySelector('.ptoggle.on:not([style*="none"])')){ switchMealPhase(firstVisible.pid, firstVisible.btn); }
  // Subtitle: a single "My plan" phase = build-your-own.
  const sub = document.querySelector('#sec-meals .page-header p');
  if(sub && ids.length === 1 && (MP_DATA.phases[ids[0]].label || '').toLowerCase() === 'my plan'){
    sub.textContent = 'Your own plan · edit any day, log what you actually eat';
  }
}
function renderMealPlan(){
  if(!MP_DATA) return;
  mpSyncPhaseTabs();
  Object.keys(MP_DATA.phases).forEach(pid => {
    const phase = MP_DATA.phases[pid];
    Object.keys(phase.days).forEach(dayKey => {
      const dc = document.getElementById(pid + '-' + dayKey);
      if(!dc) return;
      const day = phase.days[dayKey];
      const tot = day.meals.reduce((a,m) => { const e = mealEffective(dayKey, m); return { kcal:a.kcal+e.kcal, p:a.p+e.p, c:a.c+e.c, f:a.f+e.f, logged:a.logged||!!e.status }; }, {kcal:0,p:0,c:0,f:0,logged:false});
      let h = '<div class="mp-bento">'
        + '<div class="mp-hero"><span class="n">' + tot.kcal.toLocaleString() + '</span><span class="u">kcal' + (tot.logged ? ' · actual' : '') + '</span><span class="ctx">' + esc(phase.label || '') + '</span></div>'
        + '<div class="mp-stat"><div class="l">Protein</div><div class="v">' + tot.p + 'g</div></div>'
        + '<div class="mp-stat"><div class="l">Carbs</div><div class="v">' + tot.c + 'g</div></div>'
        + '<div class="mp-stat"><div class="l">Fats</div><div class="v">' + tot.f + 'g</div></div>'
        + '</div>';
      h += '<div class="mp-meals">' + day.meals.map(m => mpCardHtml(pid, dayKey, m)).join('') + '</div>';
      h += '<button class="mp-add" onclick="mpAddMeal(\'' + pid + '\',\'' + dayKey + '\')">+ Add meal</button>';
      if(day.tip) h += '<div class="tip">' + esc(day.tip) + '</div>';
      dc.innerHTML = h;
    });
  });
}
function mpFindDay(pid, dayKey){ return MP_DATA && MP_DATA.phases[pid] && MP_DATA.phases[pid].days[dayKey]; }
function mpEditMeal(pid, dayKey, id){
  const day = mpFindDay(pid, dayKey); if(!day) return;
  const m = day.meals.find(x => x.id === id); if(!m) return;
  _mpEdit = { pid, dayKey, id };
  document.getElementById('mp-edit-title').textContent = 'Edit meal';
  document.getElementById('mp-f-type').value = m.type || 'snack';
  document.getElementById('mp-f-name').value = m.name || '';
  document.getElementById('mp-f-body').value = m.body || '';
  document.getElementById('mp-f-note').value = m.note || '';
  document.getElementById('mp-f-kcal').value = m.kcal || 0;
  document.getElementById('mp-f-p').value = m.p || 0;
  document.getElementById('mp-f-c').value = m.c || 0;
  document.getElementById('mp-f-f').value = m.f || 0;
  document.getElementById('meal-edit-modal').style.display = 'block';
}
function mpAddMeal(pid, dayKey){
  const day = mpFindDay(pid, dayKey); if(!day) return;
  const id = mpUid();
  day.meals.push({ id, type:'snack', name:'', body:'', note:'', kcal:0, p:0, c:0, f:0 });
  mpSave(); renderMealPlan();
  const card = document.querySelector('#' + pid + '-' + dayKey + ' .mp-card[data-id="' + id + '"]');
  if(card){ card.classList.add('editing'); card.scrollIntoView({ block:'center', behavior:'smooth' }); const nm = card.querySelector('.mp-e-name'); if(nm) nm.focus(); }
}
// Inline tap-to-edit (replaces the old modal)
function mpOpenEdit(viewEl){
  const card = viewEl.closest('.mp-card'); if(!card) return;
  document.querySelectorAll('#sec-meals .mp-card.editing').forEach(c => { if(c !== card) c.classList.remove('editing'); });
  card.classList.add('editing');
  const nm = card.querySelector('.mp-e-name'); if(nm) nm.focus();
}
function mpInlineSave(btn){
  const card = btn.closest('.mp-card'); if(!card) return;
  const day = mpFindDay(card.dataset.pid, card.dataset.day); if(!day) return;
  const meal = day.meals.find(x => x.id === card.dataset.id); if(!meal) return;
  const q = s => card.querySelector(s);
  const num = el => { const n = parseInt(el.value, 10); return (isNaN(n) || n < 0) ? 0 : n; };
  const name = (q('.mp-e-name').value || '').trim();
  if(!name){ showToast('Give the meal a name.', 'error'); return; }
  meal.type = q('.mp-e-type').value;
  meal.name = name;
  meal.body = (q('.mp-e-body').value || '').trim();
  meal.note = (q('.mp-e-note').value || '').trim();
  meal.kcal = num(q('.mp-e-kcal')); meal.p = num(q('.mp-e-p')); meal.c = num(q('.mp-e-c')); meal.f = num(q('.mp-e-f'));
  mpSave(); renderMealPlan();
  showToast('Saved', 'success');
}
function mpInlineDelete(btn){
  const card = btn.closest('.mp-card'); if(!card) return;
  const day = mpFindDay(card.dataset.pid, card.dataset.day); if(!day) return;
  if(!confirm('Delete this meal?')) return;
  day.meals = day.meals.filter(x => x.id !== card.dataset.id);
  mpSave(); renderMealPlan();
  showToast('Meal removed', 'info');
}
function mpCloseEdit(){ document.getElementById('meal-edit-modal').style.display = 'none'; _mpEdit = null; }
function mpSaveEdit(){
  if(!_mpEdit) return;
  const day = mpFindDay(_mpEdit.pid, _mpEdit.dayKey); if(!day) return;
  const v = id => document.getElementById('mp-f-' + id).value;
  const num = id => { const n = parseInt(v(id),10); return (isNaN(n) || n < 0) ? 0 : n; };
  const name = (v('name') || '').trim();
  if(!name){ showToast('Give the meal a name.', 'error'); return; }
  const fields = { type:v('type'), name, body:(v('body')||'').trim(), note:(v('note')||'').trim(), kcal:num('kcal'), p:num('p'), c:num('c'), f:num('f') };
  if(_mpEdit.id){ Object.assign(day.meals.find(x => x.id === _mpEdit.id), fields); }
  else { day.meals.push(Object.assign({ id: mpUid() }, fields)); }
  mpSave(); renderMealPlan(); mpCloseEdit();
  showToast('Meal saved', 'success');
}
function mpDeleteMeal(pid, dayKey, id){
  const day = mpFindDay(pid, dayKey); if(!day) return;
  if(!confirm('Delete this meal?')) return;
  day.meals = day.meals.filter(x => x.id !== id);
  mpSave(); renderMealPlan();
  showToast('Meal removed', 'info');
}

// ==================== MEALS ⇄ SHOPPING (tabs + auto-built list) ====================
function mealTab(t){
  const plan = t === 'plan';
  document.getElementById('meal-tab-plan').classList.toggle('on', plan);
  document.getElementById('meal-tab-shop').classList.toggle('on', !plan);
  document.getElementById('meal-plan-view').style.display = plan ? '' : 'none';
  document.getElementById('meal-shop-view').style.display = plan ? 'none' : 'block';
  if(!plan) renderMealShopping();
}
const SHOP_CATS = [
  { key:'protein', label:'Meat & fish', kw:['chicken','beef','mince','steak','turkey','salmon','tuna','fish','pork','bacon','prawn','ham','egg'] },
  { key:'dairy',   label:'Dairy & fridge', kw:['milk','yogurt','yoghurt','cheese','cottage','butter','cream'] },
  { key:'carbs',   label:'Carbs & grains', kw:['rice','pasta','spaghetti','oats','bread','wrap','tortilla','potato','weetabix','granola','couscous','noodle','rice cake'] },
  { key:'produce', label:'Veg & fruit', kw:['pepper','onion','lettuce','cucumber','tomato','broccoli','apple','banana','berr','spinach','sweetcorn','salad','carrot','avocado','lemon','lime','pea','garlic','veg','fruit'] },
  { key:'other',   label:'Store cupboard', kw:[] }
];
function shopCatFor(name){ const n = name.toLowerCase(); for(const c of SHOP_CATS){ if(c.kw.some(k => n.includes(k))) return c.key; } return 'other'; }
function shopName(piece){
  let s = (piece || '').trim();
  s = s.replace(/\(.*?\)/g,'');
  s = s.replace(/^[\d]+([.,/][\d]+)?\s*/,'');
  s = s.replace(/^(g|kg|ml|l|tbsp|tsp|scoops?|large|small|handful|pinch|cloves?|cups?|slices?|tins?|cans?|½|¼|x|of)\b\.?\s*/i,'');
  s = s.replace(/\b(on top|stirred in|sliced|shredded|grated|optional|to serve|to taste|chopped|diced|cooked|raw|fresh|warm|drizzle|squeeze|of)\b/gi,'');
  s = s.replace(/\s+/g,' ').replace(/^[-,\s]+|[-,\s]+$/g,'').trim();
  return s;
}
let _mealShopChecked = loadStore('sbp-mealshop', {});
function renderMealShopping(){
  const el = document.getElementById('meal-shop-view'); if(!el) return;
  if(typeof MP_DATA === 'undefined' || !MP_DATA || !MP_DATA.phases){ el.innerHTML = '<div class="tip">Build a meal plan first — then your shopping list appears here.</div>'; return; }
  const seen = {};
  Object.values(MP_DATA.phases).forEach(ph => Object.values(ph.days).forEach(day => (day.meals || []).forEach(m => {
    (m.body || '').replace(/\(.*?\)/g,'').split(/[·+]/).forEach(piece => { const nm = shopName(piece); if(nm && nm.length > 1){ const key = nm.toLowerCase(); if(!seen[key]) seen[key] = nm; } });
  })));
  const groups = {};
  Object.values(seen).forEach(nm => { const c = shopCatFor(nm); (groups[c] = groups[c] || []).push(nm); });
  let h = '<div class="meal-shop-head"><span id="shop-count"></span><div class="shop-acts">'
    + '<button class="shop-act" onclick="shopCopy()"><i class="fa-solid fa-copy" aria-hidden="true"></i> Copy</button>'
    + '<button class="shop-act" onclick="shopToReminders()"><i class="fa-solid fa-list-check" aria-hidden="true"></i> Reminders</button>'
    + '<button class="mp-reset-link" onclick="shopReset()">↻ Uncheck all</button></div></div>';
  SHOP_CATS.forEach(c => {
    const items = (groups[c.key] || []).sort(); if(!items.length) return;
    h += '<div class="shop-cat"><div class="shop-cat-h">' + esc(c.label) + '</div><div class="shop-items">';
    items.forEach(nm => { const k = nm.toLowerCase(); const on = _mealShopChecked[k]; h += '<label class="shop-it' + (on ? ' on' : '') + '"><input type="checkbox" data-k="' + esc(k) + '"' + (on ? ' checked' : '') + ' onchange="shopToggle(this)"><span>' + esc(nm) + '</span></label>'; });
    h += '</div></div>';
  });
  el.innerHTML = h;
  shopUpdateCount();
}
function shopToggle(cb){ const k = cb.dataset.k; if(cb.checked) _mealShopChecked[k] = true; else delete _mealShopChecked[k]; localStorage.setItem('sbp-mealshop', JSON.stringify(_mealShopChecked)); cb.closest('.shop-it').classList.toggle('on', cb.checked); shopUpdateCount(); }
function shopReset(){ _mealShopChecked = {}; localStorage.setItem('sbp-mealshop', '{}'); renderMealShopping(); }
function shopItemsToBuy(){ return [...document.querySelectorAll('#meal-shop-view .shop-it:not(.on) span')].map(s => s.textContent.trim()).filter(Boolean); }
async function shopCopy(){
  const items = shopItemsToBuy();
  if(!items.length){ showToast('Nothing left to buy 🎉', 'info'); return; }
  try { await navigator.clipboard.writeText(items.join('\n')); showToast('Copied ' + items.length + ' items — paste into Reminders', 'success'); }
  catch(_){ showToast('Couldn\'t copy', 'error'); }
}
function shopToReminders(){
  const items = shopItemsToBuy();
  if(!items.length){ showToast('Nothing left to buy 🎉', 'info'); return; }
  window.location.href = 'shortcuts://run-shortcut?name=' + encodeURIComponent('BuildBody Shopping') + '&input=text&text=' + encodeURIComponent(items.join('\n'));
}
function shopUpdateCount(){ const all = document.querySelectorAll('#meal-shop-view .shop-it').length; const on = document.querySelectorAll('#meal-shop-view .shop-it.on').length; const el = document.getElementById('shop-count'); if(el) el.textContent = on + ' / ' + all + ' in the basket'; }

// ==================== RECIPE LIBRARY + MEAL ONBOARDING ====================
// The pickable catalog lives in Supabase (table `recipe_library`, public read).
// This bundled set is a fallback so onboarding works offline / while the project
// is paused — it's also the exact data seeded by backend/recipe-library.sql.
const RECIPE_LIBRARY = [
  // breakfasts
  { id:'rb1', type:'breakfast', name:'Overnight weetabix', kcal:440, p:46, c:54, f:8, veg:true, cuisines:['british','simple'], tags:['dairy','gluten'], body:'3 weetabix · 200ml semi-skimmed milk · 150g Greek yogurt (0%) · 1 scoop whey · 1 tbsp honey · blueberries', note:'Mix the night before, fridge overnight, top with honey and berries.' },
  { id:'rb2', type:'breakfast', name:'Scrambled eggs on toast', kcal:380, p:28, c:30, f:16, veg:true, cuisines:['british','simple'], tags:['egg','gluten','dairy'], body:'3 eggs · 2 slices wholemeal toast · splash of milk · knob of butter', note:'Scramble low and slow for creamy eggs.' },
  { id:'rb3', type:'breakfast', name:'Greek yogurt protein bowl', kcal:350, p:30, c:40, f:6, veg:true, cuisines:['simple'], tags:['dairy'], body:'250g Greek yogurt · 1 scoop whey · 40g granola · honey · berries', note:'Stir whey into the yogurt, top with granola + fruit.' },
  { id:'rb4', type:'breakfast', name:'Peanut butter banana oats', kcal:420, p:18, c:60, f:14, veg:true, cuisines:['american'], tags:['nuts','gluten'], body:'60g oats · 250ml milk · 1 banana · 1 tbsp peanut butter', note:'Microwave the oats, stir in PB, slice banana on top.' },
  { id:'rb5', type:'breakfast', name:'Veggie breakfast burrito', kcal:450, p:26, c:45, f:18, veg:true, cuisines:['mexican'], tags:['egg','gluten','dairy'], body:'2 eggs · 1 tortilla · black beans · cheese · salsa · peppers', note:'Scramble eggs with peppers, wrap with beans, cheese and salsa.' },
  // snacks
  { id:'rs1', type:'snack', name:'Cottage cheese + apple', kcal:180, p:18, c:20, f:2, veg:true, cuisines:['simple'], tags:['dairy'], body:'150g cottage cheese · 1 tbsp honey · 1 apple (sliced)', note:'' },
  { id:'rs2', type:'snack', name:'Protein shake + banana', kcal:190, p:25, c:20, f:2, veg:true, cuisines:['simple'], tags:['dairy'], body:'1 scoop whey in water · 1 banana', note:'' },
  { id:'rs3', type:'snack', name:'Rice cakes + tuna', kcal:200, p:22, c:18, f:4, veg:false, cuisines:['simple'], tags:['fish'], body:'2 rice cakes · 1 tin tuna · squeeze of lemon', note:'' },
  { id:'rs4', type:'snack', name:'Nuts + dark chocolate', kcal:220, p:6, c:16, f:16, veg:true, cuisines:['simple'], tags:['nuts'], body:'30g mixed nuts · 2 squares dark chocolate', note:'' },
  { id:'rs5', type:'snack', name:'Hummus + veg sticks', kcal:160, p:6, c:18, f:8, veg:true, cuisines:['simple'], tags:[], body:'80g hummus · carrot + cucumber + pepper sticks', note:'' },
  // lunches
  { id:'rl1', type:'lunch', name:'Chicken honey wrap', kcal:490, p:52, c:48, f:10, veg:false, cuisines:['british'], tags:['gluten','meat'], body:'2 wholemeal wraps · 180g chicken · honey mustard · lettuce + cucumber + sweetcorn', note:'' },
  { id:'rl2', type:'lunch', name:'Tuna pasta', kcal:520, p:40, c:70, f:10, veg:false, cuisines:['italian'], tags:['fish','gluten'], body:'90g pasta · 1 tin tuna · sweetcorn · light mayo · black pepper', note:'Cook pasta, mix through tuna, sweetcorn and a little mayo.' },
  { id:'rl3', type:'lunch', name:'Chicken burrito bowl', kcal:560, p:48, c:62, f:14, veg:false, cuisines:['mexican'], tags:['meat','dairy'], body:'150g chicken · 120g rice · black beans · salsa · cheese · lettuce', note:'' },
  { id:'rl4', type:'lunch', name:'Halloumi couscous salad', kcal:480, p:24, c:50, f:20, veg:true, cuisines:['simple'], tags:['dairy','gluten'], body:'100g halloumi · 80g couscous · cherry tomatoes · cucumber · olive oil', note:'Fry halloumi, toss through couscous and salad.' },
  { id:'rl5', type:'lunch', name:'Beef + rice stir fry', kcal:580, p:45, c:65, f:14, veg:false, cuisines:['asian'], tags:['meat','beef','gluten','spicy'], body:'150g beef strips · 120g rice · mixed veg · soy sauce · chilli', note:'Stir fry beef and veg, serve over rice.' },
  // dinners
  { id:'rd1', type:'dinner', name:'Proper chicken fajitas', kcal:790, p:54, c:78, f:18, veg:false, cuisines:['mexican'], tags:['meat','gluten','dairy','spicy'], body:'220g chicken strips · 3 tortillas · peppers + onion · fajita seasoning · salsa · yogurt', note:'Fry chicken with peppers + seasoning ~15 mins, serve in warm tortillas.' },
  { id:'rd2', type:'dinner', name:'Spaghetti bolognese', kcal:720, p:45, c:80, f:20, veg:false, cuisines:['italian'], tags:['beef','meat','gluten'], body:'150g beef mince · 100g spaghetti · tomato sauce · onion + garlic', note:'Brown mince, simmer in sauce, serve over spaghetti.' },
  { id:'rd3', type:'dinner', name:'Salmon + sweet potato', kcal:620, p:42, c:50, f:24, veg:false, cuisines:['british'], tags:['fish'], body:'1 salmon fillet · 1 sweet potato · broccoli · olive oil', note:'Bake salmon + sweet potato ~25 mins, steam the broccoli.' },
  { id:'rd4', type:'dinner', name:'Chicken curry + rice', kcal:700, p:48, c:75, f:18, veg:false, cuisines:['asian'], tags:['meat','dairy','spicy'], body:'180g chicken · 120g rice · curry sauce · onion · yogurt', note:'Simmer chicken in sauce, serve over rice.' },
  { id:'rd5', type:'dinner', name:'Veggie chilli + rice', kcal:560, p:22, c:90, f:10, veg:true, cuisines:['mexican'], tags:['spicy'], body:'kidney beans + black beans · 120g rice · peppers · tomato · chilli + cumin', note:'Simmer beans, tomato and spices ~20 mins, serve over rice.' }
];

let RECIPE_LIB_CACHE = null;
function normalizeRecipe(r){
  const arr = v => Array.isArray(v) ? v : (v ? String(v).split(',').map(s=>s.trim()).filter(Boolean) : []);
  return { id:r.id, type:r.type, name:r.name, kcal:+r.kcal||0, p:+r.p||0, c:+r.c||0, f:+r.f||0, body:r.body||'', note:r.note||'', veg:!!r.veg, cuisines:arr(r.cuisines), tags:arr(r.tags) };
}
async function loadRecipeLibrary(){
  if(RECIPE_LIB_CACHE) return RECIPE_LIB_CACHE;
  try {
    if(typeof sb !== 'undefined' && sb){
      const { data, error } = await sb.from('recipe_library').select('*');
      if(!error && data && data.length){ RECIPE_LIB_CACHE = data.map(normalizeRecipe); return RECIPE_LIB_CACHE; }
    }
  } catch(_){}
  RECIPE_LIB_CACHE = RECIPE_LIBRARY.map(normalizeRecipe);   // bundled fallback
  return RECIPE_LIB_CACHE;
}

// ---- Onboarding: preferences → auto-built plan ----
let _onb = { goal:'fatloss', cuisines:[], avoid:[], veg:false };
function recipeAllowed(r, prefs){
  if(prefs.veg && !r.veg) return false;
  for(const a of (prefs.avoid||[])){ if(r.tags.includes(a)) return false; }
  return true;
}
function recipeCuisineOk(r, prefs){
  if(!prefs.cuisines || !prefs.cuisines.length) return true;
  if(r.cuisines.includes('simple')) return true;
  return r.cuisines.some(c => prefs.cuisines.includes(c));
}
function mpPool(lib, type, prefs){
  let p = lib.filter(r => r.type===type && recipeAllowed(r,prefs) && recipeCuisineOk(r,prefs));
  if(p.length < 2) p = lib.filter(r => r.type===type && recipeAllowed(r,prefs));
  if(p.length === 0) p = lib.filter(r => r.type===type);
  return p;
}
function mpRecipeToMeal(r){ return { id:mpUid(), type:r.type, name:r.name, kcal:r.kcal, body:r.body, note:r.note||'', p:r.p, c:r.c, f:r.f }; }
function buildPlanFromPrefs(lib, prefs){
  const days = ['mon','tue','wed','thu','fri','sat','sun'];
  const phaseDefs = [
    { id:'mp1', label:'Phase 1 — Fat loss', snacks:1 },
    { id:'mp2', label:'Phase 2 — Muscle build', snacks:2 }
  ];
  const data = { v:1, phases:{} };
  phaseDefs.forEach(pd => {
    const bp = mpPool(lib,'breakfast',prefs), sn = mpPool(lib,'snack',prefs), ln = mpPool(lib,'lunch',prefs), dn = mpPool(lib,'dinner',prefs);
    const pick = (arr, off) => arr.length ? mpRecipeToMeal(arr[((off % arr.length) + arr.length) % arr.length]) : null;
    const dayObjs = {};
    days.forEach((d, i) => {
      const meals = [];
      const add = m => { if(m) meals.push(m); };
      add(pick(bp, i));
      add(pick(sn, i));
      add(pick(ln, i));
      if(pd.snacks > 1) add(pick(sn, i + 3));
      add(pick(dn, i));
      dayObjs[d] = { meals, tip:'' };
    });
    data.phases[pd.id] = { label: pd.label, days: dayObjs };
  });
  return data;
}

// First choice: build-your-own (empty week) vs generate-then-edit. Auto-generation
// is never the only path.
function openMealOnboarding(){
  const m = _ensureMealChoiceModal();
  m.style.display = 'block';
}
function _ensureMealChoiceModal(){
  let m = document.getElementById('meal-choice-modal');
  if(m) return m;
  m = document.createElement('div');
  m.id = 'meal-choice-modal';
  m.style.cssText = 'display:none;position:fixed;inset:0;z-index:210;';
  m.innerHTML =
    '<div class="modal-overlay" onclick="mealCloseChoice()"></div>' +
    '<div class="modal-panel"><div class="modal-header"><div>' +
      '<div class="modal-title">Your meal plan</div>' +
      '<div class="modal-sub">Two ways to start — both fully editable after</div>' +
    '</div><button class="modal-close" onclick="mealCloseChoice()"><i class="fa-solid fa-xmark"></i></button></div>' +
    '<div class="modal-body">' +
      '<button class="meal-choice-opt" onclick="mealBuildOwn()">' +
        '<i class="fa-solid fa-pen-to-square" aria-hidden="true"></i>' +
        '<span class="mc-t">Build my own</span>' +
        '<span class="mc-s">Start from an empty week and fill in each day yourself.</span></button>' +
      '<button class="meal-choice-opt" onclick="mealChoiceGenerate()">' +
        '<i class="fa-solid fa-wand-magic-sparkles" aria-hidden="true"></i>' +
        '<span class="mc-t">Generate one I can edit</span>' +
        '<span class="mc-s">We build a personalised week from your prefs — tweak anything after.</span></button>' +
    '</div></div>';
  document.body.appendChild(m);
  return m;
}
function mealCloseChoice(){ const m = document.getElementById('meal-choice-modal'); if(m) m.style.display = 'none'; }
function mealBuildOwn(){
  MP_DATA = mpEmptyWeek();
  mpSave();
  localStorage.setItem('sbp-mealplan-onboarded', '1');
  renderMealPlan();
  mealCloseChoice();
  showSection('meals');
  const tabBtn = document.querySelector('.ptoggle[onclick*="mp1"]');
  if(tabBtn) switchMealPhase('mp1', tabBtn);
  showToast('Empty week ready — add your meals day by day', 'success');
}
function mealChoiceGenerate(){ mealCloseChoice(); openMealGenerate(); }
function openMealGenerate(){
  _onb = { goal:'fatloss', cuisines:[], avoid:[], veg:false };
  document.querySelectorAll('#onb-modal .onb-chip, #onb-modal .onb-goal').forEach(c => c.classList.remove('on'));
  const nm = (typeof authUser !== 'undefined' && authUser && authUser.user_metadata && authUser.user_metadata.name) || '';
  const t = document.getElementById('onb-title'); if(t) t.textContent = nm ? ("Let's build your plan, " + nm) : "Let's build your meal plan";
  onbStep(1);
  document.getElementById('onb-modal').style.display = 'block';
}
function closeMealOnboarding(){ document.getElementById('onb-modal').style.display = 'none'; }
function onbStep(n){
  const bs = document.getElementById('onb-step-build'); if(bs) bs.style.display = 'none';
  [1,2,3].forEach(i => {
    const s = document.getElementById('onb-step-' + i); if(!s) return;
    if(i === n){ s.style.display = 'block'; s.classList.remove('onb-anim'); void s.offsetWidth; s.classList.add('onb-anim'); }
    else s.style.display = 'none';
  });
  document.querySelectorAll('#onb-dots .onb-dot').forEach((d, idx) => d.classList.toggle('on', idx < n));
}
function onbSetGoal(g, el){ _onb.goal = g; el.parentElement.querySelectorAll('.onb-goal').forEach(b => b.classList.remove('on')); el.classList.add('on'); setTimeout(() => onbStep(2), 260); }
function onbToggle(kind, val, el){
  if(kind === 'veg'){ _onb.veg = !_onb.veg; el.classList.toggle('on', _onb.veg); return; }
  const arr = _onb[kind];
  const idx = arr.indexOf(val);
  if(idx >= 0){ arr.splice(idx,1); el.classList.remove('on'); } else { arr.push(val); el.classList.add('on'); }
}
async function onbBuild(){
  // Show the animated "building…" screen with a line personalised to their picks
  ['onb-step-1','onb-step-2','onb-step-3'].forEach(id => { const s = document.getElementById(id); if(s) s.style.display = 'none'; });
  const bs = document.getElementById('onb-step-build');
  if(bs){ bs.style.display = 'block'; bs.classList.remove('onb-anim'); void bs.offsetWidth; bs.classList.add('onb-anim'); }
  document.querySelectorAll('#onb-dots .onb-dot').forEach(d => d.classList.add('on'));
  const cap = s => s.charAt(0).toUpperCase() + s.slice(1);
  const goalTxt = _onb.goal === 'muscle' ? 'muscle-build' : (_onb.goal === 'maintain' ? 'maintenance' : 'fat-loss');
  const cuisTxt = _onb.cuisines.length ? (' ' + _onb.cuisines.map(cap).join(' & ') + '-leaning') : '';
  const bt = document.getElementById('onb-build-text'); if(bt) bt.textContent = 'Building your' + cuisTxt + ' ' + goalTxt + ' week…';
  try {
    const lib = await loadRecipeLibrary();
    MP_DATA = buildPlanFromPrefs(lib, _onb);
    await new Promise(r => setTimeout(r, 1100));   // let the build animation breathe
    mpSave();
    localStorage.setItem('sbp-mealplan-onboarded', '1');
    renderMealPlan();
    closeMealOnboarding();
    showSection('meals');
    const target = (_onb.goal === 'muscle') ? 'mp2' : 'mp1';
    const tabBtn = document.querySelector('.ptoggle[onclick*="' + target + '"]');
    if(tabBtn) switchMealPhase(target, tabBtn);
    showToast('Your meal plan is ready — tweak anything you like', 'success');
  } catch(e){ showToast('Could not build the plan — try again', 'error'); onbStep(3); }
}
function onbSkip(){ localStorage.setItem('sbp-mealplan-onboarded', '1'); closeMealOnboarding(); }

// ---- Reset: wipe the user's plan (local + synced) and re-run onboarding ----
async function resetMealPlan(){
  if(!confirm('Reset your meal plan and set it up again? This clears your current plan.')) return;
  try { localStorage.removeItem('sbp-mealplan'); } catch(_){}
  localStorage.removeItem('sbp-mealplan-onboarded');
  try {
    if(typeof sb !== 'undefined' && sb && authUser){ await sb.from('app_data').delete().eq('user_id', authUser.id).eq('key', 'sbp-mealplan'); }
  } catch(_){}
  MP_DATA = seedMealPlanFromDOM();   // keep a default visible behind the modal
  renderMealPlan();
  openMealOnboarding();
}

// ==================== MEAL LOGGING (actual vs planned) ====================
// The plan is a weekday template; the log records what actually happened on a
// real calendar date. Day totals recalc from logged actuals when present, else
// fall back to the plan. Stored under sbp-meallog: { [iso]: { [mealId]: entry } }.
let _mealLog = loadStore('sbp-meallog', {});
const _MP_DAYK = ['mon','tue','wed','thu','fri','sat','sun'];
function mealLogSave(){ localStorage.setItem('sbp-meallog', JSON.stringify(_mealLog)); }
// ISO date of the given weekday-key in the current week (mirrors tpDateKey).
function mealDayIso(dayKey){
  const now = new Date(); const ti = (now.getDay() + 6) % 7; const t = _MP_DAYK.indexOf(dayKey);
  if(t < 0) return null;
  const d = new Date(now); d.setDate(now.getDate() + (t - ti));
  return d.toISOString().slice(0, 10);
}
function mealLogFor(dayKey, mealId){
  const iso = mealDayIso(dayKey); if(!iso) return null;
  return (_mealLog[iso] && _mealLog[iso][mealId]) || null;
}
// Effective macros for a planned meal: logged actual when present, else the plan.
function mealEffective(dayKey, m){
  const log = mealLogFor(dayKey, m.id);
  if(!log) return { kcal:+m.kcal||0, p:+m.p||0, c:+m.c||0, f:+m.f||0, status:null };
  if(log.status === 'skipped') return { kcal:0, p:0, c:0, f:0, status:'skipped' };
  return { kcal:+log.kcal||0, p:+log.p||0, c:+log.c||0, f:+log.f||0, status:log.status, name:log.name };
}
function mealSetLog(dayKey, mealId, status, entry){
  const iso = mealDayIso(dayKey); if(!iso) return;
  _mealLog[iso] = _mealLog[iso] || {};
  if(status === 'clear'){ delete _mealLog[iso][mealId]; if(!Object.keys(_mealLog[iso]).length) delete _mealLog[iso]; }
  else _mealLog[iso][mealId] = Object.assign({ status }, entry || {});
  mealLogSave(); renderMealPlan();
}
// Quick actions from a plan card
function mealMarkEaten(pid, dayKey, id){
  const day = mpFindDay(pid, dayKey); if(!day) return;
  const m = day.meals.find(x => x.id === id); if(!m) return;
  mealSetLog(dayKey, id, 'eaten', { name:m.name, kcal:+m.kcal||0, p:+m.p||0, c:+m.c||0, f:+m.f||0 });
  showToast('Logged — ate as planned', 'success');
}
function mealMarkSkipped(pid, dayKey, id){ mealSetLog(dayKey, id, 'skipped', {}); showToast('Marked as skipped', 'info'); }
function mealClearLog(pid, dayKey, id){ mealSetLog(dayKey, id, 'clear'); showToast('Log cleared', 'info'); }

// "I had something else" — swap modal (pick a recipe or type a custom entry)
let _mealSwap = null;   // { pid, dayKey, id }
async function mealOpenSwap(pid, dayKey, id){
  _mealSwap = { pid, dayKey, id };
  const modal = _ensureMealSwapModal();
  const lib = await loadRecipeLibrary();
  const sel = modal.querySelector('#msw-recipe');
  sel.innerHTML = '<option value="">— pick from library —</option>' +
    lib.map(r => '<option value="' + r.id + '">' + esc(r.name) + ' (' + r.kcal + ' kcal)</option>').join('');
  ['name','kcal','p','c','f'].forEach(k => { const el = modal.querySelector('#msw-' + k); if(el) el.value = ''; });
  modal.style.display = 'block';
}
function _ensureMealSwapModal(){
  let m = document.getElementById('meal-swap-modal');
  if(m) return m;
  m = document.createElement('div');
  m.id = 'meal-swap-modal';
  m.style.cssText = 'display:none;position:fixed;inset:0;z-index:220;';
  m.innerHTML =
    '<div class="modal-overlay" onclick="mealCloseSwap()"></div>' +
    '<div class="modal-panel"><div class="modal-header"><div>' +
      '<div class="modal-title">I had something else</div>' +
      '<div class="modal-sub">Log what you actually ate</div>' +
    '</div><button class="modal-close" onclick="mealCloseSwap()"><i class="fa-solid fa-xmark"></i></button></div>' +
    '<div class="modal-body">' +
      '<label class="food-hint" for="msw-recipe">From your recipe library</label>' +
      '<select class="food-input" id="msw-recipe" onchange="mealSwapPick(this.value)"></select>' +
      (FOOD_DB_ENABLED ?
        '<div class="food-hint" style="margin:12px 0 4px">…or search the food database</div>' +
        '<div class="msw-foodsearch"><input class="food-input" id="msw-food" placeholder="e.g. chicken breast" autocomplete="off" onkeydown="if(event.key===\'Enter\'){event.preventDefault();foodSearch();}">' +
        '<button class="shop-act" onclick="foodSearch()"><i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i> Search</button></div>' +
        '<div id="msw-food-results"></div>'
      : '') +
      '<div class="food-hint" style="margin:12px 0 4px">…or type it in</div>' +
      '<input class="food-input" id="msw-name" placeholder="What you ate" autocomplete="off">' +
      '<div class="mp-emac" style="display:grid;grid-template-columns:repeat(4,1fr);gap:6px;margin-top:8px">' +
        '<input class="food-input" id="msw-kcal" type="number" min="0" placeholder="kcal">' +
        '<input class="food-input" id="msw-p" type="number" min="0" placeholder="P">' +
        '<input class="food-input" id="msw-c" type="number" min="0" placeholder="C">' +
        '<input class="food-input" id="msw-f" type="number" min="0" placeholder="F">' +
      '</div>' +
      '<button class="sigate-cta" style="margin-top:14px" onclick="mealSwapSave()">Log it</button>' +
    '</div></div>';
  document.body.appendChild(m);
  return m;
}
function mealCloseSwap(){ const m = document.getElementById('meal-swap-modal'); if(m) m.style.display = 'none'; _mealSwap = null; }
async function mealSwapPick(rid){
  if(!rid) return;
  const lib = await loadRecipeLibrary();
  const r = lib.find(x => x.id === rid); if(!r) return;
  const m = document.getElementById('meal-swap-modal');
  m.querySelector('#msw-name').value = r.name;
  m.querySelector('#msw-kcal').value = r.kcal; m.querySelector('#msw-p').value = r.p;
  m.querySelector('#msw-c').value = r.c; m.querySelector('#msw-f').value = r.f;
}
function mealSwapSave(){
  if(!_mealSwap) return;
  const m = document.getElementById('meal-swap-modal');
  const val = id => m.querySelector('#msw-' + id).value;
  const num = id => { const n = parseInt(val(id), 10); return (isNaN(n) || n < 0) ? 0 : n; };
  const name = (val('name') || '').trim();
  if(!name){ showToast('What did you eat?', 'error'); return; }
  mealSetLog(_mealSwap.dayKey, _mealSwap.id, 'swapped', { name, kcal:num('kcal'), p:num('p'), c:num('c'), f:num('f') });
  mealCloseSwap();
  showToast('Logged what you actually ate', 'success');
}
// ---- Food database search (Worker → Open Food Facts). Macros are per 100g. ----
// Post-launch feature: the /food/search backend isn't production-ready, so the
// search UI stays hidden at launch. Flip to true once the Worker route is live.
const FOOD_DB_ENABLED = false;
let _foodResults = [];
function foodServingGrams(serving){ const m = /(\d+(?:\.\d+)?)\s*g/i.exec(serving || ''); return m ? Math.round(parseFloat(m[1])) : 100; }
function foodScale(food, grams){ const k = grams / 100; return { kcal:Math.round((+food.kcal||0)*k), p:Math.round((+food.p||0)*k), c:Math.round((+food.c||0)*k), f:Math.round((+food.f||0)*k) }; }
async function foodSearch(){
  const q = (document.getElementById('msw-food').value || '').trim();
  const out = document.getElementById('msw-food-results');
  if(q.length < 2){ out.innerHTML = '<div class="food-hint">Type at least 2 letters.</div>'; return; }
  out.innerHTML = '<div class="food-hint">Searching…</div>';
  try {
    const r = await fetch(REMINDER_BACKEND.replace(/\/$/, '') + '/food/search?q=' + encodeURIComponent(q));
    if(r.status === 429){ out.innerHTML = '<div class="food-hint">Too many searches — wait a moment.</div>'; return; }
    if(!r.ok){ out.innerHTML = '<div class="food-hint">Couldn’t search — type it in below instead.</div>'; return; }
    const data = await r.json();
    _foodResults = (data && data.results) || [];
    foodRenderResults();
  } catch(_){ out.innerHTML = '<div class="food-hint">Offline — type it in below instead.</div>'; }
}
function foodRenderResults(){
  const out = document.getElementById('msw-food-results');
  if(!_foodResults.length){ out.innerHTML = '<div class="food-hint">No matches — type it in below.</div>'; return; }
  out.innerHTML = _foodResults.slice(0, 8).map((f, i) => {
    const g = foodServingGrams(f.serving);
    const sub = [f.brand, (+f.kcal||0) + ' kcal/100g'].filter(Boolean).join(' · ');
    return '<div class="msw-food-row"><div class="msw-food-info"><div class="msw-food-name">' + esc(f.name || 'Food') + '</div><div class="msw-food-sub">' + esc(sub) + '</div></div>'
      + '<input class="food-input msw-food-g" type="number" min="1" value="' + g + '" aria-label="grams" style="width:66px">'
      + '<button class="mp-add" style="margin:0" onclick="foodUse(' + i + ', this)">Use</button></div>';
  }).join('');
}
function foodUse(i, btn){
  const f = _foodResults[i]; if(!f) return;
  const row = btn.closest('.msw-food-row');
  const grams = Math.max(1, parseInt(row.querySelector('.msw-food-g').value, 10) || foodServingGrams(f.serving));
  const s = foodScale(f, grams);
  const m = document.getElementById('meal-swap-modal');
  m.querySelector('#msw-name').value = f.name + (f.brand ? ' (' + f.brand + ')' : '') + ' — ' + grams + 'g';
  m.querySelector('#msw-kcal').value = s.kcal; m.querySelector('#msw-p').value = s.p;
  m.querySelector('#msw-c').value = s.c; m.querySelector('#msw-f').value = s.f;
  const sel = m.querySelector('#msw-recipe'); if(sel) sel.value = '';
  showToast('Filled ' + grams + 'g — tap “Log it” to save', 'info');
}
// Reorder a meal within its day
function mpMoveMeal(pid, dayKey, id, dir){
  const day = mpFindDay(pid, dayKey); if(!day) return;
  const i = day.meals.findIndex(x => x.id === id); if(i < 0) return;
  const j = i + dir; if(j < 0 || j >= day.meals.length) return;
  const [it] = day.meals.splice(i, 1); day.meals.splice(j, 0, it);
  mpSave(); renderMealPlan();
}
// Build-your-own: an empty week the user fills in day by day.
function mpEmptyWeek(){
  const days = {};
  _MP_DAYK.forEach(d => { days[d] = { meals: [], tip: '' }; });
  return { v:1, phases: { mp1: { label: 'My plan', days } } };
}

// ==================== EDITABLE TRAINING PLAN ====================
// The "Workout focus" list in each phase becomes editable (add/edit/delete
// sessions), seeded from the static cards and synced. The rest of each phase
// card (metrics, schedule, macros, tip) stays as designed.
let TP_DATA = null;
let _tpEdit = null;   // { pi, id }  — id null = adding
const TP_COLORS = ['#378ADD','#1D9E75','#7F77DD','#BA7517','#D1518A'];
function tpUid(){ return 't' + Date.now().toString(36) + Math.random().toString(36).slice(2,6); }
function seedTrainingFromDOM(){
  const phases = [];
  document.querySelectorAll('#sec-plan .phase-card').forEach((card) => {
    const list = card.querySelector('.workout-list');
    const sessions = [];
    if(list){
      list.querySelectorAll('.workout-item').forEach(it => {
        const dot = it.querySelector('.workout-dot');
        const nameEl = it.querySelector('.workout-name');
        const detEl = it.querySelector('.workout-detail');
        sessions.push({
          id: tpUid(),
          name: nameEl ? nameEl.textContent.trim() : '',
          detail: detEl ? detEl.textContent.trim() : '',
          color: (dot && dot.style.background) ? dot.style.background : TP_COLORS[sessions.length % TP_COLORS.length]
        });
      });
    }
    phases.push({ sessions });
  });
  return { v:1, phases };
}
function tpSave(){ localStorage.setItem('sbp-trainingplan', JSON.stringify(TP_DATA)); }
function tpInit(){
  TP_DATA = loadStore('sbp-trainingplan', null);
  if(TP_DATA && TP_DATA.mode === 'split'){ TP_DATA = migrateSplit(TP_DATA); tpSave(); }
  if(TP_DATA && TP_DATA.mode === 'phases'){ renderTrainingPlan(); return; }
  if(!TP_DATA || !Array.isArray(TP_DATA.phases) || !TP_DATA.phases.length){ TP_DATA = seedTrainingFromDOM(); tpSave(); }
  renderTrainingPlan();
}
function tpSessionHtml(pi, s){
  return '<div class="workout-item">'
    + '<div class="workout-dot" style="background:' + esc(s.color || '#378ADD') + '"></div>'
    + '<div class="wf-content"><div class="workout-name">' + esc(s.name || 'Session') + '</div>'
    + (s.detail ? '<div class="workout-detail">' + esc(s.detail) + '</div>' : '') + '</div>'
    + '<div class="tp-controls">'
    + '<button class="mp-icon" title="Edit" aria-label="Edit session" onclick="tpEdit(' + pi + ',\'' + s.id + '\')">✎</button>'
    + '<button class="mp-icon" title="Delete" aria-label="Delete session" onclick="tpDelete(' + pi + ',\'' + s.id + '\')">✕</button>'
    + '</div></div>';
}
function renderTrainingPlan(){
  if(!TP_DATA) return;
  const sec = document.getElementById('sec-plan');
  if(TP_DATA.mode === 'phases'){ if(sec) sec.classList.add('tp-split'); renderTrainingToday(document.getElementById('tp-myweek'), TP_DATA); return; }
  if(TP_DATA.mode === 'split'){ if(sec) sec.classList.add('tp-split'); tpRenderWeek(document.getElementById('tp-myweek'), TP_DATA, 'live'); return; }
  if(sec) sec.classList.remove('tp-split');
  const cards = document.querySelectorAll('#sec-plan .phase-card');
  TP_DATA.phases.forEach((ph, i) => {
    const card = cards[i]; if(!card) return;
    const list = card.querySelector('.workout-list'); if(!list) return;
    list.innerHTML = (ph.sessions || []).map(s => tpSessionHtml(i, s)).join('')
      + '<button class="mp-add tp-add" onclick="tpAdd(' + i + ')">+ Add session</button>';
  });
}
function tpEdit(pi, id){
  const ph = TP_DATA.phases[pi]; if(!ph) return;
  const s = ph.sessions.find(x => x.id === id); if(!s) return;
  _tpEdit = { pi, id };
  document.getElementById('tp-edit-title').textContent = 'Edit session';
  document.getElementById('tp-f-name').value = s.name || '';
  document.getElementById('tp-f-detail').value = s.detail || '';
  document.getElementById('train-edit-modal').style.display = 'block';
}
function tpAdd(pi){
  _tpEdit = { pi, id:null };
  document.getElementById('tp-edit-title').textContent = 'Add session';
  document.getElementById('tp-f-name').value = '';
  document.getElementById('tp-f-detail').value = '';
  document.getElementById('train-edit-modal').style.display = 'block';
  document.getElementById('tp-f-name').focus();
}
function tpCloseEdit(){ document.getElementById('train-edit-modal').style.display = 'none'; _tpEdit = null; }
function tpSaveEdit(){
  if(!_tpEdit) return;
  const ph = TP_DATA.phases[_tpEdit.pi]; if(!ph) return;
  const name = (document.getElementById('tp-f-name').value || '').trim();
  const detail = (document.getElementById('tp-f-detail').value || '').trim();
  if(!name){ showToast('Give the session a name.', 'error'); return; }
  if(_tpEdit.id){ const s = ph.sessions.find(x => x.id === _tpEdit.id); if(s){ s.name = name; s.detail = detail; } }
  else { ph.sessions.push({ id: tpUid(), name, detail, color: TP_COLORS[ph.sessions.length % TP_COLORS.length] }); }
  tpSave(); renderTrainingPlan(); tpCloseEdit();
  showToast('Session saved', 'success');
}
function tpDelete(pi, id){
  const ph = TP_DATA.phases[pi]; if(!ph) return;
  if(!confirm('Delete this session?')) return;
  ph.sessions = ph.sessions.filter(x => x.id !== id);
  tpSave(); renderTrainingPlan();
  showToast('Session removed', 'info');
}

// ==================== EXERCISE LIBRARY + ENGINE ====================
// Catalog lives in Supabase (table `exercise_library`, public read) with this
// bundled fallback (= backend/exercise-library.sql) so onboarding + swaps work
// offline / while the project is paused. location: which settings it suits.
const EXERCISE_LIBRARY = [
  // chest
  { id:'ex_ch1', name:'Barbell bench press', muscle:'chest', location:['gym'], sets:'4×8–10' },
  { id:'ex_ch2', name:'Dumbbell bench press', muscle:'chest', location:['gym','home'], sets:'4×8–12' },
  { id:'ex_ch3', name:'Incline dumbbell press', muscle:'chest', location:['gym','home'], sets:'3×10–12' },
  { id:'ex_ch4', name:'Press-ups', muscle:'chest', location:['home','bodyweight'], sets:'3×max' },
  { id:'ex_ch5', name:'Cable fly', muscle:'chest', location:['gym'], sets:'3×12–15' },
  { id:'ex_ch6', name:'Chest press machine', muscle:'chest', location:['gym'], sets:'3×10–12' },
  // back
  { id:'ex_bk1', name:'Lat pulldown', muscle:'back', location:['gym'], sets:'4×10–12' },
  { id:'ex_bk2', name:'Pull-ups', muscle:'back', location:['gym','bodyweight'], sets:'4×max' },
  { id:'ex_bk3', name:'Bent-over row', muscle:'back', location:['gym','home'], sets:'4×8–10' },
  { id:'ex_bk4', name:'Seated cable row', muscle:'back', location:['gym'], sets:'3×10–12' },
  { id:'ex_bk5', name:'Dumbbell row', muscle:'back', location:['gym','home'], sets:'3×10–12' },
  { id:'ex_bk6', name:'Inverted row', muscle:'back', location:['home','bodyweight'], sets:'3×max' },
  // shoulders
  { id:'ex_sh1', name:'Overhead press', muscle:'shoulders', location:['gym','home'], sets:'4×8–10' },
  { id:'ex_sh2', name:'Dumbbell shoulder press', muscle:'shoulders', location:['gym','home'], sets:'3×10–12' },
  { id:'ex_sh3', name:'Lateral raises', muscle:'shoulders', location:['gym','home'], sets:'3×12–15' },
  { id:'ex_sh4', name:'Face pulls', muscle:'shoulders', location:['gym'], sets:'3×15' },
  { id:'ex_sh5', name:'Pike press-ups', muscle:'shoulders', location:['home','bodyweight'], sets:'3×max' },
  // biceps
  { id:'ex_bi1', name:'Barbell curl', muscle:'biceps', location:['gym'], sets:'3×10–12' },
  { id:'ex_bi2', name:'Dumbbell curl', muscle:'biceps', location:['gym','home'], sets:'3×10–12' },
  { id:'ex_bi3', name:'Hammer curl', muscle:'biceps', location:['gym','home'], sets:'3×10–12' },
  { id:'ex_bi4', name:'Cable curl', muscle:'biceps', location:['gym'], sets:'3×12–15' },
  { id:'ex_bi5', name:'Chin-ups', muscle:'biceps', location:['gym','bodyweight'], sets:'3×max' },
  // triceps
  { id:'ex_tr1', name:'Tricep pushdown', muscle:'triceps', location:['gym'], sets:'3×12–15' },
  { id:'ex_tr2', name:'Overhead extension', muscle:'triceps', location:['gym','home'], sets:'3×10–12' },
  { id:'ex_tr3', name:'Dips', muscle:'triceps', location:['gym','bodyweight'], sets:'3×max' },
  { id:'ex_tr4', name:'Close-grip press-ups', muscle:'triceps', location:['home','bodyweight'], sets:'3×max' },
  { id:'ex_tr5', name:'Skull crushers', muscle:'triceps', location:['gym','home'], sets:'3×10–12' },
  // legs
  { id:'ex_lg1', name:'Barbell squat', muscle:'legs', location:['gym'], sets:'4×8–10' },
  { id:'ex_lg2', name:'Leg press', muscle:'legs', location:['gym'], sets:'4×10–12' },
  { id:'ex_lg3', name:'Romanian deadlift', muscle:'legs', location:['gym','home'], sets:'3×10–12' },
  { id:'ex_lg4', name:'Walking lunges', muscle:'legs', location:['gym','home','bodyweight'], sets:'3×12 each' },
  { id:'ex_lg5', name:'Leg extension', muscle:'legs', location:['gym'], sets:'3×12–15' },
  { id:'ex_lg6', name:'Goblet squat', muscle:'legs', location:['home'], sets:'3×12–15' },
  { id:'ex_lg7', name:'Bodyweight squat', muscle:'legs', location:['bodyweight'], sets:'3×20' },
  // core
  { id:'ex_co1', name:'Plank', muscle:'core', location:['gym','home','bodyweight'], sets:'3×45s' },
  { id:'ex_co2', name:'Hanging leg raise', muscle:'core', location:['gym','bodyweight'], sets:'3×12' },
  { id:'ex_co3', name:'Cable crunch', muscle:'core', location:['gym'], sets:'3×15' },
  { id:'ex_co4', name:'Bicycle crunch', muscle:'core', location:['home','bodyweight'], sets:'3×20' },
  { id:'ex_co5', name:'Russian twist', muscle:'core', location:['home','bodyweight'], sets:'3×20' }
];
let EX_LIB_CACHE = null;
function normalizeExercise(r){
  const arr = v => Array.isArray(v) ? v : (v ? String(v).split(',').map(s=>s.trim()).filter(Boolean) : []);
  return { id:r.id, name:r.name, muscle:r.muscle, location:arr(r.location), sets:r.sets || '3×10–12' };
}
async function loadExerciseLibrary(){
  if(EX_LIB_CACHE) return EX_LIB_CACHE;
  try {
    if(typeof sb !== 'undefined' && sb){
      const { data, error } = await sb.from('exercise_library').select('*');
      if(!error && data && data.length){ EX_LIB_CACHE = data.map(normalizeExercise); return EX_LIB_CACHE; }
    }
  } catch(_){}
  EX_LIB_CACHE = EXERCISE_LIBRARY.map(normalizeExercise);
  return EX_LIB_CACHE;
}

// Focus (what a day trains) → muscle groups, in priority order.
const FOCUS_MAP = {
  'Push':            ['chest','shoulders','triceps'],
  'Pull':            ['back','biceps'],
  'Legs':            ['legs','core'],
  'Upper body':      ['chest','back','shoulders','biceps','triceps'],
  'Lower body':      ['legs','core'],
  'Full body':       ['legs','chest','back','shoulders'],
  'Chest & triceps': ['chest','triceps'],
  'Back & biceps':   ['back','biceps'],
  'Shoulders & arms':['shoulders','biceps','triceps'],
  'Core & abs':      ['core']
};
const FOCUS_OPTIONS = Object.keys(FOCUS_MAP);
// Sensible default split per training-days-per-week (mapped onto weekdays).
const DEFAULT_SPLITS = {
  3: ['Push','Pull','Legs'],
  4: ['Upper body','Lower body','Upper body','Lower body'],
  5: ['Push','Pull','Legs','Upper body','Lower body'],
  6: ['Push','Pull','Legs','Push','Pull','Legs']
};
const WEEKDAYS = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
// Spread N training days across the week leaving rest days gaps where possible.
function spreadTrainingDays(n){
  const layouts = {
    3: [0,2,4], 4: [0,1,3,4], 5: [0,1,2,4,5], 6: [0,1,2,3,4,5]
  };
  return (layouts[n] || layouts[3]).map(i => WEEKDAYS[i]);
}
// Pick `count` exercises for a focus + location, prioritising the focus muscles.
function recommendExercises(lib, focus, location, count, offset){
  offset = offset || 0;   // shifts which exercise is picked first → variety across same-focus days
  const muscles = FOCUS_MAP[focus] || ['fullbody'];
  const ok = ex => location === 'gym' ? true : ex.location.includes(location);
  const byMuscle = {};
  muscles.forEach(m => { byMuscle[m] = lib.filter(e => e.muscle === m && ok(e)); });
  const picks = [];
  const used = new Set();
  const rounds = {};
  let mi = 0, guard = 0;
  // round-robin across the focus muscles so the session is balanced
  while(picks.length < count && guard < count * 8){
    const m = muscles[mi % muscles.length];
    const pool = byMuscle[m] || [];
    if(pool.length){
      let idx = (offset + (rounds[m] || 0)) % pool.length;
      let tries = 0;
      while(used.has(pool[idx].id) && tries < pool.length){ idx = (idx + 1) % pool.length; tries++; }
      if(!used.has(pool[idx].id)){ picks.push(pool[idx]); used.add(pool[idx].id); }
      rounds[m] = (rounds[m] || 0) + 1;
    }
    mi++; guard++;
  }
  return picks;
}
// Next alternative for an exercise (same muscle, valid location, not already used).
function swapAlternative(lib, current, location, usedIds){
  const ok = ex => location === 'gym' ? true : ex.location.includes(location);
  const pool = lib.filter(e => e.muscle === current.muscle && ok(e) && e.id !== current.id);
  const fresh = pool.filter(e => !usedIds.includes(e.id));
  return (fresh[0] || pool[0] || current);
}

// ---- "Your week" renderer (shared by onboarding preview + saved plan) ----
const LOC_LABEL = { gym:'Full gym', home:'Home + dumbbells', bodyweight:'Bodyweight' };
const GOAL_LABEL = { fatloss:'Fat loss', muscle:'Muscle build', maintain:'Stay fit' };
function tpRenderWeek(el, plan, ctx){
  if(!el || !plan || !plan.days) return;
  const sum = '<div class="tp-week-sum"><b>' + esc(GOAL_LABEL[plan.goal] || '') + '</b> · ' + plan.days.length + ' days/week · ' + esc(LOC_LABEL[plan.location] || '') + '</div>';
  const cards = plan.days.map((d, di) => {
    const exs = (d.exercises || []).map((e, ei) =>
      '<div class="tp-ex"><div class="tp-ex-info" onclick="exOpen(\'' + ctx + '\',' + di + ',' + ei + ')" style="cursor:pointer"><span class="tp-ex-name">' + esc(e.name) + '</span><span class="tp-ex-sets">' + esc(e.sets || '') + '</span></div>'
      + '<button class="mp-icon" title="Swap exercise" aria-label="Swap exercise" onclick="tpSwap(\'' + ctx + '\',' + di + ',' + ei + ')">↻</button></div>'
    ).join('');
    return '<div class="tp-day-card"><div class="tp-day-head"><span class="tp-day-name">' + esc(d.day) + '</span><span class="tp-day-focus">' + esc(d.focus) + '</span></div><div class="tp-ex-list">' + exs + '</div></div>';
  }).join('');
  el.innerHTML = (ctx === 'live' ? sum : '') + '<div class="tp-week">' + cards + '</div>';
}
async function tpSwap(ctx, di, ei){
  const plan = (ctx === 'preview') ? (_tonb && _tonb.plan) : TP_DATA;
  if(!plan || !plan.days || !plan.days[di]) return;
  const lib = EX_LIB_CACHE || await loadExerciseLibrary();
  if(!lib || !lib.length){ showToast('Couldn’t load alternatives — try again', 'error'); return; }
  const day = plan.days[di];
  const ex = day.exercises[ei]; if(!ex) return;
  const used = day.exercises.map(e => e.id);
  const alt = swapAlternative(lib, { id:ex.id, muscle:ex.muscle }, plan.location, used);
  if(!alt || alt.id === ex.id){ showToast('No other option for this muscle', 'info'); return; }
  day.exercises[ei] = { id:alt.id, name:alt.name, muscle:alt.muscle, sets:alt.sets };
  if(ctx === 'preview'){ tpRenderWeek(document.getElementById('tonb-preview'), _tonb.plan, 'preview'); }
  else { tpSave(); tpRenderWeek(document.getElementById('tp-myweek'), TP_DATA, 'live'); showToast('Swapped to ' + alt.name, 'success'); }
}

// ---- Training onboarding: goal → days → location → per-day focus → preview ----
let _tonb = { goal:'muscle', phaseCount:2, weeks:8, days:4, location:'gym', split:[], plan:null };
const TONB_TITLES = { 1:"What's your main goal?", 2:"How's your plan structured?", 3:"How many days a week?", 4:"Where will you train?", 5:"What are you training each day?", 6:"Your plan" };
function openTrainOnboarding(){
  _tonb = { goal:'muscle', phaseCount:2, weeks:8, days:4, location:'gym', split:[], plan:null };
  document.querySelectorAll('#tonb-modal .onb-chip, #tonb-modal .onb-goal').forEach(c => c.classList.remove('on'));
  tonbStep(1);
  document.getElementById('tonb-modal').style.display = 'block';
}
function tonbClose(){ document.getElementById('tonb-modal').style.display = 'none'; }
function tonbStep(n){
  for(let i=1;i<=6;i++){ const s=document.getElementById('tonb-step-'+i); if(!s) continue; if(i===n){ s.style.display='block'; s.classList.remove('onb-anim'); void s.offsetWidth; s.classList.add('onb-anim'); } else s.style.display='none'; }
  document.querySelectorAll('#tonb-prog span').forEach((d, idx) => d.classList.toggle('on', idx < n));
  const sn = document.getElementById('tonb-stepn'); if(sn) sn.textContent = 'Step ' + n + ' of 6';
  const tt = document.getElementById('tonb-title'); if(tt) tt.textContent = TONB_TITLES[n] || '';
}
function tonbSetGoal(g, el){ _tonb.goal = g; el.parentElement.querySelectorAll('.onb-goal').forEach(b => b.classList.remove('on')); el.classList.add('on'); setTimeout(() => tonbStep(2), 240); }
function tonbSetPhases(n, el){ _tonb.phaseCount = n; el.parentElement.querySelectorAll('.onb-chip').forEach(b => b.classList.remove('on')); el.classList.add('on'); }
function tonbSetWeeks(w, el){ _tonb.weeks = w; el.parentElement.querySelectorAll('.onb-chip').forEach(b => b.classList.remove('on')); el.classList.add('on'); }
function tonbSetDays(d, el){ _tonb.days = d; el.parentElement.querySelectorAll('.onb-chip').forEach(b => b.classList.remove('on')); el.classList.add('on'); buildDefaultSplit(); setTimeout(() => tonbStep(4), 200); }
function tonbSetLoc(loc, el){ _tonb.location = loc; el.parentElement.querySelectorAll('.onb-goal').forEach(b => b.classList.remove('on')); el.classList.add('on'); renderDayRows(); setTimeout(() => tonbStep(5), 240); }
function buildDefaultSplit(){
  const wk = spreadTrainingDays(_tonb.days);
  const focuses = DEFAULT_SPLITS[_tonb.days] || DEFAULT_SPLITS[3];
  _tonb.split = wk.map((day, i) => ({ day, focus: focuses[i] || 'Full body' }));
}
function renderDayRows(){
  const opts = FOCUS_OPTIONS.map(f => '<option value="' + f + '">' + f + '</option>').join('');
  document.getElementById('tonb-days').innerHTML = _tonb.split.map((s, i) =>
    '<div class="tonb-day-row"><span class="tonb-day">' + esc(s.day) + '</span><select class="food-input tonb-focus" onchange="tonbSetFocus(' + i + ',this.value)">' + opts + '</select></div>'
  ).join('');
  // set each select to its current focus
  _tonb.split.forEach((s, i) => { const sel = document.querySelectorAll('#tonb-days .tonb-focus')[i]; if(sel) sel.value = s.focus; });
}
function tonbSetFocus(i, val){ if(_tonb.split[i]) _tonb.split[i].focus = val; }
// ---- Rich multi-phase plan: generate from onboarding answers ----
function tpFocusCls(f){
  if(/push|chest/i.test(f)) return 'd-lift';
  if(/pull|back/i.test(f)) return 'd-card';
  if(/leg|lower/i.test(f)) return 'd-foot';
  return 'd-lift';
}
function tpTip(goal){
  return ({
    fatloss: "Two cardio sessions a week keeps you in a fat-burning zone — hit your protein every day and don't skip rest.",
    muscle: "Add a little weight or a rep most weeks. Progressive overload is the whole game — eat slightly above maintenance.",
    maintain: "Consistency beats intensity. Just keep showing up and eat around maintenance."
  })[goal] || "Show up, train hard, recover well.";
}
function buildPhasesPlan(lib, t){
  const base = t.goal === 'muscle' ? 2700 : (t.goal === 'maintain' ? 2400 : 2100);
  const goalLabel = GOAL_LABEL[t.goal] || 'Training';
  const protein = t.goal === 'muscle' ? 180 : 160;
  const wk = spreadTrainingDays(t.days);
  const trainMap = {}; t.split.forEach(s => trainMap[s.day] = s.focus);
  const weeksEach = Math.max(1, Math.round(t.weeks / t.phaseCount));
  const phases = [];
  let weekStart = 1;
  for(let p = 0; p < t.phaseCount; p++){
    const cal = t.goal === 'muscle' ? base + p * 150 : (t.goal === 'fatloss' ? base - p * 50 : base);
    const wEnd = (p === t.phaseCount - 1) ? t.weeks : Math.min(t.weeks, weekStart + weeksEach - 1);
    const sessions = t.split.map((s, i) => ({
      id: tpUid(), day: s.day, name: s.day + ' — ' + s.focus, focus: s.focus, color: TP_COLORS[i % TP_COLORS.length],
      exercises: recommendExercises(lib, s.focus, t.location, 5, p + i).map(e => ({ id:e.id, name:e.name, muscle:e.muscle, sets:e.sets }))
    }));
    const schedule = WEEKDAYS.map(d => trainMap[d] ? { day:d, type:trainMap[d], cls:tpFocusCls(trainMap[d]) } : { day:d, type:'Rest', cls:'d-rest' });
    const fatsG = Math.round(cal * 0.27 / 9), carbsG = Math.max(0, Math.round((cal - protein * 4 - fatsG * 9) / 4));
    const mx = Math.max(protein, carbsG, fatsG);
    const macros = [
      { name:'Protein', val:protein + 'g', pct:Math.round(protein / mx * 100), color:'#378ADD' },
      { name:'Carbs', val:carbsG + 'g', pct:Math.round(carbsG / mx * 100), color:'#7F77DD' },
      { name:'Fats', val:fatsG + 'g', pct:Math.round(fatsG / mx * 100), color:'#1D9E75' }
    ];
    const metrics = [
      { label:'Daily calories', val:'~' + cal.toLocaleString(), sub: t.goal === 'fatloss' ? 'Below maintenance' : (t.goal === 'muscle' ? 'Above maintenance' : 'At maintenance') },
      { label:'Protein', val:protein + 'g', sub:'Every day' },
      { label:'Gym days', val:t.days + '×/week', sub:wk.join(' · ') },
      { label:'Where', val:LOC_LABEL[t.location] || '', sub:'' }
    ];
    phases.push({ id:tpUid(), badge:'Phase ' + (p + 1), name: goalLabel + (t.phaseCount > 1 ? ' · block ' + (p + 1) : ''), dates:'Weeks ' + weekStart + '–' + wEnd, daysPerWeek:t.days, location:t.location, metrics, schedule, sessions, macros, tip: tpTip(t.goal) });
    weekStart = wEnd + 1;
  }
  return { v:3, mode:'phases', goal:t.goal, location:t.location, weeks:t.weeks, phases };
}
// Upgrade a legacy v2 'split' plan to the v3 phases shape so it gets the new view.
function migrateSplit(sp){
  const days = sp.days || [];
  const sessions = days.map((d, i) => ({ id: tpUid(), day: d.day, name: d.day + ' — ' + d.focus, focus: d.focus, color: TP_COLORS[i % TP_COLORS.length], exercises: d.exercises || [] }));
  const trainMap = {}; days.forEach(d => trainMap[d.day] = d.focus);
  const schedule = WEEKDAYS.map(d => trainMap[d] ? { day:d, type:trainMap[d], cls:tpFocusCls(trainMap[d]) } : { day:d, type:'Rest', cls:'d-rest' });
  const goalLabel = GOAL_LABEL[sp.goal] || 'Training';
  const phase = { id: tpUid(), badge:'Phase 1', name:goalLabel, dates:'', daysPerWeek:days.length, location:sp.location,
    metrics:[ {label:'Focus', val:goalLabel, sub:''}, {label:'Gym days', val:days.length + '×/week', sub:''}, {label:'Where', val:LOC_LABEL[sp.location] || '', sub:''} ],
    schedule, sessions, macros:[], tip: tpTip(sp.goal) };
  return { v:3, mode:'phases', goal:sp.goal, location:sp.location, weeks:0, phases:[phase] };
}
function tpExItemHtml(ctx, pi, si, ei, e){
  return '<div class="tp-ex"><div class="tp-ex-info" onclick="exOpenRich(\'' + ctx + '\',' + pi + ',' + si + ',' + ei + ')" style="cursor:pointer"><span class="tp-ex-name">' + esc(e.name) + '</span><span class="tp-ex-sets">' + esc(e.sets || '') + '</span></div>'
    + (ctx === 'live' ? '<button class="mp-icon" title="Move up" aria-label="Move exercise up" onclick="tpExMove(' + pi + ',' + si + ',' + ei + ',-1)">↑</button>'
      + '<button class="mp-icon" title="Move down" aria-label="Move exercise down" onclick="tpExMove(' + pi + ',' + si + ',' + ei + ',1)">↓</button>' : '')
    + '<button class="mp-icon" title="Swap" aria-label="Swap exercise" onclick="tpSwapRich(\'' + ctx + '\',' + pi + ',' + si + ',' + ei + ')">↻</button>'
    + (ctx === 'live' ? '<button class="mp-icon" title="Remove" aria-label="Remove exercise" onclick="tpExDel(' + pi + ',' + si + ',' + ei + ')">✕</button>' : '')
    + '</div>';
}
function tpExMove(pi, si, ei, dir){
  const ph = TP_DATA.phases[pi]; const s = ph && ph.sessions[si]; if(!s) return;
  const j = ei + dir; if(j < 0 || j >= s.exercises.length) return;
  const [it] = s.exercises.splice(ei, 1); s.exercises.splice(j, 0, it);
  tpRefreshDetails();
}
function renderRichPhases(el, plan, ctx){
  if(!el || !plan || !plan.phases) return;
  const edit = ctx === 'live';
  el.innerHTML = plan.phases.map((ph, pi) => {
    let h = '<div class="phase-card tp-anim">';
    h += '<div class="phase-header"><span class="phase-badge pb1">' + esc(ph.badge) + '</span><span class="phase-title">' + esc(ph.name) + '</span><span class="phase-dates">' + esc(ph.dates) + '</span>'
      + (edit ? '<span class="tp-phase-ctrl"><button class="mp-icon" title="Duplicate phase" aria-label="Duplicate phase" onclick="tpPhaseDup(' + pi + ')"><i class="fa-solid fa-copy"></i></button><button class="mp-icon" title="Delete phase" aria-label="Delete phase" onclick="tpPhaseDel(' + pi + ')">✕</button></span>' : '')
      + '</div>';
    h += '<div class="metrics-row">' + ph.metrics.map(m => '<div class="metric-box"><div class="metric-label">' + esc(m.label) + '</div><div class="metric-val">' + esc(m.val) + '</div>' + (m.sub ? '<div class="metric-sub">' + esc(m.sub) + '</div>' : '') + '</div>').join('') + '</div>';
    h += '<div class="section-label">Weekly schedule</div><div class="week-grid">' + ph.schedule.map(d => '<div class="day-box ' + d.cls + '"><div class="day-box-name">' + esc(d.day) + '</div><div class="day-box-type">' + esc(d.type) + '</div></div>').join('') + '</div>';
    h += '<div class="section-label">Workout focus</div>';
    h += ph.sessions.map((s, si) => '<div class="tp-session"><div class="tp-session-head"><span class="tp-session-dot" style="background:' + esc(s.color) + '"></span><span class="tp-session-name">' + esc(s.name) + '</span></div><div class="tp-ex-list">' + s.exercises.map((e, ei) => tpExItemHtml(ctx, pi, si, ei, e)).join('') + '</div>' + (edit ? '<button class="mp-add tp-add" onclick="tpExAdd(' + pi + ',' + si + ')">+ Add exercise</button>' : '') + '</div>').join('');
    if(ph.macros && ph.macros.length){ h += '<div class="section-label">Macros</div>' + ph.macros.map(m => '<div class="macro-bar-row"><span class="macro-bar-name">' + esc(m.name) + '</span><div class="macro-bar-bg"><div class="macro-bar-fill" style="width:' + m.pct + '%;background:' + m.color + '"></div></div><span class="macro-bar-val">' + esc(m.val) + '</span></div>').join(''); }
    h += '</div>';
    return h;
  }).join('') + (edit ? '<button class="mp-add tp-add" style="margin-top:14px" onclick="openNewPhase()">+ Add phase</button>' : '');
}
// ---- Today-forward training view (default): today hero + up next + week strip ----
let _tpSelDay = null, _tpActivePhase = 0;
function tpDayOf(s){ return s.day || (s.name || '').split(' — ')[0]; }
let _tpProg = loadStore('sbp-tp-progress', {});
function tpDateKey(short){ const now = new Date(); const ti = (now.getDay() + 6) % 7; const t = WEEKDAYS.indexOf(short); const d = new Date(now); d.setDate(now.getDate() + (t - ti)); return d.toISOString().slice(0, 10); }
// tp-progress value: true = done, 'skipped' = intentionally skipped (doesn't break
// the streak). Older data stored only `true`, which still reads as done.
function tpProgState(short){ return _tpProg[tpDateKey(short)] || null; }
function tpIsDone(short){ return tpProgState(short) === true; }
function tpIsSkipped(short){ return tpProgState(short) === 'skipped'; }
function tpSaveProg(){ localStorage.setItem('sbp-tp-progress', JSON.stringify(_tpProg)); }
function tpToggleDone(short){ const k = tpDateKey(short); if(_tpProg[k] === true) delete _tpProg[k]; else _tpProg[k] = true; tpSaveProg(); renderTrainingToday(document.getElementById('tp-myweek'), TP_DATA); }
function tpSkipDay(short){ const k = tpDateKey(short); if(_tpProg[k] === 'skipped') delete _tpProg[k]; else _tpProg[k] = 'skipped'; tpSaveProg(); renderTrainingToday(document.getElementById('tp-myweek'), TP_DATA); showToast(_tpProg[k] ? 'Skipped — streak protected' : 'Skip undone', 'info'); }
function tpWeekStat(phase){ const tr = phase.schedule.filter(d => d.type !== 'Rest'); return { done: tr.filter(d => tpIsDone(d.day)).length, total: tr.length }; }
function tpStreak(phase){ let n = 0; const now = new Date(); for(let k = 0; k < 60; k++){ const d = new Date(now); d.setDate(now.getDate() - k); const short = WEEKDAYS[(d.getDay() + 6) % 7]; const sd = phase.schedule.find(x => x.day === short); if(!sd || sd.type === 'Rest') continue; const st = _tpProg[d.toISOString().slice(0, 10)]; if(st === true) n++; else if(st === 'skipped') continue; else break; } return n; }
// Reschedule: move a session + its schedule slot from one weekday to another.
function tpReschedule(pi, fromDay, toDay){
  const phase = TP_DATA.phases[pi]; if(!phase || fromDay === toDay) return;
  const sess = phase.sessions.find(s => tpDayOf(s) === fromDay); if(!sess) return;
  if(phase.sessions.some(s => tpDayOf(s) === toDay)){ showToast('That day already has a session — pick a rest day', 'error'); return; }
  const oldName = sess.name; sess.day = toDay;
  if(/ — /.test(oldName)) sess.name = toDay + ' — ' + oldName.split(' — ')[1];
  const fromSlot = phase.schedule.find(d => d.day === fromDay);
  const toSlot = phase.schedule.find(d => d.day === toDay);
  if(fromSlot && toSlot){ toSlot.type = fromSlot.type; toSlot.cls = fromSlot.cls; fromSlot.type = 'Rest'; fromSlot.cls = 'd-rest'; }
  _tpSelDay = toDay; tpSave(); renderTrainingToday(document.getElementById('tp-myweek'), TP_DATA);
  showToast('Moved to ' + toDay, 'success');
}
function tpOpenReschedule(pi, fromDay){
  const phase = TP_DATA.phases[pi]; if(!phase) return;
  const free = WEEKDAYS.filter(d => d !== fromDay && !phase.sessions.some(s => tpDayOf(s) === d));
  if(!free.length){ showToast('No free day to move to — every day has a session', 'info'); return; }
  const m = _ensureReschedModal();
  const sess = phase.sessions.find(s => tpDayOf(s) === fromDay);
  m.querySelector('#resched-sub').textContent = 'Move ' + (sess ? (sess.focus + ' ') : '') + 'from ' + fromDay + ' to:';
  m.querySelector('#resched-days').innerHTML = free.map(d =>
    '<button class="resched-day" onclick="tpDoReschedule(' + pi + ',\'' + fromDay + '\',\'' + d + '\')">' + esc(d) + '</button>'
  ).join('');
  m.style.display = 'block';
}
function _ensureReschedModal(){
  let m = document.getElementById('resched-modal');
  if(m) return m;
  m = document.createElement('div');
  m.id = 'resched-modal';
  m.style.cssText = 'display:none;position:fixed;inset:0;z-index:220;';
  m.innerHTML =
    '<div class="modal-overlay" onclick="tpCloseReschedule()"></div>' +
    '<div class="modal-panel"><div class="modal-header"><div>' +
      '<div class="modal-title">Reschedule session</div>' +
      '<div class="modal-sub" id="resched-sub"></div>' +
    '</div><button class="modal-close" onclick="tpCloseReschedule()"><i class="fa-solid fa-xmark"></i></button></div>' +
    '<div class="modal-body"><div class="resched-daygrid" id="resched-days"></div></div></div>';
  document.body.appendChild(m);
  return m;
}
function tpCloseReschedule(){ const m = document.getElementById('resched-modal'); if(m) m.style.display = 'none'; }
function tpDoReschedule(pi, fromDay, toDay){ tpCloseReschedule(); tpReschedule(pi, fromDay, toDay); }
// ---- Readiness: daily check-in → score that tunes training (wearables auto-fill later) ----
function rdTodayKey(){ return new Date().toISOString().slice(0, 10); }
function rdLog(){ return loadStore('sbp-readiness', {}); }
function todayReadiness(){ return rdLog()[rdTodayKey()] || null; }
function rdScore(sleep, energy, soreness){ return Math.round((sleep + energy + (6 - soreness)) / 15 * 100); }
let _rd = { sleep: 3, energy: 3, soreness: 3 };
function readinessBanner(){
  const r = todayReadiness();
  if(!r){ return '<div class="tpt-readiness rd-prompt" onclick="openReadiness()"><div class="rd-txt"><b>How are you feeling today?</b><span>10-second check-in to tune today\'s training</span></div><span class="rd-btn">Check in</span></div>'; }
  const c = r.score >= 75 ? 'good' : (r.score >= 50 ? 'ok' : 'low');
  const msg = c === 'good' ? 'Good to go — train hard' : (c === 'ok' ? 'A bit run down — keep it moderate' : 'Take it easier or rest today');
  return '<div class="tpt-readiness rd-' + c + '" onclick="openReadiness()"><div class="rd-score">' + r.score + '<span>%</span></div><div class="rd-txt"><b>Readiness</b><span>' + msg + '</span></div><i class="fa-solid fa-chevron-right" aria-hidden="true"></i></div>';
}
function openReadiness(){
  const r = todayReadiness(); _rd = r ? { sleep:r.sleep, energy:r.energy, soreness:r.soreness } : { sleep:3, energy:3, soreness:3 };
  ['sleep','energy','soreness'].forEach(m => document.querySelectorAll('#rd-' + m + ' .rd-chip').forEach(b => b.classList.toggle('on', +b.dataset.v === _rd[m])));
  rdUpdatePreview();
  document.getElementById('readiness-modal').style.display = 'block';
}
function closeReadiness(){ document.getElementById('readiness-modal').style.display = 'none'; }
function rdSet(metric, val, el){ _rd[metric] = val; el.parentElement.querySelectorAll('.rd-chip').forEach(b => b.classList.remove('on')); el.classList.add('on'); rdUpdatePreview(); }
function rdUpdatePreview(){
  const s = rdScore(_rd.sleep, _rd.energy, _rd.soreness);
  const c = s >= 75 ? 'good' : (s >= 50 ? 'ok' : 'low');
  const msg = c === 'good' ? 'Good to go — train hard' : (c === 'ok' ? 'A bit run down — keep it moderate' : 'Take it easier or rest today');
  const sc = document.getElementById('rd-prev-score'); if(sc){ sc.innerHTML = s + '<span>%</span>'; sc.className = 'rd-prev-score rdc-' + c; }
  const m = document.getElementById('rd-prev-msg'); if(m) m.textContent = msg;
}
function saveReadiness(){
  const log = rdLog();
  log[rdTodayKey()] = { sleep:_rd.sleep, energy:_rd.energy, soreness:_rd.soreness, score: rdScore(_rd.sleep, _rd.energy, _rd.soreness), source:'manual' };
  localStorage.setItem('sbp-readiness', JSON.stringify(log));
  closeReadiness();
  if(TP_DATA && TP_DATA.mode === 'phases') renderTrainingToday(document.getElementById('tp-myweek'), TP_DATA);
  showToast('Readiness logged — plan tuned for today', 'success');
}
// ---- Connect a wearable (Whoop/Oura/Fitbit/Garmin/Apple Watch). Wired but gated. ----
const WEARABLES_ENABLED = false;   // flip true once provider keys + Worker OAuth are live
function wearLink(){ return '<div class="wear-link" onclick="openWearables()"><i class="fa-solid fa-heart-pulse" aria-hidden="true"></i> Connect a wearable to auto-fill readiness</div>'; }
function openWearables(){ document.getElementById('wearable-modal').style.display = 'block'; }
function closeWearables(){ document.getElementById('wearable-modal').style.display = 'none'; }
function connectWearable(p){
  if(!WEARABLES_ENABLED){ showToast('Wearable sync is coming soon — we\'re finishing it ⌚', 'info'); return; }
  // Future: kick off OAuth via the Worker (see backend/wearables.js)
  window.location.href = REMINDER_BACKEND + '/wearable/' + p + '/start';
}
function renderTrainingToday(el, plan){
  if(!el || !plan || !plan.phases || !plan.phases.length) return;
  const pi = Math.min(_tpActivePhase, plan.phases.length - 1);
  const phase = plan.phases[pi];
  const todayShort = WEEKDAYS[(new Date().getDay() + 6) % 7];
  const selDay = _tpSelDay || todayShort;
  const isToday = selDay === todayShort;
  const sIdx = phase.sessions.findIndex(s => tpDayOf(s) === selDay);
  const sess = sIdx >= 0 ? phase.sessions[sIdx] : null;
  let hero;
  if(sess){
    const exs = sess.exercises.map((e, ei) => '<div class="tpt-ex" onclick="exOpenRich(\'live\',' + pi + ',' + sIdx + ',' + ei + ')"><span class="tpt-ex-n">' + esc(e.name) + '</span><span class="tpt-ex-s">' + esc(e.sets || '') + '</span></div>').join('');
    const done = tpIsDone(selDay);
    const skipped = tpIsSkipped(selDay);
    hero = '<div class="tpt-hero"><div class="tpt-hero-top"><span class="tpt-lbl">' + (isToday ? 'Today · ' : '') + esc(selDay) + '</span><span class="tpt-focus">' + esc(sess.focus) + (skipped ? ' · skipped' : '') + '</span></div>'
      + '<div class="tpt-title">' + esc((sess.name.split(' — ')[1]) || sess.focus) + '</div><div class="tpt-exlist">' + exs + '</div>'
      + '<button class="tpt-done' + (done ? ' is-done' : '') + '" onclick="tpToggleDone(\'' + selDay + '\')">' + (done ? '<i class="fa-solid fa-check" aria-hidden="true"></i> Done' : 'Mark as done') + '</button>'
      + '<div class="tpt-hero-acts"><button class="tpt-mini' + (skipped ? ' on' : '') + '" onclick="tpSkipDay(\'' + selDay + '\')"><i class="fa-solid fa-forward" aria-hidden="true"></i> ' + (skipped ? 'Skipped' : 'Skip') + '</button>'
      + '<button class="tpt-mini" onclick="tpOpenReschedule(' + pi + ',\'' + selDay + '\')"><i class="fa-solid fa-calendar-day" aria-hidden="true"></i> Reschedule</button></div></div>';
  } else {
    hero = '<div class="tpt-hero tpt-rest"><div class="tpt-lbl">' + (isToday ? 'Today · ' : '') + esc(selDay) + '</div><div class="tpt-title">Rest day</div><div class="tpt-restsub">Recover well — back at it tomorrow.</div></div>';
  }
  const tiles = '<div class="tpt-tiles">' + (phase.metrics || []).map(m => '<div class="tpt-tile"><div class="l">' + esc(m.label) + '</div><div class="v">' + esc(m.val) + '</div>' + (m.sub ? '<div class="s">' + esc(m.sub) + '</div>' : '') + '</div>').join('') + '</div>';
  let nextSess = null, nextDay = null;
  for(let k = 1; k <= 7; k++){ const d = WEEKDAYS[(WEEKDAYS.indexOf(selDay) + k) % 7]; const ns = phase.sessions.find(s => tpDayOf(s) === d); if(ns){ nextSess = ns; nextDay = d; break; } }
  const upnext = nextSess ? '<div class="tpt-next" onclick="tpSelectDay(\'' + nextDay + '\')"><div><div class="tpt-next-lbl">Up next · ' + esc(nextDay) + '</div><div class="tpt-next-t">' + esc(nextSess.focus) + '</div><div class="tpt-next-x">' + nextSess.exercises.slice(0, 3).map(e => esc(e.name)).join(' · ') + '</div></div><i class="fa-solid fa-chevron-right" style="color:var(--text-tertiary)" aria-hidden="true"></i></div>' : '';
  const stat = tpWeekStat(phase), streak = tpStreak(phase), pct = stat.total ? Math.round(stat.done / stat.total * 100) : 0;
  const prog = '<div class="tpt-prog"><div class="tpt-prog-row"><span>This week</span><span>' + stat.done + ' / ' + stat.total + '</span></div><div class="tpt-prog-bar"><div style="width:' + pct + '%"></div></div><div class="tpt-streak"><i class="fa-solid fa-fire" aria-hidden="true"></i> ' + streak + '-day streak</div></div>';
  const strip = phase.schedule.map(d => { const train = d.type !== 'Rest'; const ck = train && tpIsDone(d.day) ? '<span class="ck"><i class="fa-solid fa-check" aria-hidden="true"></i></span>' : ''; return '<div class="tpt-wk' + (d.day === selDay ? ' on' : '') + (train ? '' : ' rest') + '"' + (train ? ' onclick="tpSelectDay(\'' + d.day + '\')"' : '') + '>' + ck + '<span class="d">' + esc(d.day) + '</span><span class="f">' + esc(d.type) + '</span></div>'; }).join('');
  const tip = phase.tip ? '<div class="tpt-tip"><i class="fa-solid fa-lightbulb" aria-hidden="true"></i>' + esc(phase.tip) + '</div>' : '';
  el.innerHTML = '<div class="tpt-wrap">'
    + readinessBanner() + wearLink()
    + '<div class="tpt-phaserow"><button class="tpt-phasepill" onclick="openPhaseDetails()">' + esc(phase.badge) + ' · ' + esc(phase.name) + ' <i class="fa-solid fa-chevron-right" style="font-size:10px" aria-hidden="true"></i></button><span class="tpt-wk-lbl">' + esc(phase.dates || '') + '</span></div>'
    + '<div class="tpt-main">' + hero + tiles + '</div>'
    + '<div class="tpt-side">' + upnext + prog + '<div class="tpt-week-lbl">This week</div><div class="tpt-strip">' + strip + '</div>' + tip + '</div>'
    + '</div>';
}
function tpSelectDay(d){ _tpSelDay = d; renderTrainingToday(document.getElementById('tp-myweek'), TP_DATA); }
function openPhaseDetails(){ renderRichPhases(document.getElementById('phase-details-body'), TP_DATA, 'live'); document.getElementById('phase-details-modal').style.display = 'block'; }
function closePhaseDetails(){ document.getElementById('phase-details-modal').style.display = 'none'; }
async function tonbPreview(){
  const lib = await loadExerciseLibrary();
  _tonb.plan = buildPhasesPlan(lib, _tonb);
  tonbStep(6);
  renderRichPhases(document.getElementById('tonb-preview'), _tonb.plan, 'preview');
}
function tonbSave(){
  if(!_tonb.plan) return;
  TP_DATA = _tonb.plan;
  _tpSelDay = null; _tpActivePhase = 0;
  tpSave();
  localStorage.setItem('sbp-train-onboarded', '1');
  renderTrainingPlan();
  tonbClose();
  showSection('plan');
  showToast('Your training plan is ready 💪', 'success');
}

// ==================== EXERCISE DETAIL (WorkoutX) ====================
// Tap an exercise → animated demo GIF + instructions from WorkoutX, with the
// worked muscles highlighted on the body map. Falls back to just the muscle
// map (driven by our own muscle tag) when no key is set or the API is down.
const WORKOUTX_KEY = 'wx_5964653f7338f5d1e316118bf2ad272b72c935cf6ec1fa7dc5641362';   // free WorkoutX key (workoutxapp.com)
const WORKOUTX_BASE = 'https://api.workoutxapp.com/v1';
function workoutxConfigured(){ return typeof WORKOUTX_KEY === 'string' && WORKOUTX_KEY.indexOf('wx_') === 0; }
let _exCache = {};
try { _exCache = JSON.parse(localStorage.getItem('bb-ex-cache')) || {}; } catch(_){}

// Detailed anatomical muscle map — polygon data from react-body-highlighter (MIT).
const BODY_MUSCLE = {"anterior":[{"m":"chest","pts":["51.8367347 41.6326531 51.0204082 55.1020408 57.9591837 57.9591837 67.755102 55.5102041 70.6122449 47.3469388 62.0408163 41.6326531","29.7959184 46.5306122 31.4285714 55.5102041 40.8163265 57.9591837 48.1632653 55.1020408 47.755102 42.0408163 37.5510204 42.0408163"]},{"m":"obliques","pts":["68.5714286 63.2653061 67.3469388 57.1428571 58.7755102 59.5918367 60 64.0816327 60.4081633 83.2653061 65.7142857 78.7755102 66.5306122 69.7959184","33.877551 78.3673469 33.0612245 71.8367347 31.0204082 63.2653061 32.244898 57.1428571 40.8163265 59.1836735 39.1836735 63.2653061 39.1836735 83.6734694"]},{"m":"abs","pts":["56.3265306 59.1836735 57.9591837 64.0816327 58.3673469 77.9591837 58.3673469 92.6530612 56.3265306 98.3673469 55.1020408 104.081633 51.4285714 107.755102 51.0204082 84.4897959 50.6122449 67.3469388 51.0204082 57.1428571","43.6734694 58.7755102 48.5714286 57.1428571 48.9795918 67.3469388 48.5714286 84.4897959 48.1632653 107.346939 44.4897959 103.673469 40.8163265 91.4285714 40.8163265 78.3673469 41.2244898 64.4897959"]},{"m":"biceps","pts":["16.7346939 68.1632653 17.9591837 71.4285714 22.8571429 66.122449 28.9795918 53.877551 27.755102 49.3877551 20.4081633 55.9183673","71.4285714 49.3877551 70.2040816 54.6938776 76.3265306 66.122449 81.6326531 71.8367347 82.8571429 68.9795918 78.7755102 55.5102041"]},{"m":"triceps","pts":["69.3877551 55.5102041 69.3877551 61.6326531 75.9183673 72.6530612 77.5510204 70.2040816 75.5102041 67.3469388","22.4489796 69.3877551 29.7959184 55.5102041 29.7959184 60.8163265 22.8571429 73.0612245"]},{"m":"neck","pts":["55.5102041 23.6734694 50.6122449 33.4693878 50.6122449 39.1836735 61.6326531 40 70.6122449 44.8979592 69.3877551 36.7346939 63.2653061 35.1020408 58.3673469 30.6122449","28.9795918 44.8979592 30.2040816 37.1428571 36.3265306 35.1020408 41.2244898 30.2040816 44.4897959 24.4897959 48.9795918 33.877551 48.5714286 39.1836735 37.9591837 39.5918367"]},{"m":"front-deltoids","pts":["78.3673469 53.0612245 79.5918367 47.755102 79.1836735 41.2244898 75.9183673 37.9591837 71.0204082 36.3265306 72.244898 42.8571429 71.4285714 47.3469388","28.1632653 47.3469388 21.2244898 53.0612245 20 47.755102 20.4081633 40.8163265 24.4897959 37.1428571 28.5714286 37.1428571 26.9387755 43.2653061"]},{"m":"head","pts":["42.4489796 2.85714286 40 11.8367347 42.0408163 19.5918367 46.122449 23.2653061 49.7959184 25.3061224 54.6938776 22.4489796 57.5510204 19.1836735 59.1836735 10.2040816 57.1428571 2.44897959 49.7959184 0"]},{"m":"abductors","pts":["52.6530612 110.204082 54.2857143 124.897959 60 110.204082 62.0408163 100 64.8979592 94.2857143 60 92.6530612 56.7346939 104.489796","47.755102 110.612245 44.8979592 125.306122 42.0408163 115.918367 40.4081633 113.061224 39.5918367 107.346939 37.9591837 102.44898 34.6938776 93.877551 39.5918367 92.244898 41.6326531 99.1836735 43.6734694 105.306122"]},{"m":"quadriceps","pts":["34.6938776 98.7755102 37.1428571 108.163265 37.1428571 127.755102 34.2857143 137.142857 31.0204082 132.653061 29.3877551 120 28.1632653 111.428571 29.3877551 100.816327 32.244898 94.6938776","63.2653061 105.714286 64.4897959 100 66.9387755 94.6938776 70.2040816 101.22449 71.0204082 111.836735 68.1632653 133.061224 65.3061224 137.55102 62.4489796 128.571429 62.0408163 111.428571","38.7755102 129.387755 38.3673469 112.244898 41.2244898 118.367347 44.4897959 129.387755 42.8571429 135.102041 40 146.122449 36.3265306 146.530612 35.5102041 140","59.5918367 145.714286 55.5102041 128.979592 60.8163265 113.877551 61.2244898 130.204082 64.0816327 139.591837 62.8571429 146.530612","32.6530612 138.367347 26.5306122 145.714286 25.7142857 136.734694 25.7142857 127.346939 26.9387755 114.285714 29.3877551 133.469388","71.8367347 113.061224 73.877551 124.081633 73.877551 140.408163 72.6530612 145.714286 66.5306122 138.367347 70.2040816 133.469388"]},{"m":"knees","pts":["33.877551 140 34.6938776 143.265306 35.5102041 147.346939 36.3265306 151.020408 35.1020408 156.734694 29.7959184 156.734694 27.3469388 152.653061 27.3469388 147.346939 30.2040816 144.081633","65.7142857 140 72.244898 147.755102 72.244898 152.244898 69.7959184 157.142857 64.8979592 156.734694 62.8571429 151.020408"]},{"m":"calves","pts":["71.4285714 160.408163 73.4693878 153.469388 76.7346939 161.22449 79.5918367 167.755102 78.3673469 187.755102 79.5918367 195.510204 74.6938776 195.510204","24.8979592 194.693878 27.755102 164.897959 28.1632653 160.408163 26.122449 154.285714 24.8979592 157.55102 22.4489796 161.632653 20.8163265 167.755102 22.0408163 188.163265 20.8163265 195.510204","72.6530612 195.102041 69.7959184 159.183673 65.3061224 158.367347 64.0816327 162.44898 64.0816327 165.306122 65.7142857 177.142857","35.5102041 158.367347 35.9183673 162.44898 35.9183673 166.938776 35.1020408 172.244898 35.1020408 176.734694 32.244898 182.040816 30.6122449 187.346939 26.9387755 194.693878 27.3469388 187.755102 28.1632653 180.408163 28.5714286 175.510204 28.9795918 169.795918 29.7959184 164.081633 30.2040816 158.77551"]},{"m":"forearm","pts":["6.12244898 88.5714286 10.2040816 75.1020408 14.6938776 70.2040816 16.3265306 74.2857143 19.1836735 73.4693878 4.48979592 97.5510204 0 100","84.4897959 69.7959184 83.2653061 73.4693878 80 73.0612245 95.1020408 98.3673469 100 100.408163 93.4693878 89.3877551 89.7959184 76.3265306","77.5510204 72.244898 77.5510204 77.5510204 80.4081633 84.0816327 85.3061224 89.7959184 92.244898 101.22449 94.6938776 99.5918367","6.93877551 101.22449 13.4693878 90.6122449 18.7755102 84.0816327 21.6326531 77.1428571 21.2244898 71.8367347 4.89795918 98.7755102"]}],"posterior":[{"m":"head","pts":["50.6382979 0 45.9574468 0.85106383 40.8510638 5.53191489 40.4255319 12.7659574 45.106383 20 55.7446809 20 59.1489362 13.6170213 59.5744681 4.68085106 55.7446809 1.27659574"]},{"m":"trapezius","pts":["44.6808511 21.7021277 47.6595745 21.7021277 47.2340426 38.2978723 47.6595745 64.6808511 38.2978723 53.1914894 35.3191489 40.8510638 31.0638298 36.5957447 39.1489362 33.1914894 43.8297872 27.2340426","52.3404255 21.7021277 55.7446809 21.7021277 56.5957447 27.2340426 60.8510638 32.7659574 68.9361702 36.5957447 64.6808511 40.4255319 61.7021277 53.1914894 52.3404255 64.6808511 53.1914894 38.2978723"]},{"m":"back-deltoids","pts":["29.3617021 37.0212766 22.9787234 39.1489362 17.4468085 44.2553191 18.2978723 53.6170213 24.2553191 49.3617021 27.2340426 46.3829787","71.0638298 37.0212766 78.2978723 39.5744681 82.5531915 44.6808511 81.7021277 53.6170213 74.893617 48.9361702 72.3404255 45.106383"]},{"m":"upper-back","pts":["31.0638298 38.7234043 28.0851064 48.9361702 28.5106383 55.3191489 34.0425532 75.3191489 47.2340426 71.0638298 47.2340426 66.3829787 36.5957447 54.0425532 33.6170213 41.2765957","68.9361702 38.7234043 71.9148936 49.3617021 71.4893617 56.1702128 65.9574468 75.3191489 52.7659574 71.0638298 52.7659574 66.3829787 63.4042553 54.4680851 66.3829787 41.7021277"]},{"m":"triceps","pts":["26.8085106 49.787234 17.8723404 55.7446809 14.4680851 72.3404255 16.5957447 81.7021277 21.7021277 63.8297872 26.8085106 55.7446809","73.6170213 50.212766 82.1276596 55.7446809 85.9574468 73.1914894 83.4042553 82.1276596 77.8723404 62.9787234 73.1914894 55.7446809","26.8085106 58.2978723 26.8085106 68.5106383 22.9787234 75.3191489 19.1489362 77.4468085 22.5531915 65.5319149","72.7659574 58.2978723 77.0212766 64.6808511 80.4255319 77.4468085 76.5957447 75.3191489 72.7659574 68.9361702"]},{"m":"lower-back","pts":["47.6595745 72.7659574 34.4680851 77.0212766 35.3191489 83.4042553 49.3617021 102.12766 46.8085106 82.9787234","52.3404255 72.7659574 65.5319149 77.0212766 64.6808511 83.4042553 50.6382979 102.12766 53.1914894 83.8297872"]},{"m":"forearm","pts":["86.3829787 75.7446809 91.0638298 83.4042553 93.1914894 94.0425532 100 106.382979 96.1702128 104.255319 88.0851064 89.3617021 84.2553191 83.8297872","13.6170213 75.7446809 8.93617021 83.8297872 6.80851064 93.6170213 0 106.382979 3.82978723 104.255319 12.3404255 88.5106383 15.7446809 82.9787234","81.2765957 79.5744681 77.4468085 77.8723404 79.1489362 84.6808511 91.0638298 103.829787 93.1914894 108.93617 94.4680851 104.680851","18.7234043 79.5744681 22.1276596 77.8723404 20.8510638 84.2553191 9.36170213 102.978723 6.80851064 108.510638 5.10638298 104.680851"]},{"m":"gluteal","pts":["44.6808511 99.5744681 30.212766 108.510638 29.787234 118.723404 31.4893617 125.957447 47.2340426 121.276596 49.3617021 114.893617","55.3191489 99.1489362 51.0638298 114.468085 52.3404255 120.851064 68.0851064 125.957447 69.787234 119.148936 69.3617021 108.510638"]},{"m":"adductor","pts":["48.0851064 122.978723 44.6808511 122.978723 41.2765957 125.531915 45.106383 144.255319 48.5106383 135.744681 48.9361702 129.361702","51.9148936 122.553191 55.7446809 123.404255 59.1489362 125.957447 54.893617 144.255319 51.9148936 136.170213 51.0638298 129.361702"]},{"m":"hamstring","pts":["28.9361702 122.12766 31.0638298 129.361702 36.5957447 125.957447 35.3191489 135.319149 34.4680851 150.212766 29.3617021 158.297872 28.9361702 146.808511 27.6595745 141.276596 27.2340426 131.489362","71.4893617 121.702128 69.3617021 128.93617 63.8297872 125.957447 65.5319149 136.595745 66.3829787 150.212766 71.0638298 158.297872 71.4893617 147.659574 72.7659574 142.12766 73.6170213 131.914894","38.7234043 125.531915 44.2553191 145.957447 40.4255319 166.808511 36.1702128 152.765957 37.0212766 135.319149","61.7021277 125.531915 63.4042553 136.170213 64.2553191 153.191489 60 166.808511 56.1702128 146.382979"]},{"m":"knees","pts":["34.4680851 153.191489 31.0638298 159.148936 33.6170213 166.382979 37.4468085 162.553191","66.3829787 153.617021 62.9787234 162.978723 66.8085106 166.382979 69.3617021 159.148936"]},{"m":"calves","pts":["29.3617021 160.425532 28.5106383 167.234043 24.6808511 179.574468 23.8297872 192.765957 25.5319149 197.021277 28.5106383 193.191489 29.787234 180 31.9148936 171.06383 31.9148936 166.808511","37.4468085 165.106383 35.3191489 167.659574 33.1914894 171.914894 31.0638298 180.425532 30.212766 191.914894 34.0425532 200 38.7234043 190.638298 39.1489362 168.93617","62.9787234 165.106383 61.2765957 168.510638 61.7021277 190.638298 66.3829787 199.574468 70.6382979 191.914894 68.9361702 179.574468 66.8085106 170.212766","70.6382979 160.425532 72.3404255 168.510638 75.7446809 179.148936 76.5957447 192.765957 74.4680851 196.595745 72.3404255 193.617021 70.6382979 179.574468 68.0851064 168.085106"]},{"m":"left-soleus","pts":["28.5106383 195.744681 30.212766 195.744681 33.6170213 201.702128 30.6382979 220 28.5106383 213.617021 26.8085106 198.297872"]},{"m":"right-soleus","pts":["69.787234 195.744681 71.9148936 195.744681 73.6170213 198.297872 71.9148936 213.191489 70.212766 219.574468 67.2340426 202.12766"]}]};/*BMDATA*/
function bodyMuscleSvg(view){
  let polys = '';
  (BODY_MUSCLE[view] || []).forEach(d => d.pts.forEach(p => { polys += '<polygon class="bm" data-m="' + d.m + '" points="' + p + '"></polygon>'; }));
  return '<svg viewBox="0 0 100 200" width="100%" aria-hidden="true">' + polys + '</svg>';
}
let _bmBuilt = false;
function buildBodyMaps(){
  if(_bmBuilt) return;
  const a = document.getElementById('bm-anterior'), p = document.getElementById('bm-posterior');
  if(a) a.innerHTML = bodyMuscleSvg('anterior');
  if(p) p.innerHTML = bodyMuscleSvg('posterior');
  _bmBuilt = !!(a && p);
}
function muscleSlugs(name){
  const n = (name || '').toLowerCase(), o = [];
  if(/pec|chest/.test(n)) o.push('chest');
  if(/delt|shoulder/.test(n)) o.push('front-deltoids','back-deltoids');
  if(/bicep/.test(n)) o.push('biceps');
  if(/tricep/.test(n)) o.push('triceps');
  if(/forearm/.test(n)) o.push('forearm');
  if(/lat|upper.?back|trap/.test(n)) o.push('upper-back','trapezius');
  if(/lower.?back|spinae|erector/.test(n)) o.push('lower-back');
  if(/abs|core|\bab\b/.test(n)) o.push('abs');
  if(/oblique/.test(n)) o.push('obliques');
  if(/glute/.test(n)) o.push('gluteal');
  if(/ham/.test(n)) o.push('hamstring');
  if(/quad/.test(n)) o.push('quadriceps');
  if(/calf|calv|soleus/.test(n)) o.push('calves','left-soleus','right-soleus');
  if(/adductor/.test(n)) o.push('adductor');
  if(/abductor/.test(n)) o.push('abductors');
  return o;
}
function groupSlugs(g){
  return ({ chest:['chest'], back:['upper-back','trapezius'], shoulders:['front-deltoids','back-deltoids'], biceps:['biceps'], triceps:['triceps'], legs:['quadriceps','hamstring','gluteal','calves'], core:['abs','obliques'], arms:['biceps','triceps'], forearms:['forearm'] })[g] || muscleSlugs(g);
}
function exHighlightA(primary, secondary){
  document.querySelectorAll('#exd-body .bm').forEach(el => { el.classList.remove('on'); el.classList.remove('sec'); });
  (secondary || []).forEach(s => document.querySelectorAll('#exd-body .bm[data-m="' + s + '"]').forEach(el => el.classList.add('sec')));
  (primary || []).forEach(s => document.querySelectorAll('#exd-body .bm[data-m="' + s + '"]').forEach(el => el.classList.add('on')));
}
// WorkoutX uses US/singular naming; map our names to a search term that hits.
const WX_ALIASES = {
  'press-ups':'push up', 'close-grip press-ups':'close grip push up', 'pike press-ups':'pike push up',
  'lateral raises':'lateral raise', 'walking lunges':'walking lunge', 'chest press machine':'machine chest press',
  'skull crushers':'skull crusher', 'overhead extension':'tricep extension', 'bent-over row':'bent over row',
  'seated cable row':'cable row', 'face pulls':'face pull', 'chin-ups':'chin up', 'pull-ups':'pull up',
  'dips':'tricep dips', 'bodyweight squat':'squat', 'hanging leg raise':'hanging leg raise', 'press-ups':'push-up'
};
function wxSearchTerm(name){
  const k = (name || '').toLowerCase().trim();
  if(WX_ALIASES[k]) return WX_ALIASES[k];
  return k.replace(/press-ups?/g, 'push up').replace(/-/g, ' ');
}
async function wxQuery(term){
  const res = await fetch(WORKOUTX_BASE + '/exercises/name/' + encodeURIComponent(term) + '?api-key=' + encodeURIComponent(WORKOUTX_KEY));
  if(!res.ok) return null;
  const data = await res.json();
  const list = Array.isArray(data) ? data : (data.data || data.exercises || data.results || []);
  return list[0] || (data && data.gifUrl ? data : null);
}
async function workoutxByName(name){
  const cacheKey = (name || '').toLowerCase().trim();
  if(_exCache[cacheKey]) return _exCache[cacheKey];
  if(!workoutxConfigured()) return null;
  try {
    const term = wxSearchTerm(name);
    let ex = await wxQuery(term);
    if(!ex){ const simpler = term.replace(/s$/, ''); if(simpler && simpler !== term) ex = await wxQuery(simpler); }
    if(!ex) return null;
    const gif = ex.gifUrl ? (ex.gifUrl + (ex.gifUrl.indexOf('?') < 0 ? '?' : '&') + 'api-key=' + encodeURIComponent(WORKOUTX_KEY)) : null;
    const rec = { name: ex.name || name, gif, target: ex.target || '', secondary: ex.secondaryMuscles || [], steps: ex.instructions || [] };
    _exCache[cacheKey] = rec;
    try { localStorage.setItem('bb-ex-cache', JSON.stringify(_exCache)); } catch(_){}
    return rec;
  } catch(_){ return null; }
}
// Map a muscle name (ours or WorkoutX's) → a body-map region id.
function exMuscleGroup(m){
  const n = (m || '').toLowerCase();
  if(/pec|chest/.test(n)) return 'chest';
  if(/delt|shoulder/.test(n)) return 'shoulders';
  if(/bicep|tricep|forearm|brachi|arm/.test(n)) return 'arms';
  if(/lat|trap|\bback\b|rhomboid|spinae|erector/.test(n)) return 'back';
  if(/ab|core|oblique/.test(n)) return 'core';
  if(/quad|hamstring|glute|calf|leg|adductor/.test(n)) return 'legs';
  return null;
}
function exHighlight(primary, secondary){
  document.querySelectorAll('#exd-body .ex-m').forEach(el => { el.classList.remove('on'); el.classList.remove('sec'); });
  (secondary || []).forEach(g => { if(g) document.querySelectorAll('#exd-body .ex-m[data-m="' + g + '"]').forEach(el => { void el.offsetWidth; el.classList.add('sec'); }); });
  if(primary) document.querySelectorAll('#exd-body .ex-m[data-m="' + primary + '"]').forEach(el => { void el.offsetWidth; el.classList.add('on'); });
}
function exOpen(ctx, di, ei){
  const plan = (ctx === 'preview') ? (_tonb && _tonb.plan) : TP_DATA;
  if(!plan || !plan.days || !plan.days[di]) return;
  const ex = plan.days[di].exercises[ei]; if(!ex) return;
  exShow(ex);
}
// Rich multi-phase: resolve exercise from phases[pi].sessions[si].exercises[ei]
function exPlanFor(ctx){ return (ctx === 'preview') ? (_tonb && _tonb.plan) : TP_DATA; }
function exOpenRich(ctx, pi, si, ei){
  const plan = exPlanFor(ctx); if(!plan || !plan.phases) return;
  const s = plan.phases[pi] && plan.phases[pi].sessions[si]; if(!s) return;
  const ex = s.exercises[ei]; if(!ex) return;
  exShow(ex);
}
async function tpSwapRich(ctx, pi, si, ei){
  const plan = exPlanFor(ctx); if(!plan || !plan.phases) return;
  const s = plan.phases[pi] && plan.phases[pi].sessions[si]; if(!s) return;
  const ex = s.exercises[ei]; if(!ex) return;
  const lib = EX_LIB_CACHE || await loadExerciseLibrary();   // lazy-load so swap never silently no-ops
  if(!lib || !lib.length){ showToast('Couldn’t load alternatives — try again', 'error'); return; }
  const used = s.exercises.map(e => e.id);
  const alt = swapAlternative(lib, { id:ex.id, muscle:ex.muscle }, plan.location || 'gym', used);
  if(!alt || alt.id === ex.id){ showToast('No other option for this muscle', 'info'); return; }
  s.exercises[ei] = { id:alt.id, name:alt.name, muscle:alt.muscle, sets:alt.sets };
  if(ctx === 'preview'){ renderRichPhases(document.getElementById('tonb-preview'), _tonb.plan, 'preview'); }
  else { tpRefreshDetails(); showToast('Swapped to ' + alt.name, 'success'); }
}
// ---- Plan editing: phases (add/duplicate/delete) + exercises (add/remove) ----
function tpRefreshDetails(){
  tpSave();
  renderTrainingToday(document.getElementById('tp-myweek'), TP_DATA);
  if(document.getElementById('phase-details-modal').style.display === 'block'){ renderRichPhases(document.getElementById('phase-details-body'), TP_DATA, 'live'); }
}
function tpRenumberPhases(){ TP_DATA.phases.forEach((p, i) => p.badge = 'Phase ' + (i + 1)); }
function tpPhaseDup(pi){
  const src = TP_DATA.phases[pi]; if(!src) return;
  const clone = JSON.parse(JSON.stringify(src));
  clone.id = tpUid(); (clone.sessions || []).forEach(s => s.id = tpUid());
  TP_DATA.phases.splice(pi + 1, 0, clone); tpRenumberPhases(); tpRefreshDetails(); showToast('Phase duplicated', 'success');
}
function tpPhaseDel(pi){
  if(TP_DATA.phases.length <= 1){ showToast('Keep at least one phase', 'error'); return; }
  if(!confirm('Delete this phase?')) return;
  TP_DATA.phases.splice(pi, 1); if(_tpActivePhase >= TP_DATA.phases.length) _tpActivePhase = 0; tpRenumberPhases(); tpRefreshDetails(); showToast('Phase deleted', 'info');
}
function tpPhaseAdd(){
  const last = TP_DATA.phases[TP_DATA.phases.length - 1]; if(!last) return;
  const clone = JSON.parse(JSON.stringify(last));
  clone.id = tpUid(); (clone.sessions || []).forEach(s => s.id = tpUid());
  TP_DATA.phases.push(clone); tpRenumberPhases(); tpRefreshDetails(); showToast('Phase added', 'success');
}
async function tpExAdd(pi, si){
  const ph = TP_DATA.phases[pi]; const s = ph && ph.sessions[si]; if(!s) return;
  const lib = await loadExerciseLibrary();
  const used = s.exercises.map(e => e.id);
  const pool = recommendExercises(lib, s.focus, ph.location || 'gym', 8, 0).filter(e => !used.includes(e.id));
  const pick = pool[0]; if(!pick){ showToast('No more for this focus', 'info'); return; }
  s.exercises.push({ id:pick.id, name:pick.name, muscle:pick.muscle, sets:pick.sets });
  tpRefreshDetails();
}
function tpExDel(pi, si, ei){
  const ph = TP_DATA.phases[pi]; const s = ph && ph.sessions[si]; if(!s) return;
  s.exercises.splice(ei, 1); tpRefreshDetails();
}
// ---- New phase: template → guided form → create ----
const NP_TEMPLATES = {
  fatloss:  { name:'Fat loss',     goal:'fatloss',  weeks:6, days:4, location:'gym' },
  muscle:   { name:'Muscle build', goal:'muscle',   weeks:8, days:5, location:'gym' },
  strength: { name:'Strength',     goal:'muscle',   weeks:6, days:4, location:'gym' },
  recomp:   { name:'Recomp',       goal:'maintain', weeks:8, days:4, location:'gym' },
  blank:    { name:'New phase',    goal:'muscle',   weeks:4, days:3, location:'gym' }
};
let _np = { name:'New phase', goal:'muscle', weeks:6, days:4, location:'gym' };
function openNewPhase(){ document.getElementById('newphase-modal').style.display = 'block'; npStep('tpl'); }
function closeNewPhase(){ document.getElementById('newphase-modal').style.display = 'none'; }
function npStep(s){
  document.getElementById('np-step-tpl').style.display = s === 'tpl' ? 'block' : 'none';
  document.getElementById('np-step-form').style.display = s === 'form' ? 'block' : 'none';
  document.getElementById('np-title').textContent = s === 'tpl' ? 'Add a phase' : 'Customise phase';
  document.getElementById('np-sub').textContent = s === 'tpl' ? 'Pick a starting point' : 'Tweak it, then create';
}
function npHighlight(groupId, val){ document.querySelectorAll('#' + groupId + ' .onb-chip').forEach(b => b.classList.toggle('on', b.dataset.v === String(val))); }
function npPickTemplate(t){
  _np = Object.assign({}, NP_TEMPLATES[t] || NP_TEMPLATES.blank);
  document.getElementById('np-name').value = _np.name;
  npHighlight('np-goal', _np.goal); npHighlight('np-weeks', _np.weeks); npHighlight('np-days', _np.days); npHighlight('np-where', _np.location);
  npStep('form');
}
function npSet(field, val, el){ _np[field] = val; el.parentElement.querySelectorAll('.onb-chip').forEach(b => b.classList.remove('on')); el.classList.add('on'); }
function npDefaultSplit(days){ const wk = spreadTrainingDays(days); const f = DEFAULT_SPLITS[days] || DEFAULT_SPLITS[3]; return wk.map((d, i) => ({ day:d, focus:f[i] || 'Full body' })); }
async function npCreate(){
  const btn = document.getElementById('np-create-btn'); if(btn){ btn.disabled = true; btn.textContent = 'Creating…'; }
  try {
    const lib = await loadExerciseLibrary();
    const t = { goal:_np.goal, location:_np.location, weeks:_np.weeks, phaseCount:1, days:_np.days, split: npDefaultSplit(_np.days) };
    const ph = buildPhasesPlan(lib, t).phases[0];
    ph.name = (document.getElementById('np-name').value || '').trim() || _np.name;
    ph.dates = '';
    TP_DATA.phases.push(ph); tpRenumberPhases();
    closeNewPhase(); tpRefreshDetails(); showToast('Phase added', 'success');
  } catch(e){ showToast('Could not create phase', 'error'); }
  finally { if(btn){ btn.disabled = false; btn.textContent = 'Create phase'; } }
}
// ==================== PER-SET LOGGING (reps/weight, with history) ====================
// sbp-setlogs: { [iso]: { [exId]: [{ r:reps, w:weight }] } }
let _setLogs = loadStore('sbp-setlogs', {});
let _exCur = null;   // exercise currently open in the detail modal
function setLogSave(){ localStorage.setItem('sbp-setlogs', JSON.stringify(_setLogs)); }
function setLogTodayKey(){ return new Date().toISOString().slice(0, 10); }
function setLogGet(exId, iso){ return (_setLogs[iso] && _setLogs[iso][exId]) || []; }
function setLogPut(exId, sets){
  const iso = setLogTodayKey();
  _setLogs[iso] = _setLogs[iso] || {};
  if(!sets.length){ delete _setLogs[iso][exId]; if(!Object.keys(_setLogs[iso]).length) delete _setLogs[iso]; }
  else _setLogs[iso][exId] = sets;
  setLogSave();
  // Logged sets feed Progress: a day with any logged set counts as a workout.
  if(sets.length && typeof workoutLog !== 'undefined'){
    if(!workoutLog[iso]){ workoutLog[iso] = true; localStorage.setItem('sbp-workouts', JSON.stringify(workoutLog)); if(typeof updateWorkoutStats === 'function') updateWorkoutStats(); }
  }
}
// Most recent PAST date (not today) with logged sets for this exercise.
function setLogLast(exId){
  const today = setLogTodayKey();
  const dates = Object.keys(_setLogs).filter(iso => iso < today && _setLogs[iso][exId] && _setLogs[iso][exId].length).sort().reverse();
  return dates.length ? { iso: dates[0], sets: _setLogs[dates[0]][exId] } : null;
}
function exSetAdd(){
  if(!_exCur) return;
  const sets = setLogGet(_exCur.id, setLogTodayKey()).slice();
  const last = sets[sets.length - 1];
  sets.push(last ? { r:last.r, w:last.w } : { r:'', w:'' });
  setLogPut(_exCur.id, sets); exRenderSetLog(_exCur);
}
function exSetChange(i, field, val){
  if(!_exCur) return;
  const sets = setLogGet(_exCur.id, setLogTodayKey()).slice();
  if(!sets[i]) return;
  const n = parseFloat(val); sets[i][field] = (isNaN(n) || n < 0) ? '' : n;
  setLogPut(_exCur.id, sets);   // no re-render — keep focus in the input
}
function exSetDel(i){
  if(!_exCur) return;
  const sets = setLogGet(_exCur.id, setLogTodayKey()).slice();
  sets.splice(i, 1); setLogPut(_exCur.id, sets); exRenderSetLog(_exCur);
}
function exRenderSetLog(ex){
  let panel = document.getElementById('exd-setlog');
  if(!panel){
    panel = document.createElement('div');
    panel.id = 'exd-setlog';
    const steps = document.getElementById('exd-steps');
    if(steps && steps.parentNode) steps.parentNode.insertBefore(panel, steps);
    else document.querySelector('#exercise-detail-modal .modal-body, #exercise-detail-modal .modal-panel')?.appendChild(panel);
  }
  const sets = setLogGet(ex.id, setLogTodayKey());
  const last = setLogLast(ex.id);
  const lastLine = last
    ? '<div class="exd-lastlog">Last time (' + esc(last.iso.slice(5)) + '): ' + last.sets.map(s => (s.w ? s.w + 'kg×' : '') + (s.r || '–')).join(', ') + '</div>'
    : '<div class="exd-lastlog">No history yet — log your first sets below.</div>';
  const rows = sets.map((s, i) =>
    '<div class="exd-setrow"><span class="exd-setn">' + (i + 1) + '</span>'
    + '<input class="food-input" type="number" min="0" inputmode="numeric" placeholder="reps" value="' + (s.r === '' || s.r == null ? '' : s.r) + '" oninput="exSetChange(' + i + ',\'r\',this.value)">'
    + '<input class="food-input" type="number" min="0" inputmode="decimal" placeholder="kg" value="' + (s.w === '' || s.w == null ? '' : s.w) + '" oninput="exSetChange(' + i + ',\'w\',this.value)">'
    + '<button class="mp-icon" title="Remove set" aria-label="Remove set" onclick="exSetDel(' + i + ')">✕</button></div>'
  ).join('');
  panel.innerHTML = '<div class="exd-setlog-h">Log your sets</div>' + lastLine
    + '<div class="exd-setrows">' + rows + '</div>'
    + '<button class="mp-add" onclick="exSetAdd()">+ Add set</button>';
}
function exShow(ex){
  _exCur = ex;
  exRenderSetLog(ex);
  document.getElementById('exd-name').textContent = ex.name;
  document.getElementById('exd-sets').textContent = ex.sets || '';
  buildBodyMaps();
  const primary = groupSlugs(ex.muscle);
  exHighlightA(primary, []);
  document.getElementById('exd-targets').textContent = '';
  const gifWrap = document.getElementById('exd-gif');
  const steps = document.getElementById('exd-steps');
  steps.innerHTML = '';
  gifWrap.innerHTML = workoutxConfigured()
    ? '<div class="ph">Loading demo…</div>'
    : '<div class="ph">Add your free WorkoutX key in the code to show the animated demo. Muscles are mapped from your plan.</div>';
  document.getElementById('exercise-detail-modal').style.display = 'block';
  workoutxByName(ex.name).then(rec => {
    if(!rec){ if(workoutxConfigured()) gifWrap.innerHTML = '<div class="ph">No demo found for this one.</div>'; return; }
    if(rec.gif){ gifWrap.innerHTML = '<img src="' + rec.gif + '" alt="' + esc(rec.name) + ' demo" loading="lazy">'; }
    else gifWrap.innerHTML = '<div class="ph">No demo found for this one.</div>';
    const sec = (rec.secondary || []).reduce((a, m) => a.concat(muscleSlugs(m)), []);
    const prim = muscleSlugs(rec.target);
    exHighlightA(prim.length ? prim : primary, sec);
    const tg = [rec.target].concat(rec.secondary || []).filter(Boolean).join(' · ');
    document.getElementById('exd-targets').textContent = tg;
    if(rec.steps && rec.steps.length){ steps.innerHTML = rec.steps.map((s, i) => '<div class="exd-step"><span class="exd-step-n">' + (i + 1) + '</span><span>' + esc(s) + '</span></div>').join(''); }
  });
}
function exClose(){ document.getElementById('exercise-detail-modal').style.display = 'none'; }

// ==================== SHOPPING ====================
function switchShopPhase(id, el) {
  document.getElementById('sp1').style.display = 'none';
  document.getElementById('sp2').style.display = 'none';
  document.getElementById(id).style.display = 'block';
  el.parentElement.querySelectorAll('.ptoggle').forEach(t => t.classList.remove('on'));
  el.classList.add('on');
}
function switchShopCat(phase, cat, el) {
  document.querySelectorAll('#' + phase + ' .cc').forEach(c => c.classList.remove('show'));
  document.getElementById(phase + '-' + cat).classList.add('show');
  document.querySelectorAll('#' + phase + ' .ctab').forEach(t => t.classList.remove('on'));
  el.classList.add('on');
}
function toggleShop(el, phase) {
  el.classList.toggle('done');
  const check = el.querySelector('.item-check');
  if(el.classList.contains('done')) {
    check.innerHTML = '<i class="fa-solid fa-check" style="font-size:10px;color:white"></i>';
    check.style.background = 'var(--green-500)';
    check.style.borderColor = 'var(--green-500)';
  } else {
    check.innerHTML = '';
    check.style.background = '';
    check.style.borderColor = '';
  }
  updateShopProgress(phase);
  persistShop(phase);
}
// Save which items are ticked (by position) so the list survives a refresh
function persistShop(phase) {
  const items = document.querySelectorAll('#' + phase + ' .shop-item');
  shopState[phase] = Array.from(items).map(el => el.classList.contains('done'));
  localStorage.setItem('sbp-shop', JSON.stringify(shopState));
}
// Re-apply ticked items on load
function applyShopState(phase) {
  const saved = shopState[phase];
  if(!Array.isArray(saved)) return;
  const items = document.querySelectorAll('#' + phase + ' .shop-item');
  if(saved.length !== items.length) return; // list changed between versions — skip
  items.forEach((el, i) => {
    if(!saved[i]) return;
    el.classList.add('done');
    const check = el.querySelector('.item-check');
    check.innerHTML = '<i class="fa-solid fa-check" style="font-size:10px;color:white"></i>';
    check.style.background = 'var(--green-500)';
    check.style.borderColor = 'var(--green-500)';
  });
}
function updateShopProgress(phase) {
  const all = document.querySelectorAll('#' + phase + ' .shop-item');
  const done = document.querySelectorAll('#' + phase + ' .shop-item.done');
  const total = all.length;
  const checked = done.length;
  const pct = total ? Math.round((checked / total) * 100) : 0;
  const bar = document.getElementById(phase + '-bar');
  const count = document.getElementById(phase + '-count');
  if(bar) bar.style.width = pct + '%';
  if(count) count.textContent = checked + ' / ' + total + ' items';
}
function resetShop(phase) {
  document.querySelectorAll('#' + phase + ' .shop-item').forEach(el => {
    el.classList.remove('done');
    const check = el.querySelector('.item-check');
    check.innerHTML = '';
    check.style.background = '';
    check.style.borderColor = '';
  });
  updateShopProgress(phase);
  persistShop(phase);
}

// ==================== PROGRESS ====================
// Safe loader — corrupt localStorage must never crash the whole app
function loadStore(key, fallback) {
  try {
    const v = JSON.parse(localStorage.getItem(key));
    return (v === null || v === undefined) ? fallback : v;
  } catch(e) {
    console.warn('Could not read saved data for "' + key + '" — starting fresh.', e);
    return fallback;
  }
}
// Escape any user-supplied text before inserting it into HTML
function esc(s) {
  return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}
let weightLog = loadStore('sbp-weight', []);
let workoutLog = loadStore('sbp-workouts', {});
let shopState = loadStore('sbp-shop', {});
let currentWeek = 1;
let weightChart = null;

// ==================== RECIPES ====================
let recipes = loadStore('sbp-recipes', []);
let _recipeDraft = null;
const PLATFORM_LABEL = { tiktok:'TikTok', instagram:'Instagram', youtube:'YouTube' };

function persistRecipes() { localStorage.setItem('sbp-recipes', JSON.stringify(recipes)); }

// Build a safe embed for a recipe. iframes for YouTube/TikTok; thumbnail link
// fallback for Instagram and unresolved TikTok ids.
function buildEmbed(platform, id, thumbnail, canonicalUrl) {
  if (platform === 'youtube' && id) {
    return '<iframe class="recipe-embed r-youtube" src="https://www.youtube.com/embed/' + esc(id) +
      '" loading="lazy" allow="encrypted-media; picture-in-picture" allowfullscreen referrerpolicy="strict-origin-when-cross-origin"></iframe>';
  }
  if (platform === 'tiktok' && id) {
    return '<iframe class="recipe-embed r-tiktok" src="https://www.tiktok.com/embed/v2/' + esc(id) +
      '" loading="lazy" allow="encrypted-media" allowfullscreen></iframe>';
  }
  return '<a class="recipe-embed-fallback" href="' + esc(canonicalUrl) + '" target="_blank" rel="noopener">' +
    (thumbnail ? '<img src="' + esc(thumbnail) + '" alt="">' : '') +
    '<span>Open on ' + esc(PLATFORM_LABEL[platform] || 'the app') + ' ↗</span></a>';
}

function showRecipesSoon() {
  document.getElementById('recipe-soon-modal').style.display = 'block';
  document.body.style.overflow = 'hidden';
}
function closeRecipesSoon() {
  document.getElementById('recipe-soon-modal').style.display = 'none';
  document.body.style.overflow = '';
}

/* ---- Center ＋ FAB quick-add menu (mobile) ---- */
function toggleQuickMenu() {
  const menu = document.getElementById('quick-menu');
  menu.classList.contains('show') ? closeQuickMenu() : openQuickMenu();
}
function openQuickMenu() {
  document.getElementById('quick-menu').classList.add('show');
  document.getElementById('quick-menu').setAttribute('aria-hidden', 'false');
  document.getElementById('quick-menu-backdrop').classList.add('show');
  const fab = document.getElementById('bnav-fab');
  fab.classList.add('open'); fab.setAttribute('aria-expanded', 'true');
}
function closeQuickMenu() {
  document.getElementById('quick-menu').classList.remove('show');
  document.getElementById('quick-menu').setAttribute('aria-hidden', 'true');
  document.getElementById('quick-menu-backdrop').classList.remove('show');
  const fab = document.getElementById('bnav-fab');
  fab.classList.remove('open'); fab.setAttribute('aria-expanded', 'false');
}
function qmGo(action) {
  closeQuickMenu();
  if (action === 'logfood') {
    showSection('today');
    document.querySelector('.bottom-nav .bnav-item').classList.add('active');
    const fi = document.getElementById('food-input');
    if (fi) { fi.scrollIntoView({ behavior: 'smooth', block: 'center' }); setTimeout(() => fi.focus(), 350); }
  } else if (action === 'weight') {
    showSection('progress');
    const wi = document.getElementById('weight-input');
    if (wi) { wi.scrollIntoView({ behavior: 'smooth', block: 'center' }); setTimeout(() => wi.focus(), 350); }
  } else if (action === 'meals') {
    showSection('meals');
  } else if (action === 'shopping') {
    showSection('shopping');
  }
}

function openAddRecipe() {
  _recipeDraft = null;
  document.getElementById('recipe-modal-title').textContent = 'Add a recipe';
  document.getElementById('recipe-modal-sub').textContent = 'Paste a TikTok, Instagram or YouTube link';
  document.getElementById('recipe-step-url').style.display = 'block';
  document.getElementById('recipe-step-edit').style.display = 'none';
  document.getElementById('recipe-url-input').value = '';
  document.getElementById('recipe-embed-slot').innerHTML = '';
  document.getElementById('recipe-modal').style.display = 'block';
  document.body.style.overflow = 'hidden';
}
function closeRecipeModal() {
  document.getElementById('recipe-modal').style.display = 'none';
  document.getElementById('recipe-embed-slot').innerHTML = ''; // tear down iframe
  document.body.style.overflow = '';
}

async function getRecipeDraft() {
  const url = document.getElementById('recipe-url-input').value.trim();
  if (!url) { showToast('Paste a link first', 'error'); return; }
  const btn = document.getElementById('recipe-get-btn');
  btn.disabled = true; btn.textContent = 'Getting recipe…';
  let d = null;
  try {
    const r = await fetch(REMINDER_BACKEND.replace(/\/$/, '') + '/recipe/extract', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ url }),
    });
    if (r.ok) d = await r.json();
    else if (r.status === 429) showToast('Too many tries — wait a bit and retry', 'error');
    else if (r.status === 400) showToast('That link isn’t a TikTok/Instagram/YouTube post', 'error');
  } catch (_) {}
  btn.disabled = false; btn.textContent = 'Get recipe';

  // Always open the editable form, even on failure (graceful degradation).
  d = d || { platform: 'unknown', embedId: null, canonicalUrl: url, title: '', author: '', thumbnail: '', ingredients: [], steps: [], macros: null, extractionQuality: 'empty' };
  _recipeDraft = { url, canonicalUrl: d.canonicalUrl || url, platform: d.platform, embedId: d.embedId || null, author: d.author || '', thumbnail: d.thumbnail || '' };

  document.getElementById('rf-title').value = d.title || '';
  document.getElementById('rf-ingredients').value = (d.ingredients || []).join('\n');
  document.getElementById('rf-steps').value = (d.steps || []).join('\n');
  document.getElementById('rf-p').value = d.macros ? (d.macros.p ?? '') : '';
  document.getElementById('rf-c').value = d.macros ? (d.macros.c ?? '') : '';
  document.getElementById('rf-f').value = d.macros ? (d.macros.f ?? '') : '';
  document.getElementById('rf-kcal').value = d.macros ? (d.macros.kcal ?? '') : '';
  document.getElementById('recipe-embed-slot').innerHTML = buildEmbed(d.platform, d.embedId, d.thumbnail, d.canonicalUrl);

  if (d.extractionQuality === 'empty') showToast('Couldn’t read much — fill it in below', 'info');
  else if (d.extractionQuality === 'good') showToast('Got it — check the details below', 'success');

  document.getElementById('recipe-modal-title').textContent = 'Edit recipe';
  document.getElementById('recipe-modal-sub').textContent = 'Tidy it up, then save';
  document.getElementById('recipe-step-url').style.display = 'none';
  document.getElementById('recipe-step-edit').style.display = 'block';
}

function saveRecipe() {
  if (!_recipeDraft) return;
  const toLines = s => s.split('\n').map(x => x.trim()).filter(Boolean);
  const num = id => { const v = parseFloat(document.getElementById(id).value); return isNaN(v) ? 0 : v; };
  const p = num('rf-p'), c = num('rf-c'), f = num('rf-f'), kcal = num('rf-kcal');
  const rec = {
    id: 'r_' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
    url: _recipeDraft.url, canonicalUrl: _recipeDraft.canonicalUrl,
    platform: _recipeDraft.platform, embedId: _recipeDraft.embedId,
    title: (document.getElementById('rf-title').value.trim()) || 'Untitled recipe',
    author: _recipeDraft.author, thumbnail: _recipeDraft.thumbnail,
    ingredients: toLines(document.getElementById('rf-ingredients').value),
    steps: toLines(document.getElementById('rf-steps').value),
    macros: (p || c || f || kcal) ? { p, c, f, kcal } : null,
    tags: [], rating: 0,
    createdAt: Date.now(), updatedAt: Date.now(),
  };
  recipes.unshift(rec);
  persistRecipes();
  closeRecipeModal();
  renderRecipes();
  showToast('Recipe saved', 'success');
}

function renderRecipes() {
  const wrap = document.getElementById('recipes-list');
  if (!wrap) return;
  if (!recipes.length) {
    wrap.innerHTML = '<div class="recipe-empty">No saved recipes yet.<br>Tap “Add a recipe” and paste a link to get started.</div>';
    return;
  }
  wrap.innerHTML = recipes.map(r => {
    const thumb = r.thumbnail
      ? '<img class="recipe-card-thumb" loading="lazy" src="' + esc(r.thumbnail) + '" alt="">'
      : '<div class="recipe-card-thumb placeholder"><svg viewBox="0 0 24 24"><rect x="3" y="3" width="18" height="18" rx="3"/><polygon points="10 8 16 12 10 16"/></svg></div>';
    const kcal = (r.macros && r.macros.kcal) ? '<div class="recipe-card-kcal">~' + r.macros.kcal + ' kcal</div>' : '';
    return '<div class="recipe-card">' +
      '<div class="recipe-card-head" onclick="openRecipe(\'' + r.id + '\')">' +
        thumb +
        '<div class="recipe-card-info">' +
          '<div class="recipe-card-title">' + esc(r.title) + '</div>' +
          '<div class="recipe-card-meta"><span class="recipe-plat">' + esc(PLATFORM_LABEL[r.platform] || r.platform || '') + '</span>' +
            (r.author ? '· ' + esc(r.author) : '') + '</div>' +
          kcal +
        '</div>' +
      '</div>' +
      starRatingHtml(r.id, r.rating, false) +
    '</div>';
  }).join('');
}

function starRatingHtml(id, rating, large) {
  let s = '<div class="star-rating' + (large ? ' lg' : '') + '" data-rid="' + id + '">';
  for (let i = 1; i <= 5; i++) {
    s += '<button class="star' + (i <= rating ? ' on' : '') + '" onclick="event.stopPropagation();setRating(\'' + id + '\',' + i + ')" aria-label="' + i + ' star' + (i > 1 ? 's' : '') + '">★</button>';
  }
  return s + '</div>';
}

function setRating(id, n) {
  const r = recipes.find(x => x.id === id);
  if (!r) return;
  r.rating = (r.rating === n) ? 0 : n;   // tap the same star to clear
  r.updatedAt = Date.now();
  persistRecipes();
  renderRecipes();
  // keep the detail view in sync if open
  const open = document.getElementById('recipe-view-modal');
  if (open && open.style.display === 'block' && _openRecipeId === id) {
    const slot = document.getElementById('rv-rating');
    if (slot) slot.outerHTML = '<div id="rv-rating">' + starRatingHtml(id, r.rating, true) + '</div>';
  }
}

let _openRecipeId = null;
function openRecipe(id) {
  const r = recipes.find(x => x.id === id);
  if (!r) return;
  _openRecipeId = id;
  document.getElementById('rv-title').textContent = r.title;
  document.getElementById('rv-author').textContent = (PLATFORM_LABEL[r.platform] || '') + (r.author ? ' · ' + r.author : '');
  const ings = r.ingredients.length
    ? '<div class="rv-section-title">Ingredients</div><ul class="rv-ings">' + r.ingredients.map(i => '<li>' + esc(i) + '</li>').join('') + '</ul>'
    : '';
  const steps = r.steps.length
    ? '<div class="rv-section-title">Method</div><ol class="rv-steps">' + r.steps.map(s => '<li>' + esc(s) + '</li>').join('') + '</ol>'
    : '';
  const macros = r.macros
    ? '<div class="mpills"><span class="pill pill-p">P: ' + r.macros.p + 'g</span><span class="pill pill-c">C: ' + r.macros.c + 'g</span><span class="pill pill-f">F: ' + r.macros.f + 'g</span></div>'
    : '';
  document.getElementById('rv-body').innerHTML =
    buildEmbed(r.platform, r.embedId, r.thumbnail, r.canonicalUrl) +
    '<div id="rv-rating">' + starRatingHtml(id, r.rating, true) + '</div>' +
    ings + steps + macros +
    '<button class="recipe-delete" onclick="deleteRecipe(\'' + id + '\')">Delete recipe</button>';
  document.getElementById('recipe-view-modal').style.display = 'block';
  document.body.style.overflow = 'hidden';
}
function closeRecipeView() {
  document.getElementById('recipe-view-modal').style.display = 'none';
  document.getElementById('rv-body').innerHTML = ''; // tear down iframe
  _openRecipeId = null;
  document.body.style.overflow = '';
}
function deleteRecipe(id) {
  recipes = recipes.filter(x => x.id !== id);
  persistRecipes();
  closeRecipeView();
  renderRecipes();
  showToast('Recipe deleted', 'info');
}

// Training days per week (0=Sun,1=Mon,...,6=Sat)
const trainingDays = {
  p1a: [1,2,3,4,5],     // Mon-Fri (Thu = football)
  p1b: [1,2,3,4,5,6],   // Mon-Sat
  p2:  [1,2,3,4,5,6]    // Mon-Sat (Thu = active rest, still tappable)
};

function getPhaseForWeek(week) {
  if(week <= 3) return 'p1a';
  if(week <= 5) return 'p1b';
  return 'p2';
}

function getWeekDays(week) {
  const start = new Date('2026-06-01');
  start.setDate(start.getDate() + (week-1)*7);
  const days = [];
  for(let i=0;i<7;i++) {
    const d = new Date(start);
    d.setDate(d.getDate() + i);
    days.push(d);
  }
  return days;
}

function renderWorkoutGrid() {
  const grid = document.getElementById('workout-grid');
  const days = getWeekDays(currentWeek);
  const phase = getPhaseForWeek(currentWeek);
  const tdays = trainingDays[phase];
  document.getElementById('week-label').textContent = 'Week ' + currentWeek;
  grid.innerHTML = '';
  const dayNames = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
  let weekDone = 0;
  days.forEach(d => {
    const dow = d.getDay();
    const key = d.toISOString().split('T')[0];
    const isTraining = tdays.includes(dow);
    const isDone = workoutLog[key];
    if(isDone) weekDone++;
    const el = document.createElement('div');
    const hasLog = sessionLogs.find(l => l.date === key);
    el.className = 'wday' + (isDone ? ' done' : '') + (!isTraining ? ' rest-day' : '');
    el.innerHTML = `<div class="wday-name">${dayNames[dow]}</div><div class="wday-date">${d.getDate()}</div>${hasLog ? '<div class="wday-score">' + hasLog.feedback.score + '</div>' : '<div class="wday-dot"></div>'}`;
    if(isTraining) {
      el.onclick = () => { openSessionLogger(key); };
    }
    grid.appendChild(el);
  });
  document.getElementById('week-workout-count').innerHTML = weekDone + ' <span style="font-size:16px;font-family:\'DM Sans\';color:var(--text-secondary)">done</span>';
  document.getElementById('week-workout-sub').textContent = weekDone === 0 ? 'Tap a training day to mark it done' : weekDone === 1 ? '1 session logged this week' : weekDone + ' sessions logged this week';
}

function updateWorkoutStats() {
  const total = Object.values(workoutLog).filter(Boolean).length;
  document.getElementById('total-workouts').textContent = total;
  const weeksWithData = new Set(Object.keys(workoutLog).map(k => {
    const start = new Date('2026-06-01');
    const d = new Date(k);
    return Math.floor((d - start) / (7*24*60*60*1000));
  })).size;
  document.getElementById('weeks-done').textContent = weeksWithData;
  // streak
  let streak = 0;
  const today = new Date();
  for(let i=0;i<60;i++) {
    const d = new Date(today);
    d.setDate(d.getDate() - i);
    const key = d.toISOString().split('T')[0];
    if(workoutLog[key]) streak++;
    else if(i > 0) break;
  }
  document.getElementById('streak-count').textContent = streak;
  renderWorkoutGrid();
}

function changeWeek(dir) {
  currentWeek = Math.max(1, Math.min(10, currentWeek + dir));
  renderWorkoutGrid();
}

function logWeight() {
  const val = parseFloat(document.getElementById('weight-input').value);
  if(isNaN(val) || val < 40 || val > 200) return;
  const entry = { date: new Date().toLocaleDateString('en-GB',{day:'numeric',month:'short'}), weight: val, ts: Date.now() };
  weightLog.unshift(entry);
  if(weightLog.length > 20) weightLog.pop();
  localStorage.setItem('sbp-weight', JSON.stringify(weightLog));
  document.getElementById('weight-input').value = '';
  renderWeightLog();
  renderWeightChart();
}

function deleteWeight(i) {
  weightLog.splice(i, 1);
  localStorage.setItem('sbp-weight', JSON.stringify(weightLog));
  renderWeightLog();
  renderWeightChart();
}

function renderWeightLog() {
  const list = document.getElementById('weight-log');
  if(!weightLog.length) { list.innerHTML = ''; return; }
  const latest = weightLog[0].weight;
  const start = weightLog[weightLog.length-1].weight;
  const diff = latest - start;
  document.getElementById('current-weight').innerHTML = latest.toFixed(1) + ' <span style="font-size:16px;font-family:\'DM Sans\';color:var(--text-secondary)">kg</span>';
  const changeEl = document.getElementById('weight-change');
  if(weightLog.length > 1) {
    const sign = diff > 0 ? '+' : '';
    changeEl.textContent = sign + diff.toFixed(1) + 'kg since start · goal: lose 2–3kg fat';
    changeEl.style.color = diff <= 0 ? 'var(--green-700)' : 'var(--text-tertiary)';
  }
  list.innerHTML = weightLog.slice(0,5).map((e,i) => `<li class="log-item"><span class="log-date">${e.date}</span><span class="log-val">${e.weight.toFixed(1)} kg</span><button class="log-del" onclick="deleteWeight(${i})"><i class="fa-solid fa-xmark"></i></button></li>`).join('');
}

function renderWeightChart() {
  if(typeof Chart === 'undefined') return; // Chart.js still loading; re-runs on load
  const canvas = document.getElementById('weightChart');
  const noData = document.getElementById('no-data-msg');
  if(!weightLog.length) { canvas.style.display='none'; noData.style.display='block'; return; }
  canvas.style.display='block'; noData.style.display='none';
  const sorted = [...weightLog].sort((a,b) => a.ts - b.ts);
  const labels = sorted.map(e => e.date);
  const data = sorted.map(e => e.weight);
  if(weightChart) weightChart.destroy();
  weightChart = new Chart(canvas, {
    type: 'line',
    data: {
      labels,
      datasets: [{
        data,
        borderColor: '#1D9E75',
        backgroundColor: 'rgba(29,158,117,0.08)',
        borderWidth: 2,
        pointBackgroundColor: '#1D9E75',
        pointRadius: 5,
        fill: true,
        tension: 0.3
      }]
    },
    options: {
      plugins: { legend: { display: false } },
      scales: {
        y: { grid: { color: 'rgba(0,0,0,0.05)' }, ticks: { font: { family: 'DM Sans', size: 11 }, color: '#888780' } },
        x: { grid: { display: false }, ticks: { font: { family: 'DM Sans', size: 11 }, color: '#888780' } }
      },
      responsive: true,
      maintainAspectRatio: true
    }
  });
}

// ==================== SESSION LOGGER ====================

// Exercise library for each session type
const SESSION_DATA = {
  upper: {
    label: 'Upper Body',
    exercises: [
      { name: 'Bench Press',          type: 'strength', key: true,  muscle: 'Chest' },
      { name: 'Shoulder Press',       type: 'strength', key: true,  muscle: 'Shoulders' },
      { name: 'Cable Rows',           type: 'strength', key: false, muscle: 'Back' },
      { name: 'Tricep Pushdowns',     type: 'strength', key: false, muscle: 'Triceps' },
      { name: 'Bicep Curls',          type: 'strength', key: false, muscle: 'Biceps' },
      { name: 'E-gym Chest Press',    type: 'strength', key: false, muscle: 'Chest' },
      { name: 'E-gym Seated Row',     type: 'strength', key: false, muscle: 'Back' },
    ]
  },
  cardio: {
    label: 'Cardio + Core',
    exercises: [
      { name: 'HIIT Treadmill',       type: 'cardio',   key: true,  muscle: 'Full Body' },
      { name: 'Incline Walk',         type: 'cardio',   key: false, muscle: 'Full Body' },
      { name: 'Planks',               type: 'core',     key: false, muscle: 'Core' },
      { name: 'Leg Raises',           type: 'core',     key: false, muscle: 'Core' },
      { name: 'Cable Crunches',       type: 'core',     key: false, muscle: 'Core' },
    ]
  },
  lower: {
    label: 'Lower Body + Core',
    exercises: [
      { name: 'E-gym Leg Press',      type: 'strength', key: true,  muscle: 'Legs' },
      { name: 'Leg Extension',        type: 'strength', key: false, muscle: 'Quads' },
      { name: 'Leg Curl',             type: 'strength', key: false, muscle: 'Hamstrings' },
      { name: 'Barbell Squats',       type: 'strength', key: true,  muscle: 'Legs' },
      { name: 'Planks',               type: 'core',     key: false, muscle: 'Core' },
      { name: 'Leg Raises',           type: 'core',     key: false, muscle: 'Core' },
    ]
  },
  fullbody: {
    label: 'Full Body Compound',
    exercises: [
      { name: 'Deadlifts',                type: 'strength', key: true,  muscle: 'Back + Legs' },
      { name: 'Pull-ups / Lat Pulldown',  type: 'strength', key: true,  muscle: 'Back' },
      { name: 'Overhead Press',           type: 'strength', key: true,  muscle: 'Shoulders' },
      { name: 'Cable Flies',              type: 'strength', key: false, muscle: 'Chest' },
      { name: 'Farmer Carries',           type: 'strength', key: false, muscle: 'Full Body' },
    ]
  },
  push: {
    label: 'Push — Chest, Shoulders, Triceps',
    exercises: [
      { name: 'Incline Bench Press',      type: 'strength', key: true,  muscle: 'Upper Chest' },
      { name: 'Flat Bench Press',         type: 'strength', key: true,  muscle: 'Chest' },
      { name: 'E-gym Chest Press',        type: 'strength', key: false, muscle: 'Chest' },
      { name: 'Shoulder Press',           type: 'strength', key: true,  muscle: 'Shoulders' },
      { name: 'E-gym Shoulder Press',     type: 'strength', key: false, muscle: 'Shoulders' },
      { name: 'Lateral Raises',           type: 'strength', key: false, muscle: 'Side Delts' },
      { name: 'Tricep Pushdowns',         type: 'strength', key: false, muscle: 'Triceps' },
      { name: 'Cable Flies',              type: 'strength', key: false, muscle: 'Chest' },
    ]
  },
  pull: {
    label: 'Pull — Back + Biceps',
    exercises: [
      { name: 'Pull-ups / Lat Pulldown',  type: 'strength', key: true,  muscle: 'Back Width' },
      { name: 'E-gym Lat Pulldown',       type: 'strength', key: false, muscle: 'Back' },
      { name: 'Bent-Over Rows',           type: 'strength', key: true,  muscle: 'Back Thickness' },
      { name: 'E-gym Seated Row',         type: 'strength', key: false, muscle: 'Back' },
      { name: 'Face Pulls',               type: 'strength', key: false, muscle: 'Rear Delts' },
      { name: 'Bicep Curls',              type: 'strength', key: false, muscle: 'Biceps' },
      { name: 'Hammer Curls',             type: 'strength', key: false, muscle: 'Biceps' },
    ]
  },
  legs: {
    label: 'Legs + Abs',
    exercises: [
      { name: 'E-gym Leg Press',          type: 'strength', key: true,  muscle: 'Quads + Glutes' },
      { name: 'Leg Extension',            type: 'strength', key: false, muscle: 'Quads' },
      { name: 'Leg Curl',                 type: 'strength', key: false, muscle: 'Hamstrings' },
      { name: 'Squats',                   type: 'strength', key: true,  muscle: 'Legs' },
      { name: 'Romanian Deadlifts',       type: 'strength', key: true,  muscle: 'Hamstrings + Glutes' },
      { name: 'Cable Crunches',           type: 'core',     key: false, muscle: 'Core' },
      { name: 'Leg Raises',               type: 'core',     key: false, muscle: 'Core' },
      { name: 'Planks',                   type: 'core',     key: false, muscle: 'Core' },
    ]
  }
};

let sessionLogs = loadStore('sbp-session-logs', []);
let currentLogDate = null;

// Work out what session type a given date falls on
function getSessionForDate(date) {
  const planStart = new Date('2026-06-01');
  const planEnd   = new Date('2026-08-09');
  if(date < planStart || date > planEnd) return null;
  const daysDiff = Math.floor((date - planStart) / 86400000);
  const week = Math.floor(daysDiff / 7) + 1;
  const phase = week <= 3 ? '1a' : week <= 5 ? '1b' : '2';
  const dow = date.getDay();
  let sessionType;
  if(phase === '1a') {
    const m = {1:'upper',2:'cardio',3:'lower',4:'football',5:'fullbody',6:'rest',0:'rest'};
    sessionType = m[dow];
  } else if(phase === '1b') {
    const m = {1:'upper',2:'cardio',3:'lower',4:'fullbody',5:'upper',6:'cardio',0:'rest'};
    sessionType = m[dow];
  } else {
    const m = {1:'push',2:'pull',3:'legs',4:'active',5:'push',6:'pull',0:'rest'};
    sessionType = m[dow];
  }
  return { week, phase, sessionType, dateStr: date.toISOString().split('T')[0] };
}

function fmtDateFull(date) {
  return date.toLocaleDateString('en-GB', {weekday:'long', day:'numeric', month:'long'});
}

// Open the session logger modal for a given date (defaults to today)
function openSessionLogger(dateStr) {
  const date = dateStr ? new Date(dateStr + 'T12:00:00') : new Date();
  currentLogDate = date.toISOString().split('T')[0];
  const session = getSessionForDate(date);

  document.getElementById('session-modal').style.display = 'block';
  document.body.style.overflow = 'hidden';

  const body = document.getElementById('modal-body');

  // Rest day
  if(!session || session.sessionType === 'rest') {
    document.getElementById('modal-title').textContent = 'Rest Day';
    document.getElementById('modal-sub').textContent = fmtDateFull(date);
    body.innerHTML = `<div style="text-align:center;padding:48px 20px">
      <i class="fa-solid fa-moon" style="font-size:36px;color:var(--text-tertiary);margin-bottom:14px;display:block"></i>
      <div style="font-size:16px;font-weight:600;color:var(--text-primary);margin-bottom:8px">Rest day — you earned it</div>
      <div style="font-size:13px;color:var(--text-secondary);line-height:1.7">Saturday and Sunday are full rest days.<br>Sleep well, eat your protein, and come back stronger.</div>
    </div>`;
    return;
  }

  // Football
  if(session.sessionType === 'football') {
    document.getElementById('modal-title').textContent = 'Football Training';
    document.getElementById('modal-sub').textContent = fmtDateFull(date) + ' · Phase 1a · Week ' + session.week;
    body.innerHTML = `<div style="text-align:center;padding:40px 20px">
      <i class="fa-solid fa-futbol" style="font-size:36px;color:var(--amber-500);margin-bottom:14px;display:block"></i>
      <div style="font-size:16px;font-weight:600;color:var(--text-primary);margin-bottom:8px">Football counts as cardio today</div>
      <div style="font-size:13px;color:var(--text-secondary);line-height:1.7;margin-bottom:24px">No gym needed. Play well, recover well, and hit your 160g protein today.</div>
      <button class="btn-primary-modal" style="max-width:200px;margin:0 auto;display:block" onclick="markDayDone('${currentLogDate}');closeSessionModal()">Mark as done</button>
    </div>`;
    return;
  }

  // Active rest (Phase 2 Thursday)
  if(session.sessionType === 'active') {
    document.getElementById('modal-title').textContent = 'Active Rest';
    document.getElementById('modal-sub').textContent = fmtDateFull(date) + ' · Phase 2 · Week ' + session.week;
    body.innerHTML = `<div style="text-align:center;padding:40px 20px">
      <i class="fa-solid fa-person-swimming" style="font-size:36px;color:var(--blue-500);margin-bottom:14px;display:block"></i>
      <div style="font-size:16px;font-weight:600;color:var(--text-primary);margin-bottom:8px">Easy swim, walk or stretch</div>
      <div style="font-size:13px;color:var(--text-secondary);line-height:1.7;margin-bottom:24px">20-minute easy swim at Everybody Gym Knutsford, a walk, or light mobility at home. Don't push it — tomorrow is Push day.</div>
      <button class="btn-primary-modal" style="max-width:200px;margin:0 auto;display:block" onclick="markDayDone('${currentLogDate}');closeSessionModal()">Mark as done</button>
    </div>`;
    return;
  }

  // Gym session
  const sessionData = SESSION_DATA[session.sessionType];
  if(!sessionData) return;

  document.getElementById('modal-title').textContent = sessionData.label;
  document.getElementById('modal-sub').textContent = fmtDateFull(date) + ' · Phase ' + session.phase + ' · Week ' + session.week;

  const existingLog = sessionLogs.find(l => l.date === currentLogDate);
  body.innerHTML = buildLoggerHTML(session, existingLog);

  // Attach toggle click handlers to all exercise rows
  body.querySelectorAll('.ex-toggle').forEach(t => attachExToggle(t));

  if(existingLog) restoreLogValues(existingLog);
}

function attachExToggle(toggle) {
  toggle.addEventListener('click', function() {
    const row = this.closest('.ex-row');
    const inputs = row.querySelector('.ex-inputs');
    const check = row.querySelector('.ex-check');
    row.classList.toggle('checked');
    const on = row.classList.contains('checked');
    check.innerHTML = on ? '<i class="fa-solid fa-check" style="font-size:11px;color:white"></i>' : '';
    inputs.style.display = on ? 'grid' : 'none';
  });
}

function buildExRow(ex, isExtra) {
  let inputsHTML;
  if(ex.type === 'cardio') {
    inputsHTML = `<div class="ex-inputs two-col" style="display:none">
      <div class="ex-input-group"><label>Duration (min)</label><input type="number" class="ex-input-num" data-field="sets" placeholder="25" min="1" max="180"></div>
      <div class="ex-input-group"><label>Intensity</label><input type="text" class="ex-input-num" data-field="reps" placeholder="High / Med"></div>
    </div>`;
  } else if(ex.type === 'core') {
    inputsHTML = `<div class="ex-inputs two-col" style="display:none">
      <div class="ex-input-group"><label>Sets</label><input type="number" class="ex-input-num" data-field="sets" placeholder="3" min="1" max="10"></div>
      <div class="ex-input-group"><label>Reps / secs</label><input type="number" class="ex-input-num" data-field="reps" placeholder="30" min="1" max="300"></div>
    </div>`;
  } else {
    inputsHTML = `<div class="ex-inputs" style="display:none">
      <div class="ex-input-group"><label>Sets</label><input type="number" class="ex-input-num" data-field="sets" placeholder="3" min="1" max="10"></div>
      <div class="ex-input-group"><label>Reps</label><input type="number" class="ex-input-num" data-field="reps" placeholder="10" min="1" max="50"></div>
      <div class="ex-input-group"><label>Weight (kg)</label><input type="number" class="ex-input-num" data-field="weight" placeholder="0" min="0" max="300" step="2.5"></div>
    </div>`;
  }
  const badge = (ex.key && !isExtra) ? '<span class="ex-key-badge">Key lift</span>' : '';
  return `<div class="ex-row" data-name="${esc(ex.name)}" data-type="${esc(ex.type)}" data-key="${ex.key?'1':'0'}" data-planned="${isExtra?'0':'1'}">
    <div class="ex-toggle">
      <div class="ex-check"></div>
      <div class="ex-info"><span class="ex-name">${esc(ex.name)}</span><span class="ex-muscle">${esc(ex.muscle)}</span></div>
      ${badge}
    </div>
    ${inputsHTML}
  </div>`;
}

function buildLoggerHTML(session, existingLog) {
  const sd = SESSION_DATA[session.sessionType];
  const strength = sd.exercises.filter(e => e.type === 'strength');
  const cardio   = sd.exercises.filter(e => e.type === 'cardio');
  const core     = sd.exercises.filter(e => e.type === 'core');

  let html = '';
  if(strength.length) {
    html += '<div class="ex-section-label">Strength exercises</div>';
    strength.forEach(e => html += buildExRow(e, false));
  }
  if(cardio.length) {
    html += '<div class="ex-section-label">Cardio</div>';
    cardio.forEach(e => html += buildExRow(e, false));
  }
  if(core.length) {
    html += '<div class="ex-section-label">Core</div>';
    core.forEach(e => html += buildExRow(e, false));
  }

  html += `<div class="ex-section-label">Add an extra exercise</div>
  <div class="add-ex-row">
    <input type="text" class="add-ex-input" id="extra-ex-input" placeholder="e.g. Incline dumbbell press" />
    <button class="add-ex-btn" onclick="addExtraExercise()"><i class="fa-solid fa-plus"></i> Add</button>
  </div>
  <div id="extra-exercises"></div>`;

  html += `<div class="modal-actions">
    <button class="btn-feedback-modal" onclick="runFeedback('${session.sessionType}','${session.phase}')"><i class="fa-solid fa-chart-bar"></i> Get feedback</button>
    <button class="btn-primary-modal" onclick="saveSession('${session.sessionType}','${session.phase}',${session.week})">Save session</button>
  </div>
  <div id="feedback-area"></div>`;

  return html;
}

function addExtraExercise() {
  const input = document.getElementById('extra-ex-input');
  const name = input.value.trim();
  if(!name) return;
  const container = document.getElementById('extra-exercises');
  container.insertAdjacentHTML('beforeend', buildExRow({name, type:'strength', key:false, muscle:'Custom'}, true));
  attachExToggle(container.lastElementChild.querySelector('.ex-toggle'));
  input.value = '';
}

function collectExercises() {
  const exercises = [];
  document.querySelectorAll('.ex-row').forEach(row => {
    const name    = row.dataset.name;
    const type    = row.dataset.type;
    const key     = row.dataset.key === '1';
    const planned = row.dataset.planned === '1';
    const done    = row.classList.contains('checked');
    let sets=0, reps=0, weight=0, duration=0, intensity='';
    if(done) {
      const sF = row.querySelector('[data-field="sets"]');
      const rF = row.querySelector('[data-field="reps"]');
      const wF = row.querySelector('[data-field="weight"]');
      if(type === 'cardio') {
        duration  = parseFloat(sF?.value) || 0;
        intensity = rF?.value || '';
      } else {
        sets   = parseInt(sF?.value) || 0;
        reps   = parseInt(rF?.value) || 0;
        weight = parseFloat(wF?.value) || 0;
      }
    }
    exercises.push({name, type, key, planned, done, sets, reps, weight, duration, intensity});
  });
  return exercises;
}

function runFeedback(sessionType, phase) {
  const exercises = collectExercises();
  const feedback = generateFeedback(sessionType, phase, exercises);
  renderFeedback(feedback, exercises, sessionType);
  setTimeout(() => {
    const fb = document.getElementById('feedback-area');
    if(fb) fb.scrollIntoView({behavior:'smooth', block:'start'});
  }, 100);
}

function generateFeedback(sessionType, phase, exercises) {
  const sd = SESSION_DATA[sessionType];
  const good = [], improve = [], tips = [];
  let score = 100;

  const doneAny = exercises.some(e => e.done);
  if(!doneAny) return {score:0, summary:'Nothing logged yet', good:[], improve:['Tap at least one exercise to mark it done, then get your feedback.'], tips:[]};

  // Check each planned exercise
  sd.exercises.forEach(p => {
    const logged = exercises.find(e => e.name === p.name && e.done);
    if(!logged) {
      if(p.key) { score -= 15; improve.push(`Skipped ${p.name} — this is a key compound lift for ${p.muscle.toLowerCase()}. It should be in every ${sd.label.split('—')[0].trim()} session.`); }
      else       { score -= 7;  improve.push(`Skipped ${p.name} — worth including for ${p.muscle.toLowerCase()} development.`); }
    } else {
      if(p.type === 'strength') {
        if(logged.sets >= 3 && logged.reps >= 8) {
          good.push(`${p.name}: ${logged.sets}×${logged.reps}${logged.weight > 0 ? ' @ ' + logged.weight + 'kg' : ''} — solid volume.${p.key ? ' Key compound hit.' : ''}`);
        } else if(logged.sets < 2) {
          score -= 8; improve.push(`${p.name}: only ${logged.sets} set — aim for 3–4 sets to properly stimulate the muscle.`);
        } else if(logged.reps < 6 && logged.reps > 0) {
          score -= 5; improve.push(`${p.name}: ${logged.reps} reps is quite low — the 8–12 rep range builds the most muscle for your goals.`);
        } else {
          good.push(`${p.name}: ${logged.sets}×${logged.reps}${logged.weight > 0 ? ' @ ' + logged.weight + 'kg' : ''} — done.`);
        }
      } else if(p.type === 'cardio') {
        if(logged.duration >= 20) { good.push(`${p.name}: ${logged.duration} min — great cardio for fat loss.`); }
        else if(logged.duration > 0) { score -= 5; improve.push(`${p.name}: ${logged.duration} min — aim for at least 20 minutes to maximise the fat-burn effect.`); }
        else { good.push(`${p.name} completed — great fat-burning session.`); }
      } else if(p.type === 'core') {
        good.push(`${p.name} done — core consistency adds up week by week.`);
      }
    }
  });

  // Progressive overload check (vs previous sessions of same type)
  const prevSessions = sessionLogs
    .filter(l => l.sessionType === sessionType && l.date < currentLogDate)
    .sort((a, b) => a.date < b.date ? -1 : 1);
  if(prevSessions.length > 0) {
    const last = prevSessions[prevSessions.length - 1]; // most recent session before this one
    let progressFound = false;
    exercises.filter(e => e.done && e.type === 'strength' && e.weight > 0).forEach(ex => {
      const prev = last.exercises.find(pe => pe.name === ex.name && pe.done && pe.weight > 0);
      if(prev) {
        if(ex.weight > prev.weight) {
          progressFound = true;
          good.push(`Progressive overload on ${ex.name}: up to ${ex.weight}kg from ${prev.weight}kg last time — this is exactly how muscle is built.`);
        } else if(ex.weight < prev.weight) {
          improve.push(`${ex.name}: dropped to ${ex.weight}kg from ${prev.weight}kg last session — try to hold or increase weight each week.`);
        }
      }
    });
    if(!progressFound && exercises.filter(e => e.done && e.type === 'strength' && e.weight > 0).length > 0 && prevSessions.length > 0) {
      tips.push('Try to increase weight on at least one lift next session — even 1.25–2.5kg counts as progressive overload.');
    }
  }

  // Extra exercises bonus
  const extras = exercises.filter(e => e.done && !e.planned);
  if(extras.length > 0) {
    score = Math.min(100, score + extras.length * 3);
    good.push(`Added ${extras.length} extra exercise${extras.length > 1 ? 's' : ''} outside the plan — great effort.`);
  }

  // Phase-specific tips
  if(phase === '1a' || phase === '1b') {
    if(sessionType !== 'cardio') tips.push('Phase 1: keep rest periods to 60–90 seconds — shorter rest keeps your heart rate elevated and burns more calories.');
    tips.push('Hit your 160g protein target today — it protects your muscle while you\'re in a calorie deficit.');
    if(sessionType === 'cardio') tips.push('HIIT is more effective than steady-state cardio for fat loss. Push hard on the "on" intervals — 30 seconds all-out.');
  } else {
    tips.push('Phase 2: aim to add weight or reps to at least one exercise each session — progressive overload is what forces your muscles to grow.');
    tips.push('Make sure you\'re eating 2,700 calories today. You can\'t build muscle in a sustained deficit.');
    if(sessionType === 'push') tips.push('Incline bench is the most important push exercise for upper chest definition. Always do it first when you\'re freshest.');
    else if(sessionType === 'pull') tips.push('Pull-ups / lat pulldown + bent-over rows together build a wide, thick back. Don\'t skip either.');
    else if(sessionType === 'legs') tips.push('Don\'t skip legs — more muscle mass means higher resting metabolism, which burns more fat even on rest days.');
  }

  score = Math.max(0, Math.min(100, score));

  let summary;
  if(score >= 90) summary = 'Excellent session — you nailed it';
  else if(score >= 75) summary = 'Good session — a few things to tighten up';
  else if(score >= 55) summary = 'Decent session — some key exercises missed';
  else summary = 'Incomplete session — room to improve';

  return {score, summary, good, improve, tips};
}

function renderFeedback(feedback, exercises, sessionType) {
  const area = document.getElementById('feedback-area');
  const scoreClass = feedback.score >= 85 ? 'score-great' : feedback.score >= 60 ? 'score-good' : 'score-ok';
  const plannedCount = exercises.filter(e => e.planned).length;
  const doneCount    = exercises.filter(e => e.done && e.planned).length;

  let html = `<div class="divider"></div>
  <div class="feedback-panel">
    <div class="fb-score-row">
      <div class="score-circle ${scoreClass}">
        <span class="score-num">${feedback.score}</span>
        <span class="score-label">/ 100</span>
      </div>
      <div>
        <div class="score-summary">${feedback.summary}</div>
        <div class="score-sub">${doneCount} of ${plannedCount} planned exercises completed</div>
      </div>
    </div>`;

  if(feedback.good.length) html += `<div class="fb-section">
    <div class="fb-section-title" style="color:var(--green-700)"><i class="fa-solid fa-circle-check"></i> What went well</div>
    ${feedback.good.map(g => `<div class="fb-item fb-good">${g}</div>`).join('')}
  </div>`;

  if(feedback.improve.length) html += `<div class="fb-section">
    <div class="fb-section-title" style="color:var(--amber-500)"><i class="fa-solid fa-triangle-exclamation"></i> What to improve</div>
    ${feedback.improve.map(i => `<div class="fb-item fb-improve">${i}</div>`).join('')}
  </div>`;

  if(feedback.tips.length) html += `<div class="fb-section">
    <div class="fb-section-title" style="color:var(--blue-700)"><i class="fa-solid fa-lightbulb"></i> Tips for next session</div>
    ${feedback.tips.map(t => `<div class="fb-item fb-tip">${t}</div>`).join('')}
  </div>`;

  html += '</div>';
  area.innerHTML = html;
}

function saveSession(sessionType, phase, week) {
  const exercises = collectExercises();
  const feedback = generateFeedback(sessionType, phase, exercises);

  sessionLogs = sessionLogs.filter(l => l.date !== currentLogDate);
  sessionLogs.push({date: currentLogDate, sessionType, phase, week, exercises, feedback:{score:feedback.score, summary:feedback.summary}, ts: Date.now()});
  localStorage.setItem('sbp-session-logs', JSON.stringify(sessionLogs));

  markDayDone(currentLogDate);
  closeSessionModal();
  renderSessionHistory();
}

function markDayDone(dateStr) {
  workoutLog[dateStr] = true;
  localStorage.setItem('sbp-workouts', JSON.stringify(workoutLog));
  updateWorkoutStats();
}

function closeSessionModal() {
  document.getElementById('session-modal').style.display = 'none';
  document.body.style.overflow = '';
  currentLogDate = null;
}

function restoreLogValues(log) {
  log.exercises.forEach(ex => {
    // Find the matching row by name (safe — no selector string injection)
    let row = Array.from(document.querySelectorAll('.ex-row')).find(r => r.dataset.name === ex.name);
    // Rebuild any custom (unplanned) exercise that isn't in the default list
    if(!row && ex.planned === false) {
      const container = document.getElementById('extra-exercises');
      if(container) {
        container.insertAdjacentHTML('beforeend', buildExRow({name: ex.name, type: ex.type || 'strength', key: false, muscle: 'Custom'}, true));
        row = container.lastElementChild;
        attachExToggle(row.querySelector('.ex-toggle'));
      }
    }
    if(!row) return;
    if(!ex.done) return;
    row.classList.add('checked');
    row.querySelector('.ex-check').innerHTML = '<i class="fa-solid fa-check" style="font-size:11px;color:white"></i>';
    const inputs = row.querySelector('.ex-inputs');
    inputs.style.display = 'grid';
    if(ex.type === 'cardio') {
      const sF = row.querySelector('[data-field="sets"]'); if(sF) sF.value = ex.duration || '';
      const rF = row.querySelector('[data-field="reps"]'); if(rF) rF.value = ex.intensity || '';
    } else {
      const sF = row.querySelector('[data-field="sets"]');   if(sF) sF.value = ex.sets || '';
      const rF = row.querySelector('[data-field="reps"]');   if(rF) rF.value = ex.reps || '';
      const wF = row.querySelector('[data-field="weight"]'); if(wF) wF.value = ex.weight || '';
    }
  });
}

function renderSessionHistory() {
  const card = document.getElementById('session-history-card');
  const list = document.getElementById('session-history-list');
  if(!sessionLogs.length) { card.style.display = 'none'; return; }
  card.style.display = 'block';
  const sorted = [...sessionLogs].sort((a,b) => b.ts - a.ts).slice(0, 6);
  list.innerHTML = sorted.map(log => {
    const date = new Date(log.date + 'T12:00:00');
    const dateStr = date.toLocaleDateString('en-GB', {weekday:'short', day:'numeric', month:'short'});
    const sd = SESSION_DATA[log.sessionType];
    const label = sd ? sd.label : log.sessionType;
    const scoreColor = log.feedback.score >= 85 ? 'var(--green-700)' : log.feedback.score >= 60 ? 'var(--amber-500)' : 'var(--text-tertiary)';
    const doneExs = log.exercises.filter(e => e.done);
    const exNames = doneExs.slice(0,3).map(e => e.name).join(', ') + (doneExs.length > 3 ? ` +${doneExs.length-3} more` : '');
    return `<div class="session-hist-item" onclick="openSessionLogger('${log.date}')">
      <div class="sh-top">
        <div><div class="sh-type">${label}</div><div class="sh-meta">${dateStr} · Week ${log.week} · Phase ${log.phase}</div></div>
        <div class="sh-score" style="color:${scoreColor}">${log.feedback.score}/100</div>
      </div>
      <div class="sh-exs">${exNames || 'No exercises logged'}</div>
    </div>`;
  }).join('');
}

// Make the session card's green glow follow the cursor. We update CSS custom
// properties (cheap, no layout) on pointer move; CSS draws the radial glow there.
function initSessionCardGlow() {
  const btn = document.getElementById('log-session-btn');
  if(!btn || btn.dataset.glow) return;
  btn.dataset.glow = '1';
  btn.addEventListener('pointermove', (e) => {
    const r = btn.getBoundingClientRect();
    btn.style.setProperty('--mx', (e.clientX - r.left) + 'px');
    btn.style.setProperty('--my', (e.clientY - r.top) + 'px');
  });
  // Ease the glow back to centre when the cursor leaves, so the next hover
  // doesn't snap from a stale corner position.
  btn.addEventListener('pointerleave', () => {
    btn.style.setProperty('--mx', '50%');
    btn.style.setProperty('--my', '50%');
  });
}

function updateLogSessionButton() {
  const today = new Date();
  const session = getSessionForDate(today);
  const titleEl = document.getElementById('log-btn-title');
  const subEl   = document.getElementById('log-btn-sub');
  if(!titleEl) return;

  const todayStr = today.toISOString().split('T')[0];
  const hasLog = sessionLogs.find(l => l.date === todayStr);

  if(!session || session.sessionType === 'rest') {
    titleEl.textContent = 'Rest day today';
    subEl.textContent = 'No gym — rest and recover';
  } else if(session.sessionType === 'football') {
    titleEl.textContent = 'Football training today';
    subEl.textContent = 'Phase 1a · Week ' + session.week + ' · Counts as cardio';
  } else if(session.sessionType === 'active') {
    titleEl.textContent = 'Active rest today';
    subEl.textContent = 'Phase 2 · Week ' + session.week + ' · Easy swim or walk';
  } else {
    const sd = SESSION_DATA[session.sessionType];
    titleEl.textContent = hasLog ? 'View today\'s session' : 'Log today\'s session';
    subEl.textContent = (sd ? sd.label : session.sessionType) + ' · Phase ' + session.phase + ' · Week ' + session.week + (hasLog ? ' · Score: ' + hasLog.feedback.score + '/100' : '');
  }
}

// ==================== TODAY — INTAKE TRACKER ====================
// Offline food database. Macros are per typical portion unless `per100` (per 100g)
// or `each` (per single unit) is given. `portion` = default grams when no quantity typed.
const FOOD_DB = [
  // Proteins
  { keys:['chicken breast','grilled chicken','chicken'], per100:{kcal:165,p:31,c:0,f:3.6}, portion:150 },
  { keys:['turkey'], per100:{kcal:135,p:29,c:0,f:1.7}, portion:150 },
  { keys:['sirloin','rump','steak','beef'], per100:{kcal:215,p:26,c:0,f:12}, portion:200 },
  { keys:['salmon'], per100:{kcal:208,p:20,c:0,f:13}, portion:180 },
  { keys:['tuna'], per100:{kcal:116,p:26,c:0,f:1}, portion:120 },
  { keys:['cod','white fish'], per100:{kcal:82,p:18,c:0,f:0.7}, portion:180 },
  { keys:['mince','beef mince'], per100:{kcal:215,p:26,c:0,f:12}, portion:150 },
  { keys:['bacon'], each:{kcal:65,p:5,c:0,f:5}, defaultCount:2, unitWord:'rasher' },
  { keys:['sausage','sausages'], each:{kcal:130,p:7,c:3,f:10}, defaultCount:2 },
  { keys:['egg','eggs','boiled egg','fried egg'], each:{kcal:78,p:6,c:0.6,f:5}, defaultCount:2 },
  { keys:['prawns','prawn'], per100:{kcal:99,p:24,c:0,f:0.3}, portion:120 },
  // Dairy / protein supps
  { keys:['whey','protein shake','protein powder','scoop of whey','whey protein'], each:{kcal:120,p:24,c:3,f:2}, defaultCount:1, unitWord:'scoop' },
  { keys:['greek yogurt','greek yoghurt'], per100:{kcal:59,p:10,c:3.6,f:0.4}, portion:150 },
  { keys:['cottage cheese'], per100:{kcal:98,p:11,c:3.4,f:4.3}, portion:150 },
  { keys:['cheddar','cheese'], per100:{kcal:402,p:25,c:1.3,f:33}, portion:30 },
  { keys:['milk','semi-skimmed milk','semi skimmed milk'], per100:{kcal:50,p:3.4,c:4.8,f:1.8}, portion:200, unitWord:'ml' },
  // Carbs
  { keys:['white rice','rice'], per100:{kcal:130,p:2.7,c:28,f:0.3}, portion:180 },
  { keys:['pasta','penne','spaghetti'], per100:{kcal:158,p:6,c:31,f:1}, portion:180 },
  { keys:['new potatoes','boiled potatoes','potato','potatoes'], per100:{kcal:77,p:2,c:17,f:0.1}, portion:200 },
  { keys:['sweet potato','sweet potatoes'], per100:{kcal:86,p:1.6,c:20,f:0.1}, portion:200 },
  { keys:['chips','fries','sweet potato fries','oven chips'], per100:{kcal:312,p:3.4,c:41,f:15}, portion:150 },
  { keys:['mashed potato','mash'], per100:{kcal:108,p:2,c:16,f:4}, portion:200 },
  { keys:['wrap','wraps','tortilla','tortillas','wholemeal wrap'], each:{kcal:150,p:5,c:26,f:3}, defaultCount:1 },
  { keys:['bread','toast','slice of bread'], each:{kcal:80,p:3,c:15,f:1}, defaultCount:1, unitWord:'slice' },
  { keys:['bagel'], each:{kcal:250,p:9,c:48,f:2}, defaultCount:1 },
  { keys:['oats','porridge'], per100:{kcal:379,p:13,c:67,f:7}, portion:60 },
  { keys:['weetabix'], each:{kcal:67,p:2.3,c:13,f:0.7}, defaultCount:3, unitWord:'biscuit' },
  { keys:['rice cakes','rice cake'], each:{kcal:35,p:0.7,c:7,f:0.3}, defaultCount:2 },
  { keys:['couscous'], per100:{kcal:112,p:3.8,c:23,f:0.2}, portion:150 },
  { keys:['noodles'], per100:{kcal:138,p:5,c:25,f:2}, portion:180 },
  // Veg / fruit
  { keys:['banana'], each:{kcal:105,p:1.3,c:27,f:0.4}, defaultCount:1 },
  { keys:['apple'], each:{kcal:78,p:0.4,c:21,f:0.2}, defaultCount:1 },
  { keys:['orange'], each:{kcal:62,p:1.2,c:15,f:0.2}, defaultCount:1 },
  { keys:['pear'], each:{kcal:101,p:0.6,c:27,f:0.2}, defaultCount:1 },
  { keys:['blueberries','berries','raspberries','strawberries'], per100:{kcal:57,p:0.7,c:14,f:0.3}, portion:80 },
  { keys:['peas'], per100:{kcal:81,p:5,c:14,f:0.4}, portion:80 },
  { keys:['sweetcorn','corn'], per100:{kcal:86,p:3.2,c:19,f:1.2}, portion:80 },
  { keys:['carrots','carrot'], per100:{kcal:41,p:0.9,c:10,f:0.2}, portion:80 },
  { keys:['broccoli'], per100:{kcal:34,p:2.8,c:7,f:0.4}, portion:80 },
  { keys:['peppers','pepper'], per100:{kcal:31,p:1,c:6,f:0.3}, portion:80 },
  { keys:['salad','lettuce','spinach','cucumber'], per100:{kcal:18,p:1.2,c:3,f:0.2}, portion:60 },
  { keys:['onion','red onion'], per100:{kcal:40,p:1.1,c:9,f:0.1}, portion:50 },
  { keys:['avocado'], each:{kcal:240,p:3,c:12,f:22}, defaultCount:1 },
  // Fats / extras / sauces
  { keys:['peanut butter'], each:{kcal:90,p:4,c:3,f:8}, defaultCount:1, unitWord:'tbsp' },
  { keys:['mixed nuts','nuts','almonds'], per100:{kcal:607,p:21,c:21,f:54}, portion:25 },
  { keys:['olive oil','oil'], each:{kcal:120,p:0,c:0,f:14}, defaultCount:1, unitWord:'tbsp' },
  { keys:['butter'], each:{kcal:74,p:0.1,c:0,f:8}, defaultCount:1, unitWord:'tsp' },
  { keys:['mayo','mayonnaise','light mayo'], each:{kcal:90,p:0.1,c:0.5,f:10}, defaultCount:1, unitWord:'tbsp' },
  { keys:['honey'], each:{kcal:64,p:0,c:17,f:0}, defaultCount:1, unitWord:'tbsp' },
  { keys:['peri peri sauce','peri peri','hot sauce','chilli sauce'], each:{kcal:15,p:0.3,c:3,f:0.2}, defaultCount:1, unitWord:'serving' },
  { keys:['ketchup','tomato sauce'], each:{kcal:20,p:0.2,c:5,f:0}, defaultCount:1, unitWord:'tbsp' },
  { keys:['bbq sauce','barbecue sauce'], each:{kcal:29,p:0.2,c:7,f:0.1}, defaultCount:1, unitWord:'tbsp' },
  { keys:['salsa'], each:{kcal:10,p:0.5,c:2,f:0.1}, defaultCount:1, unitWord:'tbsp' },
  { keys:['passata','tomato'], per100:{kcal:35,p:1.6,c:6,f:0.2}, portion:100 },
  { keys:['gravy'], each:{kcal:35,p:0.5,c:5,f:1.5}, defaultCount:1, unitWord:'serving' },
  // Takeaways / treats (still log under Junk too, but these count toward calories if typed here)
  { keys:['pizza'], each:{kcal:285,p:12,c:36,f:10}, defaultCount:2, unitWord:'slice' },
  { keys:['burger','cheeseburger'], each:{kcal:500,p:25,c:40,f:27}, defaultCount:1 },
  { keys:['kebab','doner'], each:{kcal:700,p:35,c:55,f:38}, defaultCount:1 },
  { keys:['chocolate','chocolate bar'], each:{kcal:230,p:3,c:25,f:13}, defaultCount:1, unitWord:'bar' },
  { keys:['biscoff','biscuit','biscuits','cookie'], each:{kcal:55,p:0.6,c:7,f:2.8}, defaultCount:2 },
  { keys:['crisps','chips packet'], each:{kcal:130,p:1.5,c:13,f:8}, defaultCount:1, unitWord:'packet' },
  { keys:['ice cream'], per100:{kcal:207,p:3.5,c:24,f:11}, portion:100 },
  { keys:['doughnut','donut'], each:{kcal:250,p:4,c:30,f:12}, defaultCount:1 },
  { keys:['chocolate bar','mars','snickers','kitkat'], each:{kcal:230,p:3,c:28,f:11}, defaultCount:1 },
  { keys:['beer','lager','pint'], each:{kcal:180,p:1.6,c:13,f:0}, defaultCount:1, unitWord:'pint' },
  { keys:['wine','glass of wine'], each:{kcal:160,p:0.1,c:4,f:0}, defaultCount:1, unitWord:'glass' },
  { keys:['coke','cola','soft drink','lemonade','fizzy drink'], each:{kcal:139,p:0,c:35,f:0}, defaultCount:1, unitWord:'can' },
  { keys:['chips and cheese'], each:{kcal:600,p:15,c:60,f:32}, defaultCount:1 },
];

// Quick-add buttons (label -> food string fed through the same parser)
const QUICK_ADDS = [
  { label:'Whey scoop', q:'1 scoop whey' },
  { label:'Protein shake', q:'1 scoop whey' },
  { label:'Banana', q:'1 banana' },
  { label:'2 eggs', q:'2 eggs' },
  { label:'Chicken 150g', q:'150g chicken' },
  { label:'Greek yogurt', q:'150g greek yogurt' },
  { label:'Handful nuts', q:'25g nuts' },
];

// Meal-plan shortcuts — representative meals from the plan with known macros
const MEAL_PLAN_ADDS = [
  { name:'Overnight weetabix', kcal:440, p:46, c:54, f:8 },
  { name:'Chicken honey wrap', kcal:490, p:52, c:48, f:10 },
  { name:'Pre-workout shake + banana', kcal:190, p:22, c:28, f:2 },
  { name:'Chicken fajitas', kcal:790, p:54, c:78, f:18 },
  { name:'Salmon + new potatoes', kcal:810, p:46, c:62, f:28 },
  { name:'Steak + sweet potato chips', kcal:800, p:52, c:64, f:22 },
];

const NUM_WORDS = { one:1, two:2, three:3, four:4, five:5, six:6, half:0.5, a:1, an:1 };

let todayData = loadStore('sbp-today', {});
let todayChart = null;
let pendingParse = null;

function todayKey() { return new Date().toISOString().split('T')[0]; }

function getDay(key) {
  key = key || todayKey();
  if(!todayData[key]) todayData[key] = { meals:[], water:0, creatine:false, junk:[] };
  const d = todayData[key];
  if(!Array.isArray(d.meals)) d.meals = [];
  if(!Array.isArray(d.junk)) d.junk = [];
  if(typeof d.water !== 'number') d.water = 0;
  if(typeof d.creatine !== 'boolean') d.creatine = false;
  return d;
}
function saveToday() { localStorage.setItem('sbp-today', JSON.stringify(todayData)); }

// Phase-aware targets
function todayTargets() {
  const s = getSessionForDate(new Date());
  const isPhase2 = s && s.phase === '2';
  return isPhase2 ? { kcal:2700, protein:170 } : { kcal:2100, protein:160 };
}

// ---- Free-text food parser ----
function round(n) { return Math.round(n); }

function findFood(text) {
  let best = null, bestLen = 0;
  for(const f of FOOD_DB) {
    for(const k of f.keys) {
      if(text.includes(k) && k.length > bestLen) { best = f; bestLen = k.length; }
    }
  }
  return best;
}

function parseSegment(seg) {
  seg = seg.trim().toLowerCase().replace(/\b(of|some|a bit of|with|plus|and)\b/g,' ').replace(/\s+/g,' ').trim();
  if(!seg) return null;
  // quantity: number (incl decimals), or number word
  let qty = null, grams = null;
  const gMatch = seg.match(/(\d+(?:\.\d+)?)\s*(g|grams|gram|ml)\b/);
  if(gMatch) { grams = parseFloat(gMatch[1]); }
  else {
    const nMatch = seg.match(/(?:^|\s)(\d+(?:\.\d+)?)\b/);
    if(nMatch) qty = parseFloat(nMatch[1]);
    else { for(const w in NUM_WORDS){ if(new RegExp('\\b'+w+'\\b').test(seg)){ qty = NUM_WORDS[w]; break; } } }
  }
  const food = findFood(seg);
  if(!food) return { name: seg, unknown:true, kcal:0, p:0, c:0, f:0 };
  let kcal, p, c, f, label;
  const niceName = food.keys[0];
  if(food.per100) {
    const g = grams != null ? grams : (qty != null ? food.portion * qty : food.portion);
    const m = g / 100;
    kcal = food.per100.kcal*m; p = food.per100.p*m; c = food.per100.c*m; f = food.per100.f*m;
    label = round(g) + 'g ' + niceName;
  } else { // each
    const count = grams != null ? Math.max(1, Math.round(grams/100)) : (qty != null ? qty : food.defaultCount);
    kcal = food.each.kcal*count; p = food.each.p*count; c = food.each.c*count; f = food.each.f*count;
    const unit = food.unitWord ? ' ' + food.unitWord + (count!==1?'s':'') : '';
    let dispName = niceName;
    if(!food.unitWord && count !== 1 && !/s$/.test(niceName)) dispName = niceName + 's';
    label = count + (unit ? unit + ' ' + niceName : ' ' + dispName);
  }
  return { name: label, unknown:false, kcal:round(kcal), p:round(p), c:round(c), f:round(f) };
}

function parseMealText(text) {
  const segs = text.toLowerCase().split(/,|&|\band\b|\bwith\b|\bplus\b|\+/).map(s=>s.trim()).filter(Boolean);
  const items = segs.map(parseSegment).filter(Boolean);
  const known = items.filter(i=>!i.unknown);
  const totals = known.reduce((a,i)=>({kcal:a.kcal+i.kcal,p:a.p+i.p,c:a.c+i.c,f:a.f+i.f}),{kcal:0,p:0,c:0,f:0});
  return { items, totals };
}

function parseFood() {
  const input = document.getElementById('food-input');
  const text = input.value.trim();
  if(!text) return;
  const res = parseMealText(text);
  pendingParse = { text, ...res };
  renderParsePreview();
}

function renderParsePreview() {
  const box = document.getElementById('parse-preview');
  if(!pendingParse) { box.innerHTML=''; return; }
  const { items, totals } = pendingParse;
  const lines = items.map(i => i.unknown
    ? `<span class="pp-item-unknown">• ${esc(i.name)} — not recognised</span>`
    : `• ${esc(i.name)} — ${i.kcal} kcal (P${i.p} C${i.c} F${i.f})`).join('<br>');
  box.innerHTML = `<div class="parse-preview">
    <div class="pp-head"><span style="font-size:13px;font-weight:600;color:var(--green-900)">Estimated</span><span class="pp-cal">${totals.kcal} kcal</span></div>
    <div class="pp-items">${lines}</div>
    <div class="pp-actions">
      <button class="pp-confirm" onclick="confirmFood()">Add to today</button>
      <button class="pp-cancel" onclick="cancelFood()">Cancel</button>
    </div></div>`;
}

function confirmFood() {
  if(!pendingParse) return;
  const { text, totals } = pendingParse;
  const day = getDay();
  day.meals.push({ name: text, kcal:totals.kcal, p:totals.p, c:totals.c, f:totals.f, ts:Date.now() });
  saveToday();
  pendingParse = null;
  document.getElementById('food-input').value = '';
  renderParsePreview();
  renderToday();
}
function cancelFood() { pendingParse = null; renderParsePreview(); }

function quickAdd(q, label) {
  const res = parseMealText(q);
  const day = getDay();
  day.meals.push({ name: label, kcal:res.totals.kcal, p:res.totals.p, c:res.totals.c, f:res.totals.f, ts:Date.now() });
  saveToday();
  renderToday();
}
function mealPlanAdd(idx) {
  const m = MEAL_PLAN_ADDS[idx];
  const day = getDay();
  day.meals.push({ name:m.name, kcal:m.kcal, p:m.p, c:m.c, f:m.f, ts:Date.now() });
  saveToday();
  renderToday();
}
function removeMeal(ts) {
  const day = getDay();
  day.meals = day.meals.filter(m=>m.ts!==ts);
  saveToday();
  renderToday();
}

function changeWater(delta) {
  const day = getDay();
  day.water = Math.max(0, Math.min(16, day.water + delta));
  saveToday();
  renderToday();
}
function toggleCreatine() {
  const day = getDay();
  day.creatine = !day.creatine;
  saveToday();
  renderToday();
}
function addJunk() {
  const input = document.getElementById('junk-input');
  const t = input.value.trim();
  if(!t) return;
  const day = getDay();
  day.junk.push({ name:t, ts:Date.now() });
  saveToday();
  input.value='';
  renderToday();
}
function removeJunk(ts) {
  const day = getDay();
  day.junk = day.junk.filter(j=>j.ts!==ts);
  saveToday();
  renderToday();
}

function currentStreak() {
  let streak = 0;
  const today = new Date();
  for(let i=0;i<60;i++) {
    const d = new Date(today);
    d.setDate(d.getDate() - i);
    const key = d.toISOString().split('T')[0];
    if(workoutLog[key]) streak++;
    else if(i > 0) break;
  }
  return streak;
}

function heroStart() {
  const info = getTodayPlanSession();
  if (info.type === 'no-plan') { openTrainOnboarding(); return; }
  if (info.type === 'custom' || info.type === 'rest') { showSection('plan', document.querySelector('[onclick*="\'plan\'"]')); return; }
  if (!info.sessionType || info.sessionType === 'rest') { showSection('plan', document.querySelector('[onclick*="\'plan\'"]')); return; }
  openSessionLogger();
}

// Returns a normalised session descriptor for today — custom plan first,
// then the static hardcoded schedule, then { type:'no-plan' } as last resort.
function getTodayPlanSession() {
  const today = new Date();
  const todayShort = WEEKDAYS[(today.getDay() + 6) % 7];
  const todayStr = today.toISOString().split('T')[0];
  // Custom onboarding-built plan (mode:'phases')
  if (TP_DATA && TP_DATA.mode === 'phases' && TP_DATA.phases && TP_DATA.phases.length) {
    const pi = Math.min(_tpActivePhase, TP_DATA.phases.length - 1);
    const phase = TP_DATA.phases[pi];
    const sIdx = phase.sessions.findIndex(s => tpDayOf(s) === todayShort);
    if (sIdx >= 0) {
      const sess = phase.sessions[sIdx];
      return { type:'custom', label:sess.focus, name:sess.name, phaseBadge:phase.badge, done:tpIsDone(todayShort), pi, sIdx };
    }
    return { type:'rest', phaseBadge: phase.badge };
  }
  // Static plan (within its hardcoded date window)
  const s = getSessionForDate(today);
  if (s) return { type:'static', done: !!sessionLogs.find(l => l.date === todayStr), ...s };
  // No plan or outside static date range
  return { type:'no-plan' };
}

function renderTodayHero() {
  const hero = document.getElementById('today-hero');
  if(!hero) return;
  const lbl = document.getElementById('th-lbl');
  const title = document.getElementById('th-title');
  const meta = document.getElementById('th-meta');
  const goLabel = document.getElementById('th-go-label');
  const info = getTodayPlanSession();

  hero.classList.remove('rest');
  if (info.type === 'no-plan') {
    lbl.textContent = 'Training';
    title.textContent = 'No plan yet';
    meta.textContent = 'Set up your training plan to start tracking sessions here.';
    goLabel.textContent = 'Build my plan →';
  } else if (info.type === 'custom') {
    lbl.textContent = "Today's session";
    title.textContent = info.label;
    meta.textContent = info.phaseBadge + (info.done ? ' · Done ✓' : '');
    goLabel.textContent = info.done ? 'View in Training' : 'Start session';
  } else if (info.type === 'rest') {
    hero.classList.add('rest');
    lbl.textContent = 'Today';
    title.textContent = 'Rest day';
    meta.textContent = 'No gym — sleep, eat your protein, recover.';
    goLabel.textContent = 'View your plan';
  } else {
    // Static plan session
    if (!info.sessionType || info.sessionType === 'rest') {
      hero.classList.add('rest');
      lbl.textContent = 'Today'; title.textContent = 'Rest day';
      meta.textContent = 'No gym — sleep, eat your protein, recover.';
      goLabel.textContent = 'View your plan';
    } else if (info.sessionType === 'football') {
      lbl.textContent = "Today's session"; title.textContent = 'Football';
      meta.textContent = 'Phase 1a · Week ' + info.week + ' · Counts as cardio';
      goLabel.textContent = info.done ? 'View session' : 'Mark as done';
    } else if (info.sessionType === 'active') {
      lbl.textContent = "Today's session"; title.textContent = 'Active rest';
      meta.textContent = 'Phase 2 · Week ' + info.week + ' · Easy swim or walk';
      goLabel.textContent = info.done ? 'View session' : 'Mark as done';
    } else {
      const sd = SESSION_DATA[info.sessionType];
      lbl.textContent = "Today's session";
      title.textContent = sd ? sd.label : info.sessionType;
      meta.textContent = 'Phase ' + info.phase + ' · Week ' + info.week + (info.done ? ' · Done ✓' : '');
      goLabel.textContent = info.done ? 'View session' : 'Start session';
    }
  }

  const streak = currentStreak();
  const chip = document.getElementById('th-streak');
  if(streak > 0) { chip.style.display = ''; document.getElementById('th-streak-n').textContent = streak; }
  else { chip.style.display = 'none'; }
}

// Desktop bento dashboard (>=1024px). All elements guarded so it's a no-op on mobile.
function renderTodayBento(day, tot, tgt) {
  if(!document.getElementById('today-bento')) return;

  const gn = document.getElementById('desk-greet-name');
  const nm = (typeof authUser !== 'undefined' && authUser && authUser.user_metadata && authUser.user_metadata.name) || '';
  if(gn) { gn.textContent = nm || 'there'; }
  // Phone top bar greeting + date
  const ptHi = document.getElementById('pt-hi');
  if(ptHi){
    if(nm){ ptHi.innerHTML = 'Hello, <span>' + esc(nm) + '</span>'; ptHi.style.display = ''; }
    else { ptHi.textContent = ''; ptHi.style.display = 'none'; }   // no name → just the date, no bare "Hello"
  }
  const ptDate = document.getElementById('pt-date');
  if(ptDate){ ptDate.textContent = new Date().toLocaleDateString('en-GB', {weekday:'long', day:'numeric', month:'long'}); }

  // Hydration tile (desktop bento)
  const wv = document.getElementById('db-water-val');
  if(wv) wv.textContent = day.water;
  const wd = document.getElementById('db-water-dots');
  if(wd){ let s=''; for(let i=0;i<8;i++){ s += '<i class="' + (i < day.water ? 'full' : '') + '"></i>'; } wd.innerHTML = s; }

  // calorie goal ring
  const pct = tgt.kcal ? Math.round(tot.kcal / tgt.kcal * 100) : 0;
  const C = 2 * Math.PI * 58;
  const arc = document.getElementById('db-ring-arc');
  if(arc) { arc.style.strokeDasharray = C.toFixed(1); arc.style.strokeDashoffset = (C * (1 - Math.min(1, pct/100))).toFixed(1); arc.setAttribute('stroke', pct > 108 ? 'var(--pink-500)' : 'var(--green-500)'); }
  const pctEl = document.getElementById('db-ring-pct'); if(pctEl) pctEl.textContent = pct + '%';
  const cap = document.getElementById('db-ring-cap');
  if(cap) cap.textContent = pct >= 100 ? 'Goal hit 🎉' : pct >= 70 ? 'Almost there 💪' : pct >= 30 ? 'Keep fuelling' : "Let's get going";

  // streak
  const streak = currentStreak();
  const sEl = document.getElementById('db-streak'); if(sEl) sEl.textContent = streak;
  const sSub = document.getElementById('db-streak-sub'); if(sSub) sSub.textContent = streak > 0 ? 'days · keep it alive' : 'start one today';

  // weight
  const wEl = document.getElementById('db-wt'), wD = document.getElementById('db-wt-delta'), wS = document.getElementById('db-wt-spark');
  if(wEl) {
    if(weightLog && weightLog.length) {
      const latest = weightLog[0].weight;
      wEl.innerHTML = latest.toFixed(1) + '<span style="font-size:14px"> kg</span>';
      if(weightLog.length > 1) {
        const prev = weightLog[Math.min(weightLog.length - 1, 6)].weight;
        const d = latest - prev, down = d <= 0;
        wD.textContent = (down ? '▼ ' : '▲ ') + Math.abs(d).toFixed(1) + ' kg this week';
        wD.style.color = down ? 'var(--green-700)' : 'var(--amber-900)';
      } else { wD.textContent = 'first entry'; wD.style.color = 'var(--text-tertiary)'; }
      const pts = [...weightLog].slice(0, 7).reverse().map(e => e.weight);
      if(pts.length >= 2) {
        const min = Math.min(...pts), max = Math.max(...pts), rng = (max - min) || 1, w = 120, h = 38;
        const coords = pts.map((v, i) => ((i / (pts.length - 1)) * w).toFixed(0) + ',' + (h - ((v - min) / rng) * (h - 6) - 3).toFixed(0)).join(' ');
        wS.innerHTML = '<svg viewBox="0 0 120 38"><polyline points="' + coords + '" fill="none" stroke="var(--green-500)" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>';
      } else wS.innerHTML = '';
    } else { wEl.innerHTML = '—'; wD.textContent = 'Log it in Progress'; wD.style.color = 'var(--text-tertiary)'; wS.innerHTML = ''; }
  }

  // up next workout
  const wkLbl = document.getElementById('db-wk-lbl'), wkTitle = document.getElementById('db-wk-title'), wkEx = document.getElementById('db-wk-ex'), wkBtn = document.getElementById('db-wk-btn');
  if(wkTitle) {
    const inf = getTodayPlanSession();
    if (inf.type === 'no-plan') {
      wkLbl.textContent = 'Training'; wkTitle.textContent = 'No plan yet';
      wkEx.textContent = 'Build your training plan to start tracking.'; wkBtn.textContent = 'Build my plan';
    } else if (inf.type === 'custom') {
      wkLbl.textContent = 'Up next'; wkTitle.textContent = inf.label;
      wkEx.textContent = inf.phaseBadge; wkBtn.textContent = inf.done ? 'View in Training' : 'Start session';
    } else if (inf.type === 'rest' || !inf.sessionType || inf.sessionType === 'rest') {
      wkLbl.textContent = 'Today'; wkTitle.textContent = 'Rest day';
      wkEx.textContent = 'No gym — recover, sleep, hit your protein.'; wkBtn.textContent = 'View your plan';
    } else if (inf.sessionType === 'football') {
      wkLbl.textContent = 'Up next'; wkTitle.textContent = 'Football';
      wkEx.textContent = 'Counts as cardio · Phase 1a · Week ' + inf.week; wkBtn.textContent = inf.done ? 'View session' : 'Mark as done';
    } else if (inf.sessionType === 'active') {
      wkLbl.textContent = 'Up next'; wkTitle.textContent = 'Active rest';
      wkEx.textContent = 'Easy swim or walk · Phase 2 · Week ' + inf.week; wkBtn.textContent = inf.done ? 'View session' : 'Mark as done';
    } else {
      const sd = SESSION_DATA[inf.sessionType];
      wkLbl.textContent = 'Up next · ' + (inf.phase === '2' ? 'Phase 2' : 'Phase 1');
      wkTitle.textContent = sd ? sd.label : inf.sessionType;
      wkEx.textContent = sd ? sd.exercises.slice(0, 4).map(e => e.name).join(' · ') : '';
      wkBtn.textContent = inf.done ? 'View session' : 'Start session';
    }
  }

  // fuel macros
  const carbT = Math.round(tgt.kcal * 0.45 / 4), fatT = Math.round(tgt.kcal * 0.25 / 9);
  const macWrap = document.getElementById('db-mac');
  if(macWrap) {
    const rows = [['Protein', tot.p, tgt.protein, 'var(--blue-500)'], ['Carbs', tot.c, carbT, 'var(--purple-500)'], ['Fat', tot.f, fatT, 'var(--green-500)']];
    macWrap.innerHTML = rows.map(r => { const pc = r[2] ? Math.min(100, Math.round(r[1] / r[2] * 100)) : 0; return '<div class="row"><span class="k">' + r[0] + '</span><div class="bar"><i style="width:' + pc + '%;background:' + r[3] + '"></i></div><span class="v">' + r[1] + ' / ' + r[2] + 'g</span></div>'; }).join('');
  }

  // recipe tile (only when there are saved recipes)
  const rcp = document.getElementById('db-rcp');
  if(rcp) {
    const r = (recipes && recipes.length) ? recipes[0] : null;
    if(r) {
      const img = r.thumbnail ? '<img src="' + esc(r.thumbnail) + '" alt="">' : '';
      const m = r.macros || {};
      const pills = (m.p != null || m.c != null || m.f != null) ? '<div class="pr"><span class="pill pill-p">P ' + (m.p || 0) + '</span><span class="pill pill-c">C ' + (m.c || 0) + '</span><span class="pill pill-f">F ' + (m.f || 0) + '</span></div>' : '';
      rcp.innerHTML = img + '<div class="b"><div class="t">' + esc(r.title || 'Saved recipe') + '</div>' + pills + '</div>';
      rcp.style.display = ''; rcp.style.cursor = 'pointer';
      rcp.onclick = () => showRecipesSoon();
    } else { rcp.style.display = 'none'; rcp.onclick = null; }
  }
}

function renderToday() {
  const day = getDay();
  const tgt = todayTargets();
  renderTodayHero();
  // headline
  const tot = day.meals.reduce((a,m)=>({kcal:a.kcal+m.kcal,p:a.p+m.p,c:a.c+m.c,f:a.f+m.f}),{kcal:0,p:0,c:0,f:0});
  document.getElementById('t-kcal').textContent = tot.kcal;
  document.getElementById('t-kcal-target').textContent = tgt.kcal;
  document.getElementById('t-prot').textContent = tot.p;
  document.getElementById('t-prot-target').textContent = tgt.protein;
  const kbar = document.getElementById('t-kcal-bar');
  kbar.style.width = Math.min(100, tot.kcal/tgt.kcal*100) + '%';
  kbar.className = 'tsum-fill ' + (tot.kcal > tgt.kcal*1.08 ? 'over' : 'kcal');
  document.getElementById('t-prot-bar').style.width = Math.min(100, tot.p/tgt.protein*100) + '%';
  document.getElementById('t-macp').textContent = tot.p + 'g';
  document.getElementById('t-macc').textContent = tot.c + 'g';
  document.getElementById('t-macf').textContent = tot.f + 'g';

  // sub line
  const _inf = getTodayPlanSession();
  const _sub = document.getElementById('today-sub');
  if (_sub) {
    if (_inf.type === 'custom') _sub.textContent = _inf.phaseBadge + ' · ' + _inf.label;
    else if (_inf.type === 'static' && _inf.phase) _sub.textContent = 'Week ' + _inf.week + ' · ' + (_inf.phase === '2' ? 'Phase 2 — muscle build' : 'Phase 1 — fat loss');
    else _sub.textContent = 'Track your fuel for the day';
  }

  // quick add chips
  document.getElementById('quick-row').innerHTML = QUICK_ADDS.map(q =>
    `<button class="quick-chip" onclick="quickAdd('${esc(q.q)}','${esc(q.label)}')">+ ${esc(q.label)}</button>`).join('');
  document.getElementById('mealplan-row').innerHTML = MEAL_PLAN_ADDS.map((m,i) =>
    `<button class="quick-chip" onclick="mealPlanAdd(${i})">+ ${esc(m.name)}</button>`).join('');

  // food log
  const list = document.getElementById('food-log-list');
  if(!day.meals.length) {
    list.innerHTML = '<div class="food-log-empty">Nothing logged yet today.</div>';
  } else {
    list.innerHTML = [...day.meals].reverse().map(m =>
      `<div class="food-log-item"><div><div class="fl-name">${esc(m.name)}</div><div class="fl-macros">P${m.p} · C${m.c} · F${m.f}</div></div><div class="fl-cal">${m.kcal} kcal</div><button class="fl-del" onclick="removeMeal(${m.ts})" aria-label="Remove">✕</button></div>`).join('');
  }

  // water
  document.getElementById('water-val').textContent = day.water;
  let glasses=''; for(let i=0;i<8;i++){ glasses += `<div class="glass${i<day.water?' full':''}"></div>`; }
  document.getElementById('water-glasses').innerHTML = glasses;

  // creatine
  document.getElementById('creatine-toggle').classList.toggle('on', day.creatine);

  // junk
  document.getElementById('junk-count').textContent = day.junk.length;
  const jl = document.getElementById('junk-list');
  jl.innerHTML = day.junk.length
    ? [...day.junk].reverse().map(j=>`<div class="junk-item"><span>${esc(j.name)}</span><button class="fl-del" onclick="removeJunk(${j.ts})" aria-label="Remove">✕</button></div>`).join('')
    : '';

  renderTodayBento(day, tot, tgt);
  renderTodayNudges(day, tot, tgt);
  renderTodayChart();
}

function renderTodayNudges(day, tot, tgt) {
  const wrap = document.getElementById('today-nudges');
  const nudges = [];
  const hour = new Date().getHours();
  if(!day.creatine && hour >= 12) nudges.push('Don\'t forget your 5g creatine today.');
  if(day.water < 4 && hour >= 15) nudges.push('Only ' + day.water + ' glasses of water so far — top up.');
  if(hour >= 19 && tot.p < tgt.protein*0.7) nudges.push('Protein is at ' + tot.p + 'g of ' + tgt.protein + 'g — a shake before bed helps.');
  wrap.innerHTML = nudges.map(n =>
    `<div class="today-nudge"><svg viewBox="0 0 24 24"><path d="M12 9v4"/><path d="M12 17h.01"/><path d="M10.3 4.3 2.6 18a2 2 0 0 0 1.7 3h15.4a2 2 0 0 0 1.7-3L13.7 4.3a2 2 0 0 0-3.4 0z"/></svg><span>${esc(n)}</span></div>`).join('');
}

function renderTodayChart() {
  if(typeof Chart === 'undefined') return; // Chart.js still loading; re-runs on load
  const canvas = document.getElementById('todayChart');
  const empty = document.getElementById('today-history-empty');
  // last 7 days
  const days = [];
  for(let i=6;i>=0;i--){ const dt=new Date(); dt.setDate(dt.getDate()-i); days.push(dt.toISOString().split('T')[0]); }
  const hasAny = days.some(k => todayData[k] && Array.isArray(todayData[k].meals) && todayData[k].meals.length);
  if(!hasAny) { canvas.style.display='none'; empty.style.display='block'; if(todayChart){todayChart.destroy();todayChart=null;} return; }
  canvas.style.display='block'; empty.style.display='none';
  const labels = days.map(k => new Date(k+'T12:00:00').toLocaleDateString('en-GB',{weekday:'short'}));
  const kcal = days.map(k => (todayData[k]&&todayData[k].meals?todayData[k].meals:[]).reduce((a,m)=>a+(m.kcal||0),0));
  const prot = days.map(k => (todayData[k]&&todayData[k].meals?todayData[k].meals:[]).reduce((a,m)=>a+(m.p||0),0));
  if(todayChart) todayChart.destroy();
  todayChart = new Chart(canvas, {
    type:'bar',
    data:{ labels, datasets:[
      { label:'Calories', data:kcal, backgroundColor:'rgba(29,158,117,0.85)', borderRadius:4, yAxisID:'y' },
      { label:'Protein (g)', data:prot, backgroundColor:'rgba(55,138,221,0.85)', borderRadius:4, yAxisID:'y1' }
    ]},
    options:{
      plugins:{ legend:{ display:true, labels:{ font:{family:'DM Sans',size:11}, color:'#5F5E5A', boxWidth:12 } } },
      scales:{
        y:{ position:'left', grid:{color:'rgba(0,0,0,0.05)'}, ticks:{font:{family:'DM Sans',size:10},color:'#888780'} },
        y1:{ position:'right', grid:{display:false}, ticks:{font:{family:'DM Sans',size:10},color:'#888780'} },
        x:{ grid:{display:false}, ticks:{font:{family:'DM Sans',size:11},color:'#888780'} }
      },
      responsive:true, maintainAspectRatio:true
    }
  });
}

// ==================== REMINDERS (Web Push) ====================
const VAPID_PUBLIC_KEY = "BJeO4EGkQZRdMrAP9f8cTc98lNWPXGLeq0jkjJOWybAlmvmfHBIlIQpmV-z9VvwjGL32YjOc3p1Q6ZMq0PiJQJY";
const REMINDER_BACKEND = "https://summerbody.me-e29.workers.dev"; // Cloudflare Worker

let remState = loadStore('sbp-reminders', { enabled:false, protein:'09:00', creatine:'20:00' });

// ==================== CROSS-DEVICE SYNC (Supabase) ====================
// Data lives in Supabase Postgres (table app_data) keyed by the signed-in
// user. localStorage stays as the offline cache; we mirror each synced key
// to a row and reconcile per-key by newer updated_at. Sign in to turn it on;
// logged-out the app is fully usable (local only).
//
// Fill these in before deploying (anon key is safe to ship; never the
// service_role key):
const SUPABASE_URL = 'https://owqyrgufwvqgbrpdpskx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93cXlyZ3Vmd3ZxZ2JycGRwc2t4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3MzczOTQsImV4cCI6MjA5NjMxMzM5NH0.Z_zUJbKvO6-FBbKheDmlVu46XjT9toFaVlct12IY8zU';

const SYNC_KEYS = ['sbp-today','sbp-weight','sbp-workouts','sbp-session-logs','sbp-shop','sbp-mealshop','sbp-mealplan','sbp-trainingplan','sbp-tp-progress','sbp-readiness','sbp-recipes','sbp-meallog','sbp-setlogs'];
const SYNC_KEY_SET = new Set(SYNC_KEYS);

// Capture the real setter BEFORE patching, so our own sync writes don't recurse.
const _lsSet = localStorage.setItem.bind(localStorage);

let sb = null;            // Supabase client (created once configured + signed in flow)
let authUser = null;      // current signed-in user, or null
let _lastSync = 0;        // ms of last successful pull/push
let _dirty = new Set();   // synced keys edited since last push
let _remoteT = {};        // last-seen remote updated_at (ms) per key

function syncConfigured(){ return SUPABASE_URL.indexOf('__') !== 0 && SUPABASE_ANON_KEY.indexOf('__') !== 0; }
function getSyncMeta(){ try { return JSON.parse(localStorage.getItem('sbp-sync-meta')) || {}; } catch(_){ return {}; } }
function saveSyncMeta(m){ _lsSet('sbp-sync-meta', JSON.stringify(m)); }

// Patch setItem so each save to a synced key timestamps it and queues a push.
localStorage.setItem = function(k, v){
  _lsSet(k, v);
  if (authUser && SYNC_KEY_SET.has(k)) {
    const m = getSyncMeta(); m[k] = Date.now(); saveSyncMeta(m);
    _dirty.add(k); schedulePush();
  }
};

let _pushTimer = null;
function schedulePush(){
  if (!authUser) return;
  clearTimeout(_pushTimer);
  _pushTimer = setTimeout(() => { pushDirty().catch(()=>{}); }, 1500);
}

// Load the Supabase JS SDK on demand (keeps the initial load light and works
// even if the CDN is briefly unreachable — the app just stays local-only).
function ensureSupabase(){
  return new Promise((resolve) => {
    if (window.supabase) return resolve(true);
    const s = document.createElement('script');
    s.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js';
    s.async = true;
    s.onload = () => resolve(true);
    s.onerror = () => resolve(false);
    document.head.appendChild(s);
  });
}

// Startup: create the client (if configured), restore any session, and wire
// up auth-state changes.
async function initAuth(){
  _otpInjectPanel();
  _injectAgeCheck();
  _injectDeleteAccount();
  reflectAuth();
  if (!syncConfigured()) return;            // placeholders not filled yet
  const ok = await ensureSupabase();
  if (!ok || !window.supabase) return;
  sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
  });
  sb.auth.onAuthStateChange((_event, session) => { onAuth(session); });
  try { const { data } = await sb.auth.getSession(); await onAuth(data.session); }
  catch(_){ reflectAuth(); }
}

async function onAuth(session){
  authUser = (session && session.user) ? session.user : null;
  reflectAuth();
  if (authUser) {
    try { localStorage.setItem('sbp-onboarded', '1'); } catch(_){}
    if (_pendingWelcome) {
      _pendingWelcome = false;
      const name = (authUser.user_metadata && authUser.user_metadata.name) || '';
      await playWelcome(name);
    }
    try { await syncReconcile(); } catch(_){}
  }
}

// Pull everything, merge newer-wins; if our screen data changed, reload once
// so the in-memory globals rebuild cleanly. Then push anything locally-newer.
async function syncReconcile(){
  const changed = await pullMerge();
  if (changed && !sessionStorage.getItem('sbp-synced-reload')) {
    sessionStorage.setItem('sbp-synced-reload', '1');
    location.reload();
    return;
  }
  await pushNewer();
}

async function pullMerge(){
  if (!sb || !authUser) return false;
  const { data, error } = await sb.from('app_data')
    .select('key,value,updated_at').eq('user_id', authUser.id);
  if (error) throw error;
  const meta = getSyncMeta();
  let changed = false;
  _remoteT = {};
  for (const row of (data || [])) {
    if (!SYNC_KEY_SET.has(row.key)) continue;
    const rt = Date.parse(row.updated_at);
    _remoteT[row.key] = rt;
    if (rt > (meta[row.key] || 0)) {
      const str = JSON.stringify(row.value);
      if (localStorage.getItem(row.key) !== str) { _lsSet(row.key, str); changed = true; }
      meta[row.key] = rt;
    }
  }
  saveSyncMeta(meta);
  _lastSync = Date.now(); reflectAuth();
  return changed;
}

// Push a local key when the server has no copy of it, or when our local
// timestamp beats the server's. The "no copy yet" case is essential: data
// created while logged-out never stamps sbp-sync-meta (that only happens for
// signed-in writes), so on first sign-in those keys have local ts 0 AND remote
// ts 0 — a strict ">" would never seed them and nothing would ever push.
async function pushNewer(){
  const meta = getSyncMeta();
  for (const k of SYNC_KEYS) {
    if (localStorage.getItem(k) == null) continue;
    if (!(k in _remoteT)) { _dirty.add(k); continue; }   // server has no row — seed it
    if ((meta[k] || 0) > (_remoteT[k] || 0)) _dirty.add(k);
  }
  await pushDirty();
}

async function pushDirty(){
  if (!sb || !authUser || !_dirty.size) return;
  const keys = [..._dirty]; _dirty.clear();
  const rows = [];
  for (const k of keys) {
    const v = localStorage.getItem(k);
    if (v == null) continue;
    let parsed; try { parsed = JSON.parse(v); } catch(_){ continue; }
    rows.push({ user_id: authUser.id, key: k, value: parsed });
  }
  if (!rows.length) return;
  const { data, error } = await sb.from('app_data')
    .upsert(rows, { onConflict: 'user_id,key' }).select('key,updated_at');
  if (error) { keys.forEach(k => _dirty.add(k)); throw error; }   // retry next time
  const meta = getSyncMeta();
  for (const row of (data || [])) { meta[row.key] = Date.parse(row.updated_at); _remoteT[row.key] = meta[row.key]; }
  saveSyncMeta(meta);
  _lastSync = Date.now(); reflectAuth();
}

// ---- auth UI actions ----
// 'in' = sign in, 'up' = create account
let _authMode = 'in';
let _pendingWelcome = false;

// Full-screen "Welcome, <name>" celebration after a successful sign-in.
function playWelcome(name){
  return new Promise(resolve => {
    const ov = document.getElementById('welcome-ov');
    if (!ov) { resolve(); return; }
    const nm = document.getElementById('welcome-name');
    if (nm) nm.textContent = name || 'You’re in';
    ov.classList.remove('out', 'show');
    void ov.offsetWidth;        // restart CSS animations
    ov.classList.add('show');
    setTimeout(() => { ov.classList.add('out'); }, 2000);
    setTimeout(() => { ov.classList.remove('show', 'out'); resolve(); }, 2600);
  });
}
// Age-declaration checkbox (minors compliance) — injected into the sign-up form,
// only visible in 'up' mode, required to submit. app.js-owned (no index.html edit).
function _injectAgeCheck(){
  const form = document.getElementById('auth-form');
  const cta = document.getElementById('auth-cta');
  if (!form || !cta || document.getElementById('auth-age-field')) return;
  const wrap = document.createElement('label');
  wrap.className = 'signin-age hide';
  wrap.id = 'auth-age-field';
  wrap.setAttribute('for', 'auth-age');
  wrap.innerHTML =
    '<input type="checkbox" id="auth-age"> ' +
    '<span>I confirm I am 13 or older</span>';
  form.insertBefore(wrap, cta);
}

function authSetMode(mode){
  _authMode = (mode === 'up') ? 'up' : 'in';
  const up = _authMode === 'up';
  document.querySelectorAll('#auth-seg button').forEach(b => b.classList.toggle('on', b.dataset.mode === _authMode));
  const nameField = document.getElementById('auth-name-field'); if (nameField) nameField.classList.toggle('hide', !up);
  const ageField = document.getElementById('auth-age-field'); if (ageField) ageField.classList.toggle('hide', !up);
  const title = document.getElementById('auth-title'); if (title) title.textContent = up ? 'Create your account' : 'Welcome back';
  const sub = document.getElementById('auth-sub'); if (sub) sub.textContent = up ? 'Apple, Google, or just an email — it’s free.' : 'Sign in to pick up where you left off.';
  const cta = document.getElementById('auth-cta'); if (cta) cta.textContent = up ? 'Create account' : 'Sign in';
  const forgot = document.getElementById('auth-forgot'); if (forgot) forgot.style.display = up ? 'none' : 'block';
  const toggle = document.getElementById('auth-toggle');
  if (toggle) toggle.innerHTML = up
    ? 'Already have an account? <b onclick="authSetMode(\'in\')">Sign in</b>'
    : 'New here? <b onclick="authSetMode(\'up\')">Create account</b>';
  const pw = document.getElementById('auth-password'); if (pw) pw.setAttribute('autocomplete', up ? 'new-password' : 'current-password');
}

async function authSubmit(){
  if (!syncConfigured() || !sb) { showToast('Sign-in isn’t set up yet.', 'error'); return; }
  const email = (document.getElementById('auth-email').value || '').trim();
  const password = document.getElementById('auth-password').value || '';
  const name = (document.getElementById('auth-name').value || '').trim();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { showToast('Enter a valid email.', 'error'); return; }
  if (password.length < 6) { showToast('Password must be at least 6 characters.', 'error'); return; }
  if (_authMode === 'up' && !name) { showToast('Enter your name.', 'error'); return; }
  const ageBox = document.getElementById('auth-age');
  if (_authMode === 'up' && ageBox && !ageBox.checked) { showToast('Please confirm you are 13 or older.', 'error'); return; }
  const btn = document.getElementById('auth-cta');
  const restore = _authMode === 'up' ? 'Create account' : 'Sign in';
  if (btn) { btn.disabled = true; btn.textContent = _authMode === 'up' ? 'Creating account…' : 'Signing in…'; }
  try {
    if (_authMode === 'up') {
      const { data, error } = await sb.auth.signUp({ email, password, options: { data: { name } } });
      if (error) throw error;
      if (data.session) { _pendingWelcome = true; }   // auto-confirmed (shouldn't happen with OTP on)
      else { showOtpStep(email); }
      // when there's a session, onAuthStateChange takes over (plays welcome).
    } else {
      const { error } = await sb.auth.signInWithPassword({ email, password });
      if (error) {
        // Unverified account trying to sign in → send them to verify instead.
        const msg = (error.message || '').toLowerCase();
        if (error.code === 'email_not_confirmed' || msg.indexOf('not confirmed') !== -1 || msg.indexOf('not verified') !== -1) {
          showToast('Verify your email first — we sent you a code.', 'info');
          try { await sb.auth.resend({ type: 'signup', email }); } catch(_){}
          showOtpStep(email);
        } else {
          throw error;
        }
      } else {
        _pendingWelcome = true;
        // onAuthStateChange takes over (plays welcome).
      }
    }
  } catch(e){ showToast((e && e.message) || 'Could not sign in', 'error'); }
  finally { if (btn) { btn.disabled = false; btn.textContent = restore; } }
}

// One-tap providers. Redirects away and back; detectSessionInUrl + the
// onAuthStateChange listener pick the session up on return. Until the provider
// is enabled in the Supabase dashboard this surfaces a clear toast.
async function authOAuth(provider){
  if (!syncConfigured() || !sb) { showToast('Sign-in isn’t set up yet.', 'error'); return; }
  try {
    const { error } = await sb.auth.signInWithOAuth({
      provider,
      options: { redirectTo: location.href.split('#')[0] }
    });
    if (error) throw error;
    // success → browser redirects to the provider; nothing more to do here.
  } catch(e){
    const label = provider.charAt(0).toUpperCase() + provider.slice(1);
    showToast((e && e.message) || ('Could not continue with ' + label), 'error');
  }
}

async function authForgot(){
  if (!sb) return;
  const email = (document.getElementById('auth-email').value || '').trim();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { showToast('Enter your email above first.', 'error'); return; }
  try {
    const { error } = await sb.auth.resetPasswordForEmail(email, { redirectTo: location.href.split('#')[0] });
    if (error) throw error;
    showToast('Password reset link sent — check your email.', 'success');
  } catch(e){ showToast((e && e.message) || 'Could not send reset email', 'error'); }
}

// ---- OTP email-verification step (shown after signUp when OTP is enabled) ----
let _otpEmail = '';
let _resendTimer = null;

function _otpInjectPanel(){
  const sheet = document.querySelector('.sigate-sheet');
  if (!sheet || document.getElementById('otp-panel')) return;
  const panel = document.createElement('div');
  panel.id = 'otp-panel';
  panel.style.display = 'none';
  panel.innerHTML =
    '<div class="signin-field">' +
      '<label for="otp-code">6-digit code</label>' +
      '<input class="signin-input" id="otp-code" type="text" inputmode="numeric" pattern="[0-9]*" ' +
        'maxlength="6" placeholder="000000" autocomplete="one-time-code" ' +
        'autocapitalize="none" spellcheck="false">' +
    '</div>' +
    '<button class="sigate-cta" id="otp-verify-btn" type="button" onclick="otpVerify()">Verify</button>' +
    '<div class="sigate-forgot"><a id="otp-resend" onclick="otpResend()" style="cursor:pointer">Resend code</a></div>' +
    '<div class="sigate-toggle"><a onclick="hideOtpStep()" style="cursor:pointer">← Use a different email</a></div>';
  sheet.appendChild(panel);
  // auto-submit when 6 digits entered
  document.getElementById('otp-code').addEventListener('input', function(){
    const v = this.value.replace(/\D/g,'').slice(0,6);
    this.value = v;
    if (v.length === 6) otpVerify();
  });
}

const _OTP_HIDE_SELS = ['#auth-form','#auth-forgot','#auth-toggle','.sbtn.apple','.sbtn.google','.sigate-or','.sigate-fine','#auth-seg'];

function _setOtpPanelVisible(on){
  const panel = document.getElementById('otp-panel');
  if (panel) panel.style.display = on ? '' : 'none';
  _OTP_HIDE_SELS.forEach(sel => {
    document.querySelectorAll(sel).forEach(el => { el.style.display = on ? 'none' : ''; });
  });
}

function showOtpStep(email){
  _otpEmail = email;
  const title = document.getElementById('auth-title');
  const sub   = document.getElementById('auth-sub');
  if (title) title.textContent = 'Check your email';
  if (sub)   sub.textContent   = 'Enter the 6-digit code we sent to ' + email + '.';
  _setOtpPanelVisible(true);
  const input = document.getElementById('otp-code');
  if (input){ input.value = ''; setTimeout(() => input.focus(), 80); }
  _startResendCooldown(60);   // just sent — enforce 60 s before resend
}

function hideOtpStep(){
  _setOtpPanelVisible(false);
  _otpEmail = '';
  if (_resendTimer){ clearInterval(_resendTimer); _resendTimer = null; }
  const link = document.getElementById('otp-resend');
  if (link){ link.style.pointerEvents = ''; link.textContent = 'Resend code'; }
  authSetMode('in');
}

async function otpVerify(){
  if (!sb) return;
  const raw = (document.getElementById('otp-code').value || '').replace(/\D/g,'');
  if (raw.length !== 6){ showToast('Enter the 6-digit code from your email.', 'error'); return; }
  const btn = document.getElementById('otp-verify-btn');
  if (btn){ btn.disabled = true; btn.textContent = 'Verifying…'; }
  try {
    const { error } = await sb.auth.verifyOtp({ email: _otpEmail, token: raw, type: 'signup' });
    if (error) throw error;
    _pendingWelcome = true;
    hideOtpStep();
    // onAuthStateChange fires → onAuth() → playWelcome()
  } catch(e){
    showToast('Invalid code, try again', 'error');
    const input = document.getElementById('otp-code');
    if (input){ input.value = ''; input.focus(); }
  } finally {
    if (btn){ btn.disabled = false; btn.textContent = 'Verify'; }
  }
}

function _startResendCooldown(secs){
  if (_resendTimer){ clearInterval(_resendTimer); }
  const link = document.getElementById('otp-resend');
  if (link){ link.style.pointerEvents = 'none'; link.textContent = 'Resend in ' + secs + 's'; }
  _resendTimer = setInterval(function(){
    secs--;
    if (link) link.textContent = secs > 0 ? 'Resend in ' + secs + 's' : 'Resend code';
    if (secs <= 0){
      clearInterval(_resendTimer); _resendTimer = null;
      if (link) link.style.pointerEvents = '';
    }
  }, 1000);
}

async function otpResend(){
  if (!sb || !_otpEmail) return;
  const link = document.getElementById('otp-resend');
  if (link){ link.style.pointerEvents = 'none'; link.textContent = 'Sending…'; }
  try {
    const { error } = await sb.auth.resend({ type: 'signup', email: _otpEmail });
    if (error) throw error;
    showToast('New code sent — check your email.', 'success');
    _startResendCooldown(60);
  } catch(e){
    showToast((e && e.message) || 'Could not resend the code.', 'error');
    if (link){ link.style.pointerEvents = ''; link.textContent = 'Resend code'; }
  }
}

async function authSignOut(){
  if (!sb) return;
  try { localStorage.removeItem('sbp-onboarded'); } catch(_){}  // explicit sign-out → gate returns next launch
  await sb.auth.signOut();   // local data stays; syncing just stops
  showToast('Signed out — your data stays on this device', 'info');
}

// ---- Delete my account (AADC / GDPR data-deletion-on-request, Path A) ----
// Injects a red "Delete my account" row into the signed-in card + a confirm
// modal (typing DELETE to arm it). On success: wipe all sbp-*/bb-* local keys
// and sign out to the front door. app.js-owned — no index.html edit.
function _injectDeleteAccount(){
  const inn = document.getElementById('auth-in');
  if (inn && !document.getElementById('danger-zone')){
    const dz = document.createElement('div');
    dz.id = 'danger-zone';
    dz.className = 'signin-card';
    dz.style.cssText = 'margin-top:14px';
    dz.innerHTML =
      '<div class="food-hint" style="margin-bottom:10px">Danger zone</div>' +
      '<button id="delete-acct-row" onclick="openDeleteAccount()" ' +
        'style="width:100%;text-align:left;display:flex;align-items:center;gap:10px;' +
        'padding:12px 14px;border:1px solid #e7c9c6;background:#fdf3f2;color:#c0392b;' +
        'border-radius:12px;font-weight:600;font-family:inherit;font-size:15px;cursor:pointer">' +
        '<i class="fa-solid fa-trash-can" aria-hidden="true"></i> Delete my account</button>';
    inn.appendChild(dz);
  }
  if (!document.getElementById('delete-acct-modal')){
    const m = document.createElement('div');
    m.id = 'delete-acct-modal';
    m.style.cssText = 'display:none;position:fixed;inset:0;z-index:250;';
    m.innerHTML =
      '<div class="modal-overlay" onclick="closeDeleteAccount()"></div>' +
      '<div class="modal-panel">' +
        '<div class="modal-header"><div>' +
          '<div class="modal-title">Delete my account</div>' +
          '<div class="modal-sub">This can’t be undone.</div>' +
        '</div><button class="modal-close" onclick="closeDeleteAccount()"><i class="fa-solid fa-xmark"></i></button></div>' +
        '<div class="modal-body">' +
          '<p style="margin:0 0 16px;line-height:1.5;color:var(--text-secondary)">' +
            'This permanently deletes your account and all your data. This can’t be undone.</p>' +
          '<label for="delete-acct-input" style="display:block;margin-bottom:6px;font-size:14px">' +
            'Type <b>DELETE</b> to confirm</label>' +
          '<input class="signin-input" id="delete-acct-input" type="text" placeholder="DELETE" ' +
            'autocomplete="off" autocapitalize="characters" spellcheck="false" oninput="_deleteInputChange()">' +
          '<button class="sigate-cta" id="delete-acct-confirm" disabled onclick="confirmDeleteAccount()" ' +
            'style="background:#d9463e;margin-top:14px">Delete my account</button>' +
          '<button onclick="closeDeleteAccount()" ' +
            'style="width:100%;margin-top:8px;background:none;border:none;color:var(--text-secondary);' +
            'font-family:inherit;font-size:15px;padding:10px;cursor:pointer">Cancel</button>' +
        '</div>' +
      '</div>';
    document.body.appendChild(m);
  }
}

function openDeleteAccount(){
  const m = document.getElementById('delete-acct-modal');
  const inp = document.getElementById('delete-acct-input');
  const btn = document.getElementById('delete-acct-confirm');
  if (inp) inp.value = '';
  if (btn){ btn.disabled = true; btn.textContent = 'Delete my account'; }
  if (m) m.style.display = 'block';
  if (inp) setTimeout(() => inp.focus(), 80);
}

function closeDeleteAccount(){
  const m = document.getElementById('delete-acct-modal');
  if (m) m.style.display = 'none';
}

function _deleteInputChange(){
  const inp = document.getElementById('delete-acct-input');
  const btn = document.getElementById('delete-acct-confirm');
  if (btn) btn.disabled = ((inp.value || '').trim().toUpperCase() !== 'DELETE');
}

function _clearAllLocalData(){
  const keys = [];
  for (let i = 0; i < localStorage.length; i++){
    const k = localStorage.key(i);
    if (k && (k.indexOf('sbp-') === 0 || k.indexOf('bb-') === 0)) keys.push(k);
  }
  keys.forEach(k => localStorage.removeItem(k));
}

async function confirmDeleteAccount(){
  if (!sb || !authUser){ showToast('You’re not signed in.', 'error'); return; }
  const btn = document.getElementById('delete-acct-confirm');
  if (btn){ btn.disabled = true; btn.textContent = 'Deleting…'; }
  try {
    const { data } = await sb.auth.getSession();
    const token = data && data.session && data.session.access_token;
    if (!token) throw new Error('No active session');
    const res = await fetch(REMINDER_BACKEND.replace(/\/$/, '') + '/account/delete', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token }
    });
    if (!res.ok) throw new Error('status ' + res.status);
    const body = await res.json().catch(() => ({}));
    if (!body.ok) throw new Error('delete not confirmed');
    // Success → wipe everything local and drop to the signed-out front door.
    _clearAllLocalData();
    try { await sb.auth.signOut(); } catch(_){}
    closeDeleteAccount();
    showToast('Your account and all your data have been deleted.', 'success');
    setTimeout(() => location.reload(), 1000);
  } catch(e){
    showToast('Couldn’t delete your account — please try again.', 'error');
    if (btn){ btn.disabled = false; btn.textContent = 'Delete my account'; }
  }
}

function syncNow(){
  if (!authUser) return;
  showToast('Syncing…', 'info');
  syncReconcile()
    .then(() => { if (!sessionStorage.getItem('sbp-synced-reload')) showToast('Up to date', 'success'); })
    .catch(() => showToast('Sync failed — try again', 'error'));
}

// TEMP (dev only): skip the sign-in gate while building the app. Persists across
// reloads via localStorage; the floating dev pill clears it. Remove before launch.
function devSkipSignin(){
  localStorage.setItem('sbp-dev-skip', '1');
  reflectAuth();
  showToast('Sign-in skipped (dev mode). Tap the pill to bring it back.', 'info');
}
function devUndoSkip(){
  localStorage.removeItem('sbp-dev-skip');
  reflectAuth();
}

function reflectAuth(){
  const gate = document.getElementById('signin-gate');
  const inn = document.getElementById('auth-in');
  const accBtn = document.getElementById('account-btn');
  // Account-first: show the full-screen front door whenever the auth client is
  // ready but nobody's signed in. If the SDK never loaded (offline / not
  // configured) sb stays null and we DON'T gate — the app stays usable.
  const devSkip = localStorage.getItem('sbp-dev-skip') === '1';
  // Once you've signed in on this device we don't slam the front door on every
  // cold launch — Supabase restores/refreshes the session in the background, and
  // even if it can't (e.g. offline) the app stays usable with local data. The
  // gate only returns for a brand-new device or after an explicit sign-out.
  const onboarded = localStorage.getItem('sbp-onboarded') === '1';
  const showGate = !!sb && !authUser && !devSkip && !onboarded;
  if (gate) { gate.classList.toggle('show', showGate); gate.setAttribute('aria-hidden', showGate ? 'false' : 'true'); }
  document.documentElement.classList.toggle('gated', showGate);
  // TEMP dev pill: visible only while sign-in is skipped & nobody's signed in.
  const pill = document.getElementById('dev-skip-pill');
  if (pill) pill.style.display = (devSkip && !authUser) ? 'inline-flex' : 'none';
  if (accBtn) { accBtn.classList.toggle('signed-in', !!authUser); accBtn.style.display = authUser ? '' : 'none'; }
  const out = document.getElementById('auth-out');
  if (out) out.style.display = authUser ? 'none' : 'block';
  if (inn) inn.style.display = authUser ? 'block' : 'none';
  if (authUser) {
    const name = (authUser.user_metadata && authUser.user_metadata.name) || '';
    const greet = document.getElementById('auth-greeting');
    if (greet) greet.textContent = name ? ('Hey ' + name + ' 👋') : "You're signed in";
    const u = document.getElementById('auth-user'); if (u) u.textContent = authUser.email || '';
    const last = document.getElementById('auth-last');
    if (last) last.textContent = _lastSync ? ('Last synced ' + new Date(_lastSync).toLocaleTimeString()) : 'Syncing…';
  }
}

// ---- Account settings (units + reminder times mirrored into account screen) ----
let bbSettings = loadStore('sbp-settings', { weightUnit: 'kg' });
function saveSettings(){ localStorage.setItem('sbp-settings', JSON.stringify(bbSettings)); }

function openSignInFromAccount(){
  const gate = document.getElementById('signin-gate');
  if(gate){ gate.classList.add('show'); gate.setAttribute('aria-hidden','false'); }
  document.documentElement.classList.add('gated');
}

function initAccountSettings(){
  const p = document.getElementById('acct-rem-protein');
  const c = document.getElementById('acct-rem-creatine');
  if(p) p.value = remState.protein || '09:00';
  if(c) c.value = remState.creatine || '20:00';
  const unit = (bbSettings && bbSettings.weightUnit) || 'kg';
  const kgBtn = document.getElementById('unit-kg');
  const lbsBtn = document.getElementById('unit-lbs');
  if(kgBtn) kgBtn.classList.toggle('on', unit === 'kg');
  if(lbsBtn) lbsBtn.classList.toggle('on', unit === 'lbs');
}

function acctRemChange(){
  const p = document.getElementById('acct-rem-protein');
  const c = document.getElementById('acct-rem-creatine');
  if(p) remState.protein = p.value;
  if(c) remState.creatine = c.value;
  saveRemState();
  const tp = document.getElementById('rem-protein');
  const tc = document.getElementById('rem-creatine');
  if(tp) tp.value = remState.protein;
  if(tc) tc.value = remState.creatine;
  showToast('Reminder times saved', 'success');
}

function setWeightUnit(unit){
  bbSettings.weightUnit = unit;
  saveSettings();
  const kgBtn = document.getElementById('unit-kg');
  const lbsBtn = document.getElementById('unit-lbs');
  if(kgBtn) kgBtn.classList.toggle('on', unit === 'kg');
  if(lbsBtn) lbsBtn.classList.toggle('on', unit === 'lbs');
  showToast('Units set to ' + unit, 'success');
}

// Lightweight in-app toast (replaces native alert, matches the design system)
const TOAST_ICONS = {
  success: '<polyline points="20 6 9 17 4 12"/>',
  error: '<circle cx="12" cy="12" r="9"/><line x1="12" y1="8" x2="12" y2="13"/><line x1="12" y1="16" x2="12.01" y2="16"/>',
  info: '<circle cx="12" cy="12" r="9"/><line x1="12" y1="11" x2="12" y2="16"/><line x1="12" y1="8" x2="12.01" y2="8"/>'
};
let toastTimer = null;
function showToast(msg, type){
  type = type || 'success';
  const wrap = document.getElementById('toast-wrap');
  if(!wrap) return;
  wrap.innerHTML = '<div class="toast ' + type + '"><svg class="toast-ic" viewBox="0 0 24 24" stroke="currentColor">' + TOAST_ICONS[type] + '</svg><span>' + esc(msg) + '</span></div>';
  const el = wrap.firstChild;
  requestAnimationFrame(() => el.classList.add('show'));
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    el.classList.remove('show');
    setTimeout(() => { if(wrap.firstChild === el) wrap.innerHTML = ''; }, 260);
  }, type === 'error' ? 4200 : 2800);
}

function pushSupported(){ return 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window; }
function isiOS(){ return /iphone|ipad|ipod/i.test(navigator.userAgent); }
function isStandalone(){ return (window.matchMedia && window.matchMedia('(display-mode: standalone)').matches) || window.navigator.standalone === true; }
function p2(n){ return String(n).padStart(2,'0'); }
function localToUtc(hhmm){ const [h,m]=hhmm.split(':').map(Number); const d=new Date(); d.setHours(h,m,0,0); return p2(d.getUTCHours())+':'+p2(d.getUTCMinutes()); }
function urlB64ToUint8(base64){
  const pad='='.repeat((4-base64.length%4)%4);
  const b64=(base64+pad).replace(/-/g,'+').replace(/_/g,'/');
  const raw=atob(b64); const arr=new Uint8Array(raw.length);
  for(let i=0;i<raw.length;i++) arr[i]=raw.charCodeAt(i);
  return arr;
}
function saveRemState(){ localStorage.setItem('sbp-reminders', JSON.stringify(remState)); }

function initReminders(){
  const proteinEl=document.getElementById('rem-protein'), creatineEl=document.getElementById('rem-creatine');
  if(!proteinEl) return;
  proteinEl.value=remState.protein||'09:00';
  creatineEl.value=remState.creatine||'20:00';
  proteinEl.onchange=creatineEl.onchange=onRemTimeChange;
  reflectReminders();
}

function reflectReminders(){
  const status=document.getElementById('rem-status');
  const times=document.getElementById('rem-times');
  const btn=document.getElementById('rem-enable-btn');
  const hint=document.getElementById('rem-hint');
  if(!status) return;
  if(!pushSupported()){
    status.textContent='Reminders aren’t supported in this browser.'; btn.style.display='none'; times.style.display='none'; hint.style.display='none'; return;
  }
  if(isiOS() && !isStandalone()){
    status.textContent='To get reminders on iPhone: tap Share → Add to Home Screen, open the app from there, then enable.';
    btn.style.display='none'; times.style.display='none'; hint.style.display='none'; return;
  }
  if(!REMINDER_BACKEND){ hint.textContent='Reminder delivery is being connected — enabling works once that’s live.'; }
  const on = remState.enabled && Notification.permission==='granted';
  status.className = on ? 'rem-status on' : 'rem-status';
  status.textContent = on
    ? 'Reminders are on — protein at '+remState.protein+', creatine at '+remState.creatine+'.'
    : 'Get a buzz when it’s time for your protein & creatine.';
  times.style.display='block';
  btn.style.display='block';
  btn.textContent = on ? 'Turn off reminders' : 'Enable reminders';
  btn.onclick = on ? disableReminders : enableReminders;
}

async function enableReminders(){
  try{
    if(!pushSupported()) return;
    if(!REMINDER_BACKEND){ showToast('Reminders server is still being connected — try again shortly.', 'info'); return; }
    const perm=await Notification.requestPermission();
    if(perm!=='granted'){ showToast('Notifications weren’t allowed. Turn them on in Settings, then try again.', 'error'); return; }
    const reg=await navigator.serviceWorker.register('sw.js');
    await navigator.serviceWorker.ready;
    let sub=await reg.pushManager.getSubscription();
    if(!sub){ sub=await reg.pushManager.subscribe({ userVisibleOnly:true, applicationServerKey:urlB64ToUint8(VAPID_PUBLIC_KEY) }); }
    remState.enabled=true; saveRemState();
    await syncSubscription(sub);
    reflectReminders();
    showToast('Reminders enabled', 'success');
  }catch(e){ console.error(e); showToast('Could not enable reminders: '+(e&&e.message||e), 'error'); }
}

async function syncSubscription(sub){
  if(!REMINDER_BACKEND) return;
  const schedule={ protein:localToUtc(remState.protein), creatine:localToUtc(remState.creatine) };
  await fetch(REMINDER_BACKEND.replace(/\/$/,'')+'/subscribe',{
    method:'POST', headers:{'Content-Type':'application/json'},
    body:JSON.stringify({ subscription: sub.toJSON?sub.toJSON():sub, schedule })
  });
}

async function onRemTimeChange(){
  remState.protein=document.getElementById('rem-protein').value;
  remState.creatine=document.getElementById('rem-creatine').value;
  saveRemState();
  if(remState.enabled){
    try{
      const reg=await navigator.serviceWorker.getRegistration();
      const sub=reg && await reg.pushManager.getSubscription();
      if(sub){ await syncSubscription(sub); showToast('Reminder times updated', 'success'); }
    }catch(_){}
  }
  reflectReminders();
}

async function disableReminders(){
  try{
    const reg=await navigator.serviceWorker.getRegistration();
    if(reg){
      const sub=await reg.pushManager.getSubscription();
      if(sub){
        if(REMINDER_BACKEND){ try{ await fetch(REMINDER_BACKEND.replace(/\/$/,'')+'/unsubscribe',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({endpoint:sub.endpoint})}); }catch(_){} }
        await sub.unsubscribe();
      }
    }
  }catch(_){}
  remState.enabled=false; saveRemState(); reflectReminders();
  showToast('Reminders turned off', 'info');
}

// ==================== SPLASH ====================
/* Splash motion (transform/opacity/filter only — no layout, no reflow).
   The earlier version slid the middle letters horizontally out of the S|B
   seam, which made them smear past each other. This follows how Apple/Stripe
   /Codrops do premium reveals instead:
     1. Measure the natural "SummerBody" layout.
     2. Show only "SB" — S and B glide together at centre, rest hidden.
     3. Hold that "SB" for a beat.
     4. S glides left, B glides right to their real spots (the ONLY sideways
        motion, so nothing overlaps), while "ummer" and "ody" materialise in
        place — blur-in + a small upward rise — in a left-to-right stagger.
     5. Hold the finished wordmark, then fade the layer out. */
const SPLASH_BEAT = 750;    // how long the "BB" logo sits alone before the split
const SPLASH_GLIDE = 720;   // B/B travel + letters settle
const SPLASH_HOLD = 700;    // finished wordmark dwell time before the fade-out
function playSplash(){
  const el = document.getElementById('splash');
  if(!el || !document.documentElement.classList.contains('show-splash')) return;
  el.addEventListener('click', dismissSplash, { once:true });

  const reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const run = () => {
    const mark = document.getElementById('splash-mark');
    if(!mark){ setTimeout(dismissSplash, 800); return; }
    if(reduce){
      mark.style.opacity = '1';
      setTimeout(dismissSplash, 1600);
      return;
    }
    const letters = Array.prototype.slice.call(mark.querySelectorAll('.spl'));
    const markBox = mark.getBoundingClientRect();
    const items = letters.map((l, idx) => {
      const r = l.getBoundingClientRect();
      return { el: l, idx, left: r.left - markBox.left, w: r.width, g: l.dataset.g };
    });
    const S = items.find(i => i.g === 's');
    const B = items.find(i => i.g === 'b');
    if(!S || !B){ mark.style.opacity = '1'; setTimeout(dismissSplash, SPLASH_HOLD); return; }

    // Where the centred "SB" pair sits inside the (final-width) mark box.
    // Each letter box carries 0.18em of invisible side-padding (so the GPU layer
    // doesn't clip italic ink). Collapse on the GLYPH widths, not the padded-box
    // widths, otherwise S and B end up ~0.36em too far apart in the held "SB".
    const total = Math.max.apply(null, items.map(i => i.left + i.w));
    const centreX = total / 2;
    const fs = parseFloat(getComputedStyle(mark).fontSize) || 64;
    const padPx = 0.18 * fs;                 // matches .spl horizontal padding
    // Kern the held "SB" INK-to-INK so it reads as one monogram, not two close
    // letters. The box advances include built-in side bearings (whitespace baked
    // into each glyph): S's right bearing ~0.031em and B's left bearing ~0.02em.
    // Subtract them so only a hair of real ink gap is left. (Measured for
    // DM Serif Display; safe even if slightly off — it just nudges the spacing.)
    const RSB_S = 0.031 * fs, LSB_B = 0.02 * fs;
    const inkGap = 0.02 * fs;                 // the small visible gap we actually want
    const gap = inkGap - RSB_S - LSB_B;       // advance-space gap (comes out negative)
    const advS = S.w - 2 * padPx;             // S advance width
    const advB = B.w - 2 * padPx;             // B advance width
    const pairW = advS + gap + advB;          // width of the tightly-kerned pair
    const colS = centreX - pairW / 2 - padPx; // S box-left (pair centred about centreX)
    const colB = colS + advS + gap;           // B box-left so B sits snug after S
    S.dx = colS - S.left;                   // how far S must glide (leftish)
    B.dx = colB - B.left;                   // how far B must glide (rightish)

    const fillers = items.filter(i => i.g === 'm' || i.g === 'o');
    fillers.sort((a, b) => a.left - b.left); // reveal left→right

    const ease = 'cubic-bezier(.22,.61,.36,1)'; // smooth ease-out, no overshoot

    // DM Serif Display's italic leans ~14°. Counter-skew B by that during the
    // held "SB" so it stands UPRIGHT (same glyph, just de-slanted), then animate
    // the skew back to 0 during the split so it leans into its natural italic.
    const UPRIGHT_SKEW = 14; // degrees
    B.el.style.transformOrigin = '50% 50%'; // pivot at the glyph's middle so the
                                            // kerned position is preserved while upright

    // 2) Collapse to "SB": only S and B visible (glided to centre); the rest
    //    hidden in place, pre-blurred and nudged down a touch. B is straightened.
    items.forEach((it) => {
      it.el.style.transition = 'none';
      if(it.g === 's'){
        it.el.style.transform = 'translateX(' + it.dx.toFixed(2) + 'px)';
        it.el.style.opacity = '1';
        it.el.style.filter = 'none';
      } else if(it.g === 'b'){
        it.el.style.transform = 'translateX(' + it.dx.toFixed(2) + 'px) skewX(' + UPRIGHT_SKEW + 'deg)';
        it.el.style.opacity = '1';
        it.el.style.filter = 'none';
      } else {
        it.el.style.transform = 'translateY(0.16em)';
        it.el.style.opacity = '0';
        it.el.style.filter = 'blur(6px)';
      }
    });
    mark.style.opacity = '1';
    mark.style.transform = 'scale(1.04)';
    void mark.offsetWidth; // commit collapsed "SB" frame

    // 3 + 4) After the beat: part S/B and materialise the rest in place.
    setTimeout(() => {
      mark.style.transition = 'transform ' + SPLASH_GLIDE + 'ms ' + ease;
      mark.style.transform = 'scale(1)';

      // S and B glide to their real positions; B also leans from upright into
      // its natural italic (skew 14deg -> 0) over the same glide.
      S.el.style.transition = 'transform ' + SPLASH_GLIDE + 'ms ' + ease;
      S.el.style.transform = 'translateX(0px)';
      B.el.style.transition = 'transform ' + SPLASH_GLIDE + 'ms ' + ease;
      B.el.style.transform = 'translateX(0px) skewX(0deg)';

      // "ummer" / "ody" focus into place with a left-to-right stagger.
      fillers.forEach((it, i) => {
        const delay = 140 + i * 34; // letters start after the split begins
        it.el.style.transition =
          'transform 540ms ' + ease + ' ' + delay + 'ms, ' +
          'opacity 440ms ease ' + delay + 'ms, ' +
          'filter 440ms ease ' + delay + 'ms';
        it.el.style.transform = 'translateY(0)';
        it.el.style.opacity = '1';
        it.el.style.filter = 'blur(0px)';
        // Once the blur-in finishes, drop the filter entirely. An *active* filter
        // (even blur(0px)) clips the glyph to its filter region, which shaved off
        // the italic "y" descender. blur(0px) -> none is visually identical, so
        // clearing it removes the clip with no visible jump. transitionend can be
        // flaky on iOS PWAs, so a timeout fallback guarantees the cleanup.
        const clearFilter = () => { it.el.style.filter = 'none'; };
        it.el.addEventListener('transitionend', function te(e){
          if(e.propertyName === 'filter'){ it.el.removeEventListener('transitionend', te); clearFilter(); }
        });
        setTimeout(clearFilter, delay + 480);
      });
    }, SPLASH_BEAT);

    // 5) Settle: once everything has reached its resting position, DE-PROMOTE the
    //    letters. While a glyph is on its own compositing layer (will-change /
    //    transform), WebKit sizes that layer's texture to the element's border box
    //    and clips any ink that overflows it — which shaved the italic "B" flourish
    //    (its ink sticks ~8px past its box). All letters are at identity here, so
    //    clearing transform/will-change is visually seamless but lets the
    //    overhanging ink paint on the normal layer, uncut.
    const fillEnd = 140 + (fillers.length - 1) * 34 + 540;
    const settleAt = SPLASH_BEAT + Math.max(SPLASH_GLIDE, fillEnd) + 80;
    setTimeout(() => {
      letters.forEach((l) => {
        l.style.transition = 'none';
        l.style.transform = 'none';
        l.style.filter = 'none';
        l.style.willChange = 'auto';
      });
      mark.style.transition = 'none';
      mark.style.transform = 'none';
      mark.style.willChange = 'auto';
    }, settleAt);

    // 6) Hold the finished wordmark, then fade out.
    setTimeout(dismissSplash, SPLASH_BEAT + Math.max(SPLASH_GLIDE, fillEnd) + SPLASH_HOLD);
  };

  // Measure only once the webfont is ready, otherwise positions are wrong.
  if(document.fonts && document.fonts.ready){
    let done = false;
    const go = () => { if(!done){ done = true; run(); } };
    document.fonts.ready.then(go);
    setTimeout(go, 700); // safety if the font promise stalls
  } else {
    run();
  }
}
function dismissSplash(){
  const el = document.getElementById('splash');
  if(!el || el.classList.contains('splash-done')) return; // guard double-fire
  // Let the wordmark drift up + dissolve a touch faster than the green layer, so
  // it melts into the app rather than the whole screen blinking off in one step.
  const mark = document.getElementById('splash-mark');
  if(mark){
    mark.style.transition = 'transform 900ms cubic-bezier(.4, 0, .2, 1), opacity 650ms ease';
    mark.style.transform = 'scale(1.05)';
    mark.style.opacity = '0';
  }
  el.classList.add('splash-done');
  setTimeout(()=>{ document.documentElement.classList.remove('show-splash'); document.documentElement.style.background = ''; }, 950);
}

// ==================== NOTIFICATION DEEP-LINK ====================
// When opened via ?log=protein / ?log=creatine (from a tapped reminder),
// jump to the Today tab and gently highlight the right block to log it.
function goToLog(which){
  if(which !== 'protein' && which !== 'creatine') return;
  const todayBtn = document.querySelector('.nav-link, .bnav-item');
  // activate the Today section
  const todayNav = document.querySelector('.nav-link');
  if(todayNav) showSection('today', todayNav);
  const targetId = which === 'protein' ? 'block-food' : 'block-creatine';
  const prompt = which === 'protein'
    ? 'Log your protein shake below 🥤'
    : 'Tick off your creatine below 💊';
  // wait a tick for the section to render, then scroll + pulse
  setTimeout(()=>{
    const target = document.getElementById(targetId);
    if(target){
      target.scrollIntoView({ behavior:'smooth', block:'center' });
      target.classList.remove('log-pulse');
      void target.offsetWidth; // restart animation
      target.classList.add('log-pulse');
      setTimeout(()=> target.classList.remove('log-pulse'), 3800);
    }
    showToast(prompt, 'info');
  }, 120);
}
function handleLaunchParam(){
  try {
    const params = new URLSearchParams(window.location.search);
    const log = params.get('log');
    if(log){
      goToLog(log);
      // tidy the URL so a refresh doesn't re-trigger
      history.replaceState(null, '', window.location.pathname);
    }
  } catch(_){}
}
// App already open: service worker tells us which reminder was tapped.
if('serviceWorker' in navigator){
  navigator.serviceWorker.addEventListener('message', (e)=>{
    if(e.data && e.data.type === 'open-log' && e.data.log){
      goToLog(e.data.log);
    }
  });
}

// Enter-key support
document.getElementById('food-input').addEventListener('keydown', e=>{ if(e.key==='Enter') parseFood(); });
document.getElementById('junk-input').addEventListener('keydown', e=>{ if(e.key==='Enter') addJunk(); });

// Init
renderWeightLog();
updateWorkoutStats();
applyShopState('sp1');
applyShopState('sp2');
updateShopProgress('sp1');
updateShopProgress('sp2');
renderSessionHistory();
updateLogSessionButton();
initSessionCardGlow();
document.documentElement.classList.add('view-today');
renderToday();
mpInit();
tpInit();
initReminders();
initAuth();
initAccountSettings();
playSplash();
handleLaunchParam();

// When the deferred Chart.js finishes loading, draw whichever chart is visible.
window.__onChartReady = function(){
  try {
    renderTodayChart();
    if(document.getElementById('sec-progress').classList.contains('active')) renderWeightChart();
  } catch(_){}
};
// In case Chart.js was already cached and fired before this handler existed.
if(typeof Chart !== 'undefined') window.__onChartReady();
