# Container Management

The Container Management page lets you view and manage the CIPP application container on a self-hosted instance. From here you can see which image and version are running, control the release channel, configure automatic update checks, and restart the container. It sits under the CIPP Super Admin area and is arranged as four cards.

## Container Status

This card shows read-only details about the container that is currently running.

| Field             | Description                                                        |
| ----------------- | ------------------------------------------------------------------ |
| Running Channel   | The release channel the running container was built from.          |
| Image Tag         | The tag of the running container image.                            |
| App Version       | The version of CIPP currently running.                             |
| Image Built (UTC) | The date and time the running image was built.                     |
| Commit SHA        | The source commit the running image was built from.                |
| Container Image   | The full reference of the running container image, when known.     |
| App Service       | The name of the App Service hosting the container, when available. |

Two notices can appear at the top of this card. One warns that a channel change is pending, showing the running and configured channels, when they differ and a restart is needed to apply the change. The other advises that a new image is available and that restarting will pull it.

## Update Management

This card configures how CIPP checks for new container images. CIPP queries the container registry for a new image digest and can optionally restart the container to apply the update. By default, it checks every hour and auto-restarts at 23:00.

| Setting                                 | Description                                                                                                            |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Check Interval                          | How often CIPP checks the registry for a new image: Disabled, Every hour, Every 4 hours, Every 12 hours, or Every day. |
| Preferred Check Time                    | The hour of the day, in 24-hour time, at which the check should run.                                                   |
| Auto-restart when an update is detected | When enabled, CIPP automatically restarts the container to apply an update once one is found.                          |

Select **Check Now** to run a check immediately or **Save Settings** to store the options above. The card also reports when the last check ran and whether the container is up to date, along with the running and remote versions, the remote image's build date, and the remote image digest.

Note that if the container restarts for any reason, the latest image for the current release channel is pulled regardless of these settings.

## Release Channel

This card selects which release channel the container follows. Changing the channel updates the container image tag; the new image is pulled on the next container restart.

| Channel         | Description                                                         |
| --------------- | ------------------------------------------------------------------- |
| Latest (Stable) | The stable release channel.                                         |
| Dev             | Development builds, which may include unstable or untested changes. |
| Nightly         | Nightly builds, which may include unstable or untested changes.     |

Choose a channel and select **Update Channel** to apply it. The change takes effect on the next container restart. Switching to Dev or Nightly may introduce unstable or untested changes.

### Branch builds

Below the standard channels the list may also show **Branch builds** — images built from a branch that has not been merged yet, so a change can be tested on a real instance before it ships. They are named after the branch they came from, such as `fix-sso-multi-domain` or `feat-new-report`.

A branch build tag follows its branch, in the same way `dev` and `nightly` do: if the branch is built again, the container picks up the newer image on its next restart. To hold one exact build instead, set the container image to its digest rather than its tag — the build summary in the GitHub Actions run prints the full reference to use.

Only builds that currently exist are listed, and the tag is checked before the change is saved, so a build that has already been removed cannot be selected by mistake.

Branch builds are **not supported** and are intended for testing only:

- They receive no updates, and the automatic update check does not apply to them.
- They are deleted when their branch is deleted, and swept after 30 days. Once the image is gone the container cannot start until you switch back to a standard channel — so move off a branch build as soon as you have finished testing.

Unless you have been asked to test a specific build, stay on Latest (Stable).

## Restart Application

This card restarts the application container. Select **Restart Container** to restart; this causes a brief period of downtime while the container comes back up. If you have changed the release channel or an update is pending, the new image is pulled as part of the restart.

***

{% include "../../../../../.gitbook/includes/feature-request.md" %}
