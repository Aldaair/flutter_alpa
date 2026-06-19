# Skill Registry — flutter_alpa

<!-- Auto-generated SDD init artifact. Regenerate when installed or project skills change. -->

Last updated: 2026-06-17

## Sources scanned

- /Users/aldair/.config/opencode/skills
- /Users/aldair/.copilot/skills
- /Users/aldair/Desktop/Proyectos/flutter_alpa/AGENTS.md

## Contract

**Delegator use only.** This registry is an index, not a summary. `SKILL.md` remains the source of truth and must be read from the exact path before work starts.

Project-specific registry-resolved standards are not available in this repo today. Use installed user-level skills plus repo convention files.

## Skills

| Skill | Trigger / description | Scope | Path |
| --- | --- | --- | --- |
| `branch-pr` | Create Gentle AI pull requests with issue-first checks. Trigger: creating, opening, or preparing PRs for review. | user | `/Users/aldair/.config/opencode/skills/branch-pr/SKILL.md` |
| `chained-pr` | Trigger: PRs over 400 lines, stacked PRs, review slices. Split oversized changes into chained PRs that protect review focus. | user | `/Users/aldair/.config/opencode/skills/chained-pr/SKILL.md` |
| `cognitive-doc-design` | Design docs that reduce cognitive load. Trigger: writing guides, READMEs, RFCs, onboarding, architecture, or review-facing docs. | user | `/Users/aldair/.config/opencode/skills/cognitive-doc-design/SKILL.md` |
| `comment-writer` | Write warm, direct collaboration comments. Trigger: PR feedback, issue replies, reviews, Slack messages, or GitHub comments. | user | `/Users/aldair/.config/opencode/skills/comment-writer/SKILL.md` |
| `go-testing` | Trigger: Go tests, go test coverage, Bubbletea teatest, golden files. Apply focused Go testing patterns. | user | `/Users/aldair/.config/opencode/skills/go-testing/SKILL.md` |
| `issue-creation` | Create Gentle AI issues with issue-first checks. Trigger: creating GitHub issues, bug reports, or feature requests. | user | `/Users/aldair/.config/opencode/skills/issue-creation/SKILL.md` |
| `judgment-day` | Trigger: judgment day, dual review, adversarial review, juzgar. Run blind dual review, fix confirmed issues, then re-judge. | user | `/Users/aldair/.config/opencode/skills/judgment-day/SKILL.md` |
| `skill-creator` | Trigger: new skills, agent instructions, documenting AI usage patterns. Create LLM-first skills with valid frontmatter. | user | `/Users/aldair/.config/opencode/skills/skill-creator/SKILL.md` |
| `skill-improver` | Trigger: improve skills, audit skills, refactor skills, skill quality. Audit and upgrade existing LLM-first skills. | user | `/Users/aldair/.config/opencode/skills/skill-improver/SKILL.md` |
| `work-unit-commits` | Plan commits as reviewable work units. Trigger: implementation, commit splitting, chained PRs, or keeping tests and docs with code. | user | `/Users/aldair/.config/opencode/skills/work-unit-commits/SKILL.md` |

## Project Convention Files

| File | Role |
| --- | --- |
| `/Users/aldair/Desktop/Proyectos/flutter_alpa/AGENTS.md` | Repo snapshot, verified Flutter commands, SDK constraint caveat, app/data-flow guidance, and codebase gotchas. |

## Loading Protocol

1. Match task context and target files against the `Trigger / description` column.
2. Pass only matching `SKILL.md` paths under `## Skills to load before work`.
3. Load repo convention files alongside the selected skills when project rules matter.
4. If no matching skill exists, proceed without project skill injection and report `skill_resolution: none`.
