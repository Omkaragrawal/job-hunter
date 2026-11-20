# job-hunter

A Claude plugin that does the busywork of applying for jobs, while you stay in charge.

- **Finds jobs** on the job sites you choose, every day if you like.
- **Tailors your resume and cover letter** for each job, using only facts from your own resume.
- **Fills in the application forms** in your browser and stops on the last page.
- **Submits only when you say so**, job by job.

Shared for friends and family. Version 0.9.2 (beta).

## What you need
- **The Claude desktop app** on Windows or Mac, with a paid Claude plan (Pro, Max, Team or Enterprise). You use its **Code** tab.
- **A Chromium browser**, such as Google Chrome, Microsoft Edge, Brave, Arc, Vivaldi or Opera, with the **Claude extension** installed and signed in: [Claude in the Chrome Web Store](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn). Firefox and Safari don't work.
- **Your resume** as a PDF (a Word file works too).

Nothing else to install.

## Install
1. Open the Claude desktop app, go to the **Code** tab and start a new session.
2. Type these two lines, one at a time, and press Enter after each:
   ```
   /plugin marketplace add Omkaragrawal/job-hunter
   ```
   ```
   /plugin install job-hunter@omkaragrawal
   ```
3. Start a new session so the plugin loads.

## Set up (about 15 minutes)
In a new Code session, type:
```
/job-hunter:setup
```
Claude asks you a few questions, reads your resume and sets everything up:
- which browser to use;
- where to keep your files;
- your resume layout: a standard template for your field, or your own design;
- your job sites and search terms;
- an optional daily search, at a time you choose, using the Claude model you choose;
- optional tracking: every application can also be kept in step with Job Toast or RoleCatcher, if you use them.

You can run setup again any time to change something.

## Everyday use
Type these in a Code session:

| You type | What happens |
|---|---|
| `find jobs` | Searches your sites, prepares tailored applications and fills the forms. |
| `apply to <link>` | Prepares one job from a link. |
| `review my applications` | Shows everything waiting for you. |
| `submit 1, 3` | Submits jobs 1 and 3. Nothing is ever submitted without this. |
| `done 4` | You finished a step Claude handed you on job 4 (a CAPTCHA, a sign-in, an upload). |

While a search runs:
- Claude never waits on one stuck job. When it needs you, it writes a line starting with ⏸ and moves on to the next job.
- Keep the tab called **⚓ KEEP OPEN · Claude job run** open. You can close any other tab.

## Safety and privacy
- **Nothing is submitted without your "submit".** Sign-ins, passwords, CAPTCHAs, consent boxes and anything that costs money are always left to you.
- **Only your facts.** Resumes and answers come only from your own resume and profile. Claude never invents skills or numbers.
- **Job pages can't give it orders.** If a job posting tries to instruct the AI, Claude shows it to you and ignores it.
- **Your data stays on your computer**, in the folder you picked during setup. This repo holds none of it.
- **Site rules:** some job sites, LinkedIn among them, don't allow automation tools. job-hunter works at a human pace, but use it at your own judgement.

## Updating
New versions come out from time to time. To get the latest, type:
```
/plugin marketplace update omkaragrawal
```
Or open `/plugin`, go to **Marketplaces**, and turn on auto-update for omkaragrawal.

## If something goes wrong
- **"Extension not connected":** open your browser, check the Claude extension is installed and signed in with the same Claude account, then run `/job-hunter:setup` again and choose to change the browser.
- **The daily search didn't run:** the Claude app must be open at that time. If it was closed, the search runs the next time you open the app.
- **The daily search stopped and asked for permission:** open the task under **Scheduled**, click **Run now** once and approve the tools. Later runs won't ask again.
- **A site found nothing:** many sites only show jobs when you're signed in. Sign in to them in your browser. The run's summary lists which sites were blocked and why.
