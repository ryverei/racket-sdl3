# Commit Completed Phase

Read PLAN.md to find the most recently completed phase, then commit all changes with an appropriate message.

## Instructions

1. **Read PLAN.md** and find the most recently completed phase
   - Look for phases marked "✓ DONE"
   - The most recent is typically the last one marked done

2. **Check git status**
   - See what files have been changed
   - Verify the changes match what the phase was supposed to do

3. **Stage and commit**
   - Stage all relevant changes: `git add <files>`
   - Create commit with message format:
   ```
   Phase N: [Phase name]

   [Brief description of what was done, from the Outcome section]

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
   ```

4. **Report the commit**
   - Show the commit hash and message
   - Confirm what was committed

Example commit message:
```
Phase 1: Merges

Merged 4 pairs of similar examples:
- keyboard-events + keyboard-state → keyboard.rkt
- tint + rotate → texture-transforms.rkt
- mouse-events + mouse-warp → mouse.rkt
- shapes + geometry → drawing.rkt
```
