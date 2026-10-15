# Writing an event

1. **Plan the run in Run Planner.** Make it complete: every room planned and no findings left,
   so the planner would let you send it to the game. Save it, then copy the saved file into a
   new folder here as `events/<event-id>/project.runplanner.json`. Players can open this project
   from the event notice as an unsaved copy.
2. **Write `events/<event-id>/event.json`:**

   ```json
   {
     "id": "2026-w42-staff",
     "title": "Week 42: Staff sprint",
     "description": "What the run asks of players.",
     "rules": "Optional extra rules.",
     "startsAt": "2026-10-12T00:00:00Z",
     "endsAt": "2026-10-19T00:00:00Z"
   }
   ```

   - `id` equals the folder name: lower-case letters, digits and single hyphens, at most 64
     characters.
   - `title` is one line of at most 80 characters; `description` and `rules` at most 2000
     characters each. No invisible formatting characters.
   - Times are UTC (`Z`). The event is active from `startsAt` until just before `endsAt`; if two
     overlap, the later start wins. Ended events are not published.
   - No other fields: the project's URL, hash and schema version are added when the feed is
     built.

3. **Check it locally** (optional): `scripts/check-local.sh <path-to-RunPlanner-checkout>`.
4. **Open a pull request.** The validation check compiles every event with the planner's latest
   release. Once merged, the publish workflow builds, signs and publishes the feed.

## What players receive

The feed lists each event with its project's URL, SHA-256 hash and `schemaVersion`; it holds no
compiled plans. Each planner downloads the active event's project, checks its hash and compiles
it for the game module it installs, so the event keeps working across planner and module
releases.

A planner plays an event only when the project's `schemaVersion` is within the range that
planner loads. A project saved by a newer planner than a player has asks that player to update
the planner first, so save event projects with a released planner, not a development build.

`_template/` holds an example `event.json` and an empty starting project; folders whose name
starts with `_` are never published.
