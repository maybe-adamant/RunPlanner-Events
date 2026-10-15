# Run Planner Events

Community events for [Run Planner](https://github.com/maybe-adamant/RunPlanner). Each event is
a planned Hades II run that every player of the planner is offered for a week or so: the app
announces it, writes it to the read-only **Event** slot in game, and names it on the victory
screen.

This repository holds the event data and the workflow that publishes it. The planner only
listens: it downloads the signed feed from this repository's `events` release and checks it with
the event public key built into the app.

## Layout

```text
events/
  <event-id>/
    event.json               # title, description, optional rules, start and end
    project.runplanner.json  # the planned run, saved from the planner
  _template/                 # an example; folders starting with _ are never published
scripts/check-local.sh       # validates every event against a local planner checkout
.github/workflows/
  validate.yml               # pull requests: validate every event folder (no secrets)
  publish.yml                # build, sign and publish the feed
```

See [events/README.md](events/README.md) to write an event.

## Publishing

`publish.yml` runs daily, on every push to `main` that touches `events/`, and by hand
(**Run workflow**, with **dry run** on by default). It:

1. checks out the planner's latest release and builds the feed with its event builder
   (`npm run events:build`), which lists every event that has not ended with its project's URL,
   hash and schema version, and compiles each project to refuse one that would not play;
2. checks the feed with the planner's own decoder;
3. stops if the published feed is identical and its signature verifies; otherwise signs
   `events.json` with the event key, verifies the signature with the planner's public key, and
   replaces each `<event-id>.runplanner.json` and then `events.json` and `events.json.sig` on the
   `events` release.

The feed carries projects, not compiled plans: each planner downloads the active event's project,
checks its hash and compiles it for the game module it installs, so a planner release needs no
republish. The planner chooses the active event by time itself, so an event starts and ends on
its dates without another publish; the daily run drops ended events from the feed. GitHub pauses
scheduled runs after 60 days without activity in this repository; a push or a manual run resumes
them.

Merging a pull request that changes `events/` publishes at once. To preview first, run the
workflow by hand on the pull request's branch with **dry run** on.

If an upload stops part way, run the workflow again: a published feed that differs or whose
signature does not verify is signed afresh and replaced.

## Owner setup

1. Generate the event key pair (once): `npx @tauri-apps/cli signer generate -w events.key`.
   Keep `events.key` and its password private and backed up.
2. Create the `events-publish` environment (Settings → Environments) with a deployment branch
   policy that allows only `main`, and add the **environment** secrets
   `EVENTS_SIGNING_PRIVATE_KEY` (the contents of `events.key`) and
   `EVENTS_SIGNING_PRIVATE_KEY_PASSWORD` there. Repository-level secrets would be reachable
   from a workflow run on any branch. Required reviewers are optional, for approval before each
   publish.
3. Put the public key (`events.key.pub`, one base64 line) in the planner repository's
   `apps/planner/src-tauri/event-feed.pub` and release the planner. Until a release ships the
   real key the publish workflow stops, and the app ignores events.
