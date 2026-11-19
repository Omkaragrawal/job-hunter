# Job-site presets

Setup reads this file to propose a starting list. It takes the person's country section, adds the field extras that match their field, and lets them add or remove sites. It then copies the chosen lines into the "## Job sites" section of their profile.md, keeping only the `- Name: URL (notes)` part.

Line format: `- Name: URL (notes) [fields] [status]`
- `fields`: `all`, or a list of `tech` (software, data), `design`, `sales`, `finance`, `operations`, `healthcare`, `education`, `academic`.
- `status`: `tested` means it worked in real runs; `untested` means not yet tried. Setup tells the person which sites are untested.
- Add `feed` in the notes for a personal list with no search box; it's read in full once per run.
- `sign-in` means the site shows little or nothing until the person signs in to it in their browser.

## India
- Naukri: https://www.naukri.com/ (sign-in; profile-resume applies) [all] [tested]
- Indeed India: https://in.indeed.com/ [all] [tested]
- LinkedIn: https://www.linkedin.com/jobs/ (sign-in) [all] [tested]
- Foundit: https://www.foundit.in/seeker/dashboard (sign-in; start from the dashboard, the plain search page errored) [all] [tested]
- Instahyre: https://www.instahyre.com/ (sign-in) [tech, design, sales] [tested]
- Wellfound: https://wellfound.com/jobs (sign-in; startups) [tech, design, sales] [tested]
- HiringCafe: https://hiringcafe.com/ [all] [tested]
- JobLeads: https://www.jobleads.com/search/jobs?view=for-you (feed; sign-in) [all] [tested]
- Hirist: https://www.hirist.tech/ (sign-in to apply) [tech] [tested]
- Cutshort: https://cutshort.io/jobs (sign-in) [tech] [tested]
- Weekday: https://jobs.weekday.works/ (feed; sign-in, open Fast Apply and paste your own Fast Apply link here) [tech] [tested]

## Global / remote
- LinkedIn: https://www.linkedin.com/jobs/ (sign-in) [all] [tested]
- Indeed: https://www.indeed.com/ [all] [tested]
- Wellfound: https://wellfound.com/jobs (sign-in; startups) [tech, design, sales] [tested]
- HiringCafe: https://hiringcafe.com/ [all] [tested]
- MyGreenhouse: https://my.greenhouse.io/jobs/search (sign-in) [all] [tested]
- JobLeads: https://www.jobleads.com/search/jobs?view=for-you (feed; sign-in) [all] [tested]
- FoundRole: https://www.foundrole.com/app/recommended-jobs (feed; sign-in; the public list is mostly US jobs) [tech] [tested]
- Workopia: https://workopia.io/jobs (use a Workopia connector if the session has one) [all] [tested]

## UAE / Gulf
- LinkedIn: https://www.linkedin.com/jobs/ (sign-in) [all] [untested]
- Bayt: https://www.bayt.com/en/uae/jobs/ (sign-in to apply) [all] [untested]
- NaukriGulf: https://www.naukrigulf.com/ (sign-in; profile-resume applies) [all] [untested]
- GulfTalent: https://www.gulftalent.com/jobs (sign-in) [all] [untested]
- Indeed UAE: https://ae.indeed.com/ [all] [untested]

## US / UK / Canada
- LinkedIn: https://www.linkedin.com/jobs/ (sign-in) [all] [untested]
- Indeed (US): https://www.indeed.com/ [all] [untested]
- Indeed (UK): https://uk.indeed.com/ [all] [untested]
- Indeed (Canada): https://ca.indeed.com/ [all] [untested]
- Glassdoor: https://www.glassdoor.com/Job/ (sign-in) [all] [untested]
- Reed (UK): https://www.reed.co.uk/jobs [all] [untested]
- Job Bank (Canada): https://www.jobbank.gc.ca/jobsearch/ [all] [untested]
- MyGreenhouse: https://my.greenhouse.io/jobs/search (sign-in) [all] [untested]

## Field extras (any country)
- Dribbble Jobs: https://dribbble.com/jobs [design] [untested]
- eFinancialCareers: https://www.efinancialcareers.com/ [finance] [untested]
- Health eCareers (US): https://www.healthecareers.com/ [healthcare] [untested]
- Tes (teaching): https://www.tes.com/jobs/ [education] [untested]
- Times Higher Education Jobs: https://www.timeshighereducation.com/unijobs/ [academic] [untested]
- jobs.ac.uk (UK academic): https://www.jobs.ac.uk/ [academic] [untested]
- EURAXESS (research): https://euraxess.ec.europa.eu/jobs/search [academic] [untested]
