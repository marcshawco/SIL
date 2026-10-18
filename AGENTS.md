# AGENTS.md

## Project Operating Rules

These rules must be followed whenever working on this project.

## Branch Rules

- Always work on the `main` branch.
- Before making changes, confirm the current branch is `main`.
- If currently on another branch, switch back to `main` before continuing.
- Do not create feature branches unless explicitly instructed.

## Versioning Rules

- Whenever code, design, configuration, or project behavior changes, update the application version and/or build number.
- The version/build update should be proportional to the change:
  - Patch/build increase for bug fixes, small UI updates, copy changes, refactors, or minor improvements.
  - Minor version increase for new features, meaningful UX changes, new screens, new flows, or new integrations.
  - Major version increase only for breaking changes, major architecture changes, or large product direction changes.
- Do not leave the version/build number unchanged after meaningful project changes.

## README Rules

- Update `README.md` whenever significant changes are made.
- Significant changes include:
  - New features
  - Changed setup instructions
  - Changed environment variables
  - Changed commands
  - Changed architecture
  - Changed dependencies
  - Changed deployment process
  - Changed product behavior

## Git Rules

- Always commit completed changes.
- Always push committed changes to the remote repository.
- Use clear commit messages that describe the actual change.
- Before committing, review the changed files.
- Do not commit secrets, API keys, credentials, local environment files, or generated junk files.
- If committing or pushing fails because of permissions, authentication, missing remote configuration, merge conflicts, or another Git issue, stop and explain the blocker.

## Completion Checklist

Before saying the task is complete:

1. Confirm the work was done on `main`.
2. Update the version/build number if changes were made.
3. Update `README.md` if the change was significant.
4. Run relevant checks when possible.
5. Commit the changes.
6. Push the changes.
7. Summarize:
   - What changed
   - Version/build update made
   - README update made, if applicable
   - Commit message used
   - Push status

## Chat Response Style

When responding to the user in chat:

* Keep responses brief and easy to read.
* Write at about an 8th-grade reading level.
* Use simple words and short sentences.
* Avoid jargon unless it is needed.
* If jargon is needed, explain it in plain English.
* Do not over-explain unless asked.
* Use bullets when they make the answer easier to scan.
* Be direct about what changed, what failed, and what needs attention.
* Final responses should usually include only:

  * What changed
  * Files changed
  * Checks run
  * Commit/push status
  * Any blockers


## Ambiguous Request Rules

If the user gives instructions that are vague, unclear, or open to multiple interpretations:

* Do not guess and make major changes without checking first.
* Ask clear follow-up questions before continuing.
* Keep the questions brief and easy to answer.
* Provide multiple-choice options when possible.
* Explain the main paths the request could take.
* Recommend the best option if one path seems clearly better.
* If the change is small and low-risk, make the safest reasonable choice and explain the assumption.

When asking for clarification, use this format:

```md
I can take this a few different ways:

A. [Option 1] — [simple explanation]
B. [Option 2] — [simple explanation]
C. [Option 3] — [simple explanation]

My recommendation: [best option]

Which direction do you want?
```

Do not ask vague questions like “What do you want me to do?”

Instead, give the user useful options.

## Agent Work Log Rules

Maintain a local-only file called `AGENT_LOG.md`.

After every meaningful task, update `AGENT_LOG.md` with a brief record of what was done.

Each entry should include:

* Date
* Request summary
* Files changed
* Version/build change
* README updated: yes/no
* Tests/checks run
* Commit message
* Push status
* Notes, blockers, or risks

Keep entries brief and easy to read.

Do not include secrets, API keys, tokens, passwords, private customer data, or sensitive information in `AGENT_LOG.md`.

If `AGENT_LOG.md` does not exist, create it.

If `AGENT_LOG.md` is not ignored locally, add it to `.git/info/exclude`.

Do not commit `AGENT_LOG.md` unless the user explicitly asks.
