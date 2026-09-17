# Publishing Filter

Use this document as the owning rulebook for every entry published on the site. `AGENTS.md` `## Project Rules` carries the gates. This file carries the rules, their rationale, and the detectors behind `check.sh`. Positions the site holds live in `stance-register.md`.

## Purpose

- Apply this filter to every entry created or edited under `life/`, `mind/`, `society/`, or `tech/`, and to the root site pages `about.md` and `index.md`.
- Apply `## Triage` to every raw thought the Director offers as a candidate entry.
- Pass every rule below before an entry counts as implementation-complete.
- Treat the site as how the author sees the world: a short first-person take supported by external references, or a practical how-to, never a full treatment.
- Prefer removing text over explaining it when an entry exceeds its budget.

Note: the site is public and attributable through its GitHub repository. Anonymity is not the defense. Accuracy, fairness, and brevity are.

## Entry Types And Budgets

- Declare exactly one `type` in front matter on every entry: `take`, `note`, `howto`, `reference`, or `quote`.
- Keep a `take` to 250 prose words.
- Keep a `note` to 400 prose words.
- Keep a `howto` to 500 prose words.
- Keep a `quote` to 300 words including the quoted text.
- Keep a `reference` skimmable, with no prose cap.
- Count prose words after removing front matter, fenced code blocks, and HTML comments.
- Split an entry that cannot meet its budget into two entries with one topic each.
- Treat a missing `type` as `note` during the site-wide sweep only.
- Update the About paragraph when a kind or its cap changes.

Note: a `take` is opinion on a subject, a `note` is an explainer, a `howto` is steps to a result, a `reference` is a cheat-sheet or list, a `quote` is a collection of other people's words. Anything longer than these budgets reads like an encyclopedia entry, and Wikipedia already does that better.

## Privacy

- Publish no real name of the author or of a private individual.
- Publish no handle derived from a real name.
- Publish no credential, token, key, or password, even one that is expired or was never real.
- Publish no device identifier: serial number, hardware UUID, MAC address, or USB device ID.
- Publish no employer name, employer domain, internal hostname, job name, or internal URL.
- Publish no private network detail beyond generic RFC1918 examples.
- Publish no home-folder layout: no path to a non-default folder under `~` or `$HOME`, and no iCloud Drive path.
- Publish no personal health, family, or location detail.
- Publish no first-person account of the author's mental health or emotional distress.
- Mark a flagged line the Director has approved with `<!-- private-ok -->`.
- Add that marker only on the Director's explicit decision for that line.
- Replace each removed value with a placeholder in the site's `<NAME>` or `mydomain.com` style, inside a code span or fence.
- Keep an exact year that narrows the author's age out of first-person sentences; use a decade instead.
- Keep the private denylist outside the repository at `~/.config/bits/denylist.txt` or at the path in `BITS_DENYLIST`.
- Keep one literal per denylist line.
- Add every newly found personal literal to the denylist before the entry ships.
- Treat the site's own `kquo` and `queone` handles as allowed.
- Treat attribution through the GitHub repository as accepted, not as a leak.

Note: the two blood-pressure pages stay. A generic health how-to is not personal health detail. A stated preference or ranking is not an account of distress. This section is class-based on purpose. Naming an instance here would publish it. Blank lines and lines starting with `#` in the denylist are ignored.

## Voice

- Write a reflective entry as one continuous first-person argument under its page title.
- Write each reflective entry as how the author sees the subject, not as a report on it.
- Write every `take` and `note` in plain English: short sentences and common words.
- Keep a `take` or `note` near 16 words per sentence or fewer.
- Show the reader the thing itself instead of announcing that you will discuss it.
- Prefer a concrete noun and an active verb over an abstract noun made from a verb.
- Define each term and spell out each abbreviation where it first appears.
- Put a sentence's heaviest phrase at its end, not in its middle.
- Open a sentence with what the reader already knows, then add the new point.
- Write every sentence complete and grammatically correct.
- Make each sentence follow from the one before it, so a paragraph reads as one line of thought in the author's voice.
- Open with one grounding sentence in that same voice.
- Carry the general reference, usually Wikipedia, as an inline link where the concept first appears.
- Use external links to support the argument, never as a detached summary of what others say.
- Use no heading that labels a passage as opinion, such as `My take`, `Opinion`, `Thoughts`, or `Verdict`.
- Use a `###` heading only to separate distinct sub-topics, steps, or reference sections.
- Prefer no internal heading in a `take`.
- Condense AI-drafted text into that shape before publishing any of it.
- Use no section headed Conclusion, Final Thoughts, Bottom Line, Key Insight, Summary, Question, or Answer.
- Publish no question-and-answer transcript.
- Write every entry in English.
- Quote a non-English source in the original only inside a block quote, followed by an English rendering.
- Publish no placeholder such as NEEDS REWRITE, need link, Need sources, Needs clean up, TODO, FIXME, or TBD.
- Write a how-to as the shortest sequence of steps that reaches the result.

Note: the banned headings are the fingerprint of an unedited machine draft. The text under them is usually the only part worth keeping. The question-form and Spanish-prose detectors in `check.sh` back the transcript and English rules. The five sentence-level rules after the length rule follow The Sense of Style, and `mind/sense-of-style.md` explains them.

## Fairness And Corrections

- Criticize positions and actions, never mental states.
- Use no psychiatric or medical characterization of a named person.
- State the strongest version of a view before disagreeing with it.
- Apply no blanket moral label to a group.
- Name a living person only for what that person said or did in public.
- Source every factual claim about a named person.
- State each such claim no more strongly than its source supports.
- Fix or cite a disputed claim in the next release.
- Keep the corrections channel on `about.md` pointing at the repository's Issues page.

Note: the entries on the Principle of Charity, Hanlon's Razor, and Bulverism already state this standard. This section makes the site hold itself to it. A sourced fact plus a judgment plainly in the author's own voice is the defensible stance. A diagnosis of a stranger is not.

## Consistency And The Stance Register

- Record every settled position in `stance-register.md` as one line with its owning entry.
- Check every stance-bearing claim in a changed entry against the register before Implement completion.
- Match, extend, or explicitly supersede the registered line; never contradict it silently.
- Return to Refine when a changed entry contradicts a registered line.
- Record a new or changed position in the register in the same pass as the entry.
- Mark a position `unresolved` when two entries disagree.
- Settle each `unresolved` line with the Director before either entry ships again.
- Keep each register row's key terms present in its owning entry, or reword the row.
- Run `./check.sh --register` after every register edit.

Note: the register is what turns "no contradictions" from a one-time review into an ongoing check.

## Linking And Repetition

- Give each concept one owning entry.
- Link to the owning entry instead of restating the concept.
- Use a repo-relative path for every internal link.
- Use no absolute `que.one` URL inside the site.
- Add an inbound link from at least one related entry when a new entry ships.
- Keep each area index listing every entry in its directory.

Note: the 2026-09-03 review found attention-economy mechanics explained in six entries and the reflexivity limitation in five. Each should be one page and five links.

## Accuracy And Sourcing

- Source every contested factual claim.
- Write every fact-claiming entry as defensibly as its sources allow.
- State every factual claim no more strongly than its source supports.
- Prefer Wikipedia or a primary source over commentary.
- Attribute every quotation to a person and a source.
- Mark a quotation `attributed` when its source cannot be verified.
- Remove a quotation that is documented as misattributed.
- State a consensus claim such as "most would say" only with a source.
- Date a time-sensitive claim in text instead of using words like recently or nowadays.

## Link Stability

- Store the final URL, never a redirecting alias.
- Link a release page or listing, never a version-specific download asset.
- Link no private repository page.
- Reference only the `queone` GitHub organization.
- Resolve every relative link and anchor before an entry ships.
- Fetch every external URL before an entry ships.
- Verify the fragment of an external link against the target page.
- Retry a rate-limited fetch before reporting it.
- Rewrite a link whose target now redirects to a different path.
- Verify a host on the bot-block allowlist in a browser.
- Run the site-wide link sweep monthly through the scheduled workflow, and on demand.
- Fix the findings of the monthly link sweep in the next release.

Note: the allowlist covers hosts that reject scripted requests: Stack Overflow and Stack Exchange, Medium, congress.gov, SAGE, Politico, devgenius, Human Rights Watch, and GRC. Liveness decays between releases, which is why the sweep repeats.

## Code Hosting

- Host no executable code on the site.
- Keep every script under `scripts/` in the `queone/gkit` repository and link to it.
- Write download commands as `curl -L` against `https://github.com/queone/gkit/raw/main/scripts/<file>`.
- Keep a fenced block on a `take`, `note`, `howto`, or `quote` entry to 40 lines or fewer.
- Tag every fenced block with a language, or `text` for plain output.
- Show a snippet inline only when reading it is the point of the entry.

## Triage

- Apply this section when the Director offers a raw thought as a candidate entry.
- Judge one thought per pass.
- State the thought's key point in one sentence before the verdict.
- Search the existing entries for an owner of the concept before judging the thought.
- Test the thought against `## Purpose`, `## Entry Types And Budgets`, `## Linking And Repetition`, and `## Consistency And The Stance Register` as if the entry were already written.
- Weigh whether the entry could meet `## Privacy`, `## Fairness And Corrections`, and `## Accuracy And Sourcing` with sources that exist.
- Require the entry to tell a reader something an encyclopedia page or a first search result does not.
- Require the entry to stay worth reading a year from now.
- Return exactly one verdict: `Publish`, `Merge`, `Park`, or `Drop`.
- Lead the reply with the verdict and the one reason that decided it.
- Propose a directory, a `type`, and a working title for every `Publish`.
- Name the target entry for every `Merge`.
- State what would turn a `Park` into a `Publish`.
- Write no entry during triage.
- Log a verdict in `triage-log.md` only after the Director confirms or overrides it.
- Log every confirmed verdict, including `Drop`.
- Write each log label as a short neutral phrase that passes `## Privacy`.
- Keep the raw thought out of the repository.
- Fill a row's entry path when its entry ships.

Note: triage is this filter run early, on a thought instead of a draft. The voice, link, code, and check rules need text, so they wait for the draft. The repository is public, which is why the log carries labels and the Director keeps the raw captures. A kept `Drop` row is how a repeated thought gets recognized weeks later.

## Check Command

- Run `./check.sh` on every changed entry before Implement completion.
- Run `./check.sh` on the release's changed entries and `./check.sh --no-net --all` during Package prep, and report both failing-entry counts.
- Run `./check.sh --all` monthly through `.github/workflows/link-sweep.yml`; findings land in the Link sweep issue.
- Run `./check.sh --selftest` after every change to `check.sh`.
- Treat any non-warning finding in a changed entry as blocking.
- Treat a warning as a review prompt, not a failure.

Detector codes. Privacy: `P-GUID`, `P-SSH`, `P-HEX`, `P-MAC`, `P-EMAIL`, `P-PATH`, `P-ORG`, `P-DENY`, `P-SELF`. Warnings: `W-YEAR`, `W-PERSONAL`, `W-NAME`, `W-PLAIN`, `W-ZOMBIE`, `W-ANCHOR`, `W-STALE`, and the informational `W-DENY`, `W-TYPE`, `W-EXT`. Budgets: `B-TYPE`, `B-WORDS`, `B-FENCE`. Links: `L-REL`, `L-ANCHOR`, `L-ABS`, `L-EXT`. Structure: `X-MARKER`, `X-HEADING`, `X-LANG`, `X-QA`, `X-FENCE`. Index: `I-INDEX`. Register: `R-PATH`. Privacy and link checks run on every checked file. Budget, fence, marker, heading, and index checks run only on entries and the root site pages. The plain-English warning measures mean words per sentence over prose lines, with front matter, fences, block quotes, headings, table rows, link targets, and code spans removed, and with initials and common abbreviations not counted as sentence ends. The name warning skips the product names in its allow-list. The Spanish check fires on a line with four distinct Spanish words or a sentence with three. The question-form check also flags a paragraph that is nothing but a question. The anchor warning skips a fragment that starts with `/` or `!`, which is a client-side route. A fetch with no answer at all is retried once before it counts as dead. The stale-owner warning takes the first five letters of each word of five letters or more in a register row, minus common function words, and fires when fewer than half of them start a word in the owning entries. `CHANGELOG.md` is exempt from `P-ORG` because its historical rows are immutable.

`P-PATH` covers an absolute home directory path, a home-folder layout (a non-default folder under `~` or `$HOME`), and an iCloud Drive path. Apple's default folders and `bin` are allowed.

`P-SELF` blocks a line that holds both a first-person word and a keyword for mental or emotional health, such as a mood, a treatment, or a feeling of not belonging. A line that carries the `<!-- private-ok -->` marker is exempt. The detector matches vocabulary, not meaning, so a disclosure in plain words still needs a reader to catch it.

`L-EXT` also covers bare `github.com/queone` and `raw.githubusercontent.com/queone` URLs inside fenced blocks and code spans, so download commands are checked too. The `github.com/<owner>/<repo>/raw/` redirect form is not reported as moved.

`W-ZOMBIE` warns a `take` or `note` whose nominalization rate passes five per hundred prose words, lists the counted words, and never blocks.

## Self-Enhancement

- Record each filter gap found in a closure audit as an `IE<N>:` item in `plan.md` in the same completion report.
- Add a detector to `check.sh` for every leak class found in an entry, in the same pass that fixes the entry.
- Add the literal of every personal leak found to the private denylist.
- Review this document at every Package for a rule that failed to prevent a finding.
- Propose a triage rule change when the Director overrides a verdict for a reason `## Triage` lacks.
- Retire a rule only through a Director decision.
