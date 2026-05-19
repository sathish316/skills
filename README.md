# Overview

AI-SDLC skills and general-purpose skills that I use everyday.

# Install skill in a repo or globally

Install a specific skill from this repo

```sh
npx skills@latest add sathish316/skills --skill brainstorm-feature
```

Install all skills from this repo

```sh
npx skills@latest add sathish316/skills --skill '*'
```

# Usage

## For large features ([flowchart](docs/devskills-decision-tree-flowchart.md))

1. /write-prd
2. /prd-to-rfc (Optional if Tech design doc is needed)
3. /prd-to-issues
4. /issue-to-tasks (Optional if the issue is large enough to be broken down into tasks)
5. *code* each issue or task (Just prompt or use implement-* skills)
6. /code-simplify
7. /code-review
8. /final-review-and-create-pr

## For medium/small features ([flowchart](docs/devskills-workflow-flowchart.md))

1. /brainstorm-feature
2. /feature-to-rfc (Optional if Tech design doc is needed)
3. /feature-to-issues
4. /issue-to-tasks (Optional if the issue is large enough to be broken down into tasks)
5. *code* each issue or task (Just prompt or use implement-* skills)
6. /code-simplify
7. /code-review
8. /finish-work-*-and-create-pr (for each issue or task if needed) 
9. /apply-pr-comments (for each issue or task if needed)

## For minor features

1. Just ask the agent to *code* the feature
2. /code-simplify
3. /code-review
4. /create-pr

# Resources

Other similar skills resources:
* https://github.com/addyosmani/agent-skills
* https://github.com/mattpocock/skills
* https://github.com/maiobarbero/my-ai-workflow
* https://github.com/obra/superpowers
* https://github.com/garrytan/gstack

# Skill-specific docs

## Codewiki skill

Install codewiki skills in a repo:

```sh
npx skills@latest add sathish316/skills --skill codewiki
npx skills@latest add sathish316/skills --skill codewiki-viewer
```

Ask your Coding agent to generate and serve Codewiki

```
Use codewiki skill to generate comprehensive documentation for this repo.
```

```
Use codewiki-viewer skill to serve html documentation
```