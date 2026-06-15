# codex-docker

A small Docker setup for running the Codex CLI inside an Ubuntu container with persistent local storage.

## What Persists

Docker Compose uses named volumes:

- `workspace-data` -> `/workspace`: files and repos you create or edit
- `codex-home` -> `/root/.codex`: CLI config, auth, sessions, logs, skills, and state
- `cache-data` -> `/root/.cache`: tool caches

Those volumes survive container restarts and recreates. Kubernetes uses matching PVCs under `k8s/`.

## SSH Access

The image installs and starts OpenSSH server by default. SSH host keys and `authorized_keys` live under the persistent `codex-home` volume or PVC:

```text
/root/.codex/ssh/
```

Password login is disabled. Root key login is enabled because the container is intentionally root-based for tool installation.

### Docker Compose SSH

Start the container:

```bash
make up
```

Add your public key to the persistent auth file:

```bash
docker compose exec -T workspace sh -c 'mkdir -p /root/.codex/ssh && cat > /root/.codex/ssh/authorized_keys && chmod 600 /root/.codex/ssh/authorized_keys' < ~/.ssh/id_ed25519.pub
```

Connect:

```bash
make ssh
```

Compose publishes SSH on `127.0.0.1:2222` by default. To publish differently:

```bash
SSH_BIND_ADDRESS=0.0.0.0 SSH_PORT=2222 docker compose up -d
```

Only bind publicly on a network you trust and only with key-based access.

### Kubernetes SSH

Apply the manifests:

```bash
make k8s-apply
```

Add your public key to the persistent auth file:

```bash
kubectl -n codex-docker exec -i deploy/codex-docker -- sh -c 'mkdir -p /root/.codex/ssh && cat > /root/.codex/ssh/authorized_keys && chmod 600 /root/.codex/ssh/authorized_keys' < ~/.ssh/id_ed25519.pub
```

For local testing, forward the Service:

```bash
make k8s-port-forward
```

Then connect from another terminal:

```bash
SSH_PORT=2222 make ssh
```

The Kubernetes Service is `ClusterIP` by default. For a reachable always-on host, expose `codex-docker-ssh` through your cluster's preferred private path, such as a VPN, mesh network, internal load balancer, or a patched Service type.

### SSH Config For Remote Projects

Add a concrete host alias to the machine running the Codex App:

```sshconfig
Host codex-docker
  HostName localhost
  Port 2222
  User root
  IdentityFile ~/.ssh/id_ed25519
```

Confirm SSH works before adding the host in the app:

```bash
ssh codex-docker
```

The app discovers concrete aliases from `~/.ssh/config`, uses OpenSSH to resolve them, and starts the remote app server through SSH using the remote login shell. The `codex` wrapper is installed on `PATH` as `/usr/local/bin/codex`.

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

## Updating The CLI

The image contains a baked runtime under `/opt/codex-home`. On first startup, the entrypoint seeds that runtime into the persistent `codex-home` volume or PVC at `/root/.codex`. After that, the `codex` command runs from persistent storage.

Update a running Compose container without recreating it:

```bash
make update
```

Update a running Kubernetes pod without restarting it:

```bash
make k8s-update
```

Because the standalone package store lives under `/root/.codex/packages/standalone`, updates made this way survive container recreates and pod replacements as long as the `codex-home` volume or PVC is retained.

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
- The image seeds the CLI runtime from `/opt/codex-home` into the mounted `/root/.codex` volume or PVC, so runtime updates can persist.
- The Dockerfile uses the documented standalone installer from `https://chatgpt.com/codex/install.sh`.
