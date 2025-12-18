# Implement Next Phase

Read PLAN.md, find the first incomplete phase, implement it, and update the plan.

## Instructions

1. **Read PLAN.md** and find the first phase that hasn't been marked done
   - Look for phases without "✓ DONE" in the heading
   - Check the Execution Order section - follow that order, not numerical order

2. **Implement the phase**
   - Work through each sub-section (1.1, 1.2, etc.) in order
   - For each task, do the actual work (create files, edit code, etc.)
   - Run relevant tests after changes: `PLTCOLLECTS="$PWD:" racket <file>`

3. **Update PLAN.md** when done
   - Add "✓ DONE" to the phase heading: `## Phase 1: Merges ✓ DONE`
   - Add an **Outcome** section at the end of the phase:
   ```markdown
   **Outcome:** Completed successfully. Created keyboard.rkt combining both input approaches. All examples tested and working.
   ```
   - If there were issues or deviations from the plan, note them in the outcome
   - If blocked, add "⚠ BLOCKED" instead and explain why in the outcome

4. **Report what was done**
   - Summarize the changes made
   - List any files created, modified, or deleted
   - Note any issues encountered

Do NOT commit - that's a separate command.
