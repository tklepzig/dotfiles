# AI

## Claude

### Useful commands

- /statusline
- /usage
- /voice

### Subagents

#### Overview

- Gets its own context window (separate from the main conversation)
- Has access to tools (Read, Grep, Glob, Bash, etc.)
- Works autonomously to complete the task
- Returns a single result message when done

#### Benefits

1. Context protection — reading many large files inline would consume the main
   conversation's context window. The subagent uses its own window, so the main
   conversation stays clean.
2. Parallelism — multiple agents can run concurrently, doing independent work
   simultaneously.
3. Thoroughness — a subagent can take many tool-call steps (read, grep, compare,
   re-read) without cluttering the main response flow.

#### Invoke

- "Use a subagent to analyze X"
- "Spawn an agent to search for Y"
- "Use the Explore agent to find all usages of Z"

I'll follow that instruction. You can also specify which type of subagent if you
want (Explore, Plan, general-purpose, etc.), or just say "subagent" and I'll
pick the appropriate type based on the task.
