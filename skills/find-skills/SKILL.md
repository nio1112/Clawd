---
name: find-skills
description: "A guide for Claude/AI Agents to search and find new vercel-labs/skills on Windows. Use this skill when you need to search for new skills via 'npx skills find' to avoid empty outputs in the default Bash environment."
license: Complete terms in LICENSE.txt
---

# Find Skills (Windows Compatibility Guide)

**ATTENTION AI AGENT (Claude Code / Clawd):**

When operating on a **Windows** host, and you need to search or add skills via the `vercel-labs/skills` ecosystem (e.g., `npx skills find` or `npx skills add`), you **MUST NOT** run these commands directly in your default Bash-like terminal interface. Doing so will result in the command failing silently, yielding no output.

## Correct Usage

You must encapsulate the command using **PowerShell (`pwsh`)** to ensure successful execution. 

### Examples

**Searching for a skill:**
\`\`\`bash
# WRONG (will yield no output on Windows Bash):
npx skills find my-skill

# CORRECT (Windows compatibility):
pwsh -Command "npx -y skills find my-skill"
\`\`\`

**Adding a skill:**
\`\`\`bash
# WRONG:
npx skills add skill-creator

# CORRECT:
pwsh -Command "npx -y skills add skill-creator"
\`\`\`

Always use the `-y` flag with `npx` to auto-approve the execution prompt of the `skills` tool.

### Background
By default, the `npx skills` CLI may encounter TTY/terminal piping issues inside the AI's internal Bash environment on Windows, resulting in no terminal output. Calling it via PowerShell forces standard IO streaming that works correctly.
