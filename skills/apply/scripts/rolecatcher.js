// RoleCatcher helpers for job-hunter. Paste this whole file into javascript_tool on
// https://app.rolecatcher.com/jobs/ (My Jobs, Kanban view). Then call, one job per call or a few at a time:
//   await rcAdd({col: 'Applied', title, emp, loc, url, date: 'YYYY-MM-DD'})  -> "saved ..." or "FAIL ..."
//     col: Shortlisted | Applying | Applied | Interview. Give date only for Applied / Interview jobs.
//     Add dryRun: true to fill and pick the date, then cancel without saving.
//   await rcCheck(title)  -> "<title> -> <Date Applied as RoleCatcher shows it>"
// RoleCatcher's date picker ignores typed dates (a typed 11/18/2026 was saved as 1 Jan 2026), so rcAdd opens
// the real picker and clicks the day, then checks the picker's stored ISO date before saving.
// Don't add jobs to "Applying": RoleCatcher stamps today as Date Applied there.
const sleep = ms => new Promise(r => setTimeout(r, ms));
const set = (el, v) => { el.value = v; el.dispatchEvent(new Event('input', {bubbles: true})); el.dispatchEvent(new Event('change', {bubbles: true})); };
const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const pickerHeader = () => document.querySelector('#ui-datepicker-div .ui-datepicker-title')?.innerText.replace(/\s+/g, ' ').trim();

window.rcAdd = async (j) => {
  const btn = [...document.querySelectorAll('button')].find(b => (b.getAttribute('aria-label') || b.title || b.textContent.trim()) === 'Add to ' + j.col && b.offsetParent !== null);
  if (!btn) return 'FAIL no "Add to ' + j.col + '" button (is the Kanban view open?)';
  btn.click(); await sleep(1500);
  const f = document.getElementById('add-form');
  if (!f) return 'FAIL add form did not open';
  set(f.role_title, j.title); set(f.company_external_name, j.emp); set(f.location, j.loc || ''); set(f.external_url, j.url || '');
  document.querySelectorAll('.ui-autocomplete').forEach(m => m.style.display = 'none');
  let iso = '';
  if (j.date) {
    const [y, m, d] = j.date.split('-').map(Number);
    const want = MONTHS[m - 1] + ' ' + y;
    f.querySelector('a[href="#create-add-milestones-tab"]')?.click(); await sleep(400);
    f.date_applied.parentElement.querySelector('button').click(); await sleep(500);
    for (let k = 0; k < 24 && pickerHeader() !== want; k++) {
      const [hm, hy] = (pickerHeader() || '').split(' ');
      const back = Number(hy) * 12 + MONTHS.indexOf(hm) > y * 12 + m - 1;
      document.querySelector('#ui-datepicker-div .ui-datepicker-' + (back ? 'prev' : 'next'))?.click(); await sleep(250);
    }
    if (pickerHeader() !== want) return 'FAIL picker shows ' + pickerHeader() + ', wanted ' + want;
    const day = [...document.querySelectorAll('#ui-datepicker-div td a')].find(a => a.textContent.trim() === String(d));
    if (!day) return 'FAIL no day ' + d + ' in picker';
    day.click(); await sleep(400);
    iso = f.date_applied.getAttribute('data-iso-date') || '';
    if (iso !== j.date) return 'FAIL picker stored ' + iso + ', wanted ' + j.date;
  }
  if (j.dryRun) {
    [...f.querySelectorAll('button')].find(b => b.textContent.trim() === 'Cancel')?.click(); await sleep(800);
    return 'dry run ok ' + j.emp + ' | ' + j.col + ' | ' + iso;
  }
  f.querySelector('button[type=submit]').click(); await sleep(3500);
  const open = document.getElementById('add-form')?.closest('.modal')?.classList.contains('show');
  return (open ? 'FAIL dialog still open ' : 'saved ') + j.emp + ' | ' + j.col + ' | ' + iso;
};

window.rcCheck = async (title) => {
  const card = [...document.querySelectorAll('[aria-label^="Open record: "]')].find(c => c.getAttribute('aria-label') === 'Open record: ' + title);
  if (!card) return 'NO CARD ' + title;
  card.click(); await sleep(2500);
  const dlg = document.querySelector('.modal.show');
  const tab = dlg && [...dlg.querySelectorAll('a,button')].find(x => x.textContent.trim() === 'Milestones' && x.offsetParent);
  if (tab) { tab.click(); await sleep(1200); }
  const txt = dlg ? dlg.innerText.replace(/\s+/g, ' ') : '';
  const applied = (txt.match(/Date Applied (?:Recorded )?(\w+day, \w+ \d+, \d{4})/) || [])[1] || 'not set';
  const close = dlg && [...dlg.querySelectorAll('button')].find(b => /close/i.test(b.getAttribute('aria-label') || b.title || ''));
  if (close) { close.click(); await sleep(1200); }
  return title + ' -> ' + applied;
};
'rolecatcher helpers loaded';
