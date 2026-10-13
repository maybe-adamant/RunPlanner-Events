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

1. reads `module-build.json` from the planner's latest release, which names the game module
   build that release ships;
2. checks out the planner at that release and compiles every event that has not ended through
   the planner's own event builder (`npm run events:build`), so plans match what that app and
   game module accept;
3. keeps the plans the published feed already carries for older module builds (after verifying
   that feed's signature), so players who have not updated keep the event;
4. stops if the feed is unchanged; otherwise signs `events.json` with the event key and replaces
   `events.json`, `events.json.sig` and each `<event-id>.runplanner.json` on the `events`
   release.

The planner chooses the active event by time itself, so an event starts and ends on its dates
without another publish. Run the workflow by hand after a planner release so new versions get
plans without waiting for the daily run, or have the planner's release send a
`planner-release` repository dispatch here (that needs a token with access to this
repository, which the planner's workflows do not hold today). GitHub pauses scheduled runs
after 60 days without activity in this repository; a push or a manual run resumes them.

Merging a pull request that changes `events/` publishes at once. To preview first, run the
workflow by hand on the pull request's branch with **dry run** on.

### Recovering a failed publish

The feed and its signature are uploaded together after the project files. If an upload stops
part way, the published `events.json` and `events.json.sig` may not match, and the next run
fails its verification on purpose rather than drop older builds' plans. Download the
`event-feed-signed` artifact of the run that failed and upload both files again:

```sh
gh release upload events events.json events.json.sig --clobber
```

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
