# codex-docker

A small Docker setup for running the Codex CLI inside an Ubuntu container with persistent local storage.

## What Persists

Docker Compose uses named volumes:

- `workspace-data` -> `/workspace`: files and repos you create or edit
- `codex-home` -> `/root/.codex`: CLI config, auth, sessions, logs, skills, and state
- `cache-data` -> `/root/.cache`: tool caches

Those volumes survive container restarts and recreates. Kubernetes uses matching PVCs under `k8s/`.

## Included Tools

The image installs a small base developer toolchain from `docker/apt-packages.txt`, including Git, GitHub CLI, curl, jq, ripgrep, build tools, Python, Node.js, npm, editors, SSH client, zip/unzip, and shell utilities.

The container runs as `root`, so tools can also be installed interactively:

```bash
apt-get update
apt-get install -y htop make
```

Interactive system package installs survive a normal container restart, but they do not survive a Compose recreate or Kubernetes pod replacement. For durable tools, use one of these two paths.

### Bake Tools Into The Image

Add package names to `docker/apt-packages.txt`, rebuild, and redeploy:

```bash
make build
```

For Kubernetes, push the rebuilt image and update `k8s/deployment.yaml` if the tag changed.

### Reinstall Tools From Persistent Storage

Compose and Kubernetes set `INSTALL_WORKSPACE_APT=1`. On startup, the entrypoint checks this file inside the persistent workspace:

```text
/workspace/.container/apt-packages.txt
```

Add one apt package name per line. Missing packages are installed automatically when the container or pod starts:

```text
htop
tree
postgresql-client
```

This keeps the package intent in persistent storage even though the installed system packages live in the container filesystem.

## Quick Start

Build the image:

```bash
make build
```

Start a long-running container:

```bash
make up
```

Open a shell in the container:

```bash
make shell
```

Run the CLI directly:

```bash
make run
```

Run diagnostics:

```bash
make doctor
```

List the named volumes:

```bash
make volumes
```

Stop the container:

```bash
make down
```

## Authentication

The first interactive CLI run can authenticate with ChatGPT or an API key:

```bash
docker compose exec workspace codex login
```

For access-token automation, pass the token through stdin:

```bash
printf '%s' "$CODEX_ACCESS_TOKEN" | docker compose exec -T workspace codex login --with-access-token
```

Auth state is stored in `codex-home/`, so it survives restarts and recreates. Do not commit the contents of that directory.

## Kubernetes

The `k8s/` directory contains a namespace, three PVCs, and one Deployment using the same mounted paths as Docker Compose.

Apply the manifests:

```bash
make k8s-apply
```

Open a shell:

```bash
kubectl -n codex-docker exec -it deploy/codex-docker -- bash
```

Run the CLI:

```bash
kubectl -n codex-docker exec -it deploy/codex-docker -- codex
```

Delete the manifests:

```bash
make k8s-delete
```

Update `k8s/deployment.yaml` if you publish the image under a different registry or tag.

## Notes

- The container runs as `root` so it can install system packages during a session.
- The image installs the CLI runtime under `/opt/codex-home`; runtime state is kept separately under the mounted `/root/.codex`.
- The Dockerfile uses the documented standalone installer from `https://chatgpt.com/codex/install.sh`.
