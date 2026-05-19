# Overview

AI-SDLC skills and general-purpose skills that I use everyday.

# Install in a repo

## Option 1: `npx marketplace add` + `npx skills install`

Add this repo as a skills marketplace, then install a specific skill from it into the current repository:

```sh
npx marketplace add sathish316-skills github:sathish316/skills
npx skills install sathish316-skills/brainstorm-feature
```

## Option 2: Git submodule + symlink all skills

Add this repo as a submodule, then symlink every skill into your repo's `.agents/skills` directory:

```sh
git submodule add https://github.com/sathish316/skills.git .agents/skill-repos/sathish316-skills
mkdir -p .agents/skills
for skill in .agents/skill-repos/sathish316-skills/skills/*; do ln -s "../skill-repos/sathish316-skills/skills/$(basename "$skill")" ".agents/skills/$(basename "$skill")"; done
```

## Option 3: Git submodule + symlink a specific skill

Add this repo as a submodule, then symlink only the skill you want:

```sh
git submodule add https://github.com/sathish316/skills.git .agents/skill-repos/sathish316-skills
mkdir -p .agents/skills
ln -s ../skill-repos/sathish316-skills/skills/brainstorm-feature .agents/skills/brainstorm-feature
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
