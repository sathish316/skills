# Overview

AI-SDLC skills and general-purpose skills that I use everyday.

# Setup - Coding agents that support .agents/skills

# Setup - Claude code

# Usage

## For large features

1. /write-prd
2. /prd-to-rfc (Optional if Tech design doc is needed)
3. /prd-to-issues
4. /issue-to-tasks (Optional if the issue is large enough to be broken down into tasks)
5. *code* each issue or task (Just prompt or use implement-* skills)
6. /code-simplify
7. /code-review
8. /final-review-and-create-pr

## For medium/small features

1. /brainstorm-feature
2. /feature-to-rfc (Optional if Tech design doc is needed)
3. /feature-to-issues
4. /issue-to-tasks (Optional if the issue is large enough to be broken down into tasks)
5. *code* each issue or task (Just prompt or use implement-* skills)
6. /code-simplify
7. /code-review
8.1 /finish-work-*-and-create-pr (for each issue or task if needed) 
8.2 /apply-pr-comments (for each issue or task if needed)
8.3 /final-review-and-create-pr (for all issues or tasks of a feature)

## For minor features

1. Just ask the agent to *code* the feature
2. /code-simplify
3. /code-review
4. /create-pr

# Resources

Other similar skills resources:
* https://github.com/addyosmani/agent-skills
* https://github.com/mattpocock/skills
* https://github.com/maiobarbero/my-ai-workflow/tree/main/skills
* https://github.com/obra/superpowers