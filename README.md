# codex-docker

A small Docker setup for running the Codex CLI inside an Ubuntu container with persistent local storage.

## What Persists

Docker Compose uses named volumes:

- `workspace-data` -> `/workspace`: files and repos you create or edit
- `codex-home` -> `/root/.codex`: CLI config, auth, sessions, logs, skills, and state
- `cache-data` -> `/root/.cache`: tool caches

Those volumes survive container restarts and recreates. Kubernetes uses matching PVCs under `k8s/`.

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
