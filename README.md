# panda-compose

A self-contained Docker Compose stack for running a local PanDA workload management
system. Designed for development and CI testing — in particular for developing and
testing the [jacamar-ci](https://gitlab.com/ecp-ci/jacamar-ci) PanDA executor.

This repository mirrors the component set of
[panda-k8s](https://github.com/PanDAWMS/panda-k8s) but expressed as a single
`docker-compose.yml`, using the same upstream container images.

## Stack components

| Service | Image | Purpose |
|---|---|---|
| `postgres` | `ghcr.io/pandawms/panda-database:latest` | PanDA + JEDI database (postgres with pre-installed schema) |
| `activemq` | `ghcr.io/pandawms/panda-activemq:latest` | Message broker (STOMP/OpenWire) |
| `panda-server` | `ghcr.io/pandawms/panda-server:latest` | PanDA REST API + Apache httpd |
| `panda-jedi` | `ghcr.io/pandawms/panda-jedi:latest` | JEDI workload management daemon |
| `mariadb` | `bitnami/mariadb:latest` | Harvester database |
| `harvester` | `ghcr.io/hsf/harvester:latest` | Resource-facing pilot submission service |

Service startup order: `postgres` + `activemq` + `mariadb` → `panda-server` → `panda-jedi` + `harvester`

## Quick start

```bash
# 1. Clone and enter the repository
git clone https://github.com/your-org/panda-compose.git
cd panda-compose

# 2. Create your environment file (edit secrets as needed)
cp .env.example .env

# 3. Start the stack
docker compose up -d

# 4. Wait for the server to become healthy
./scripts/healthcheck.sh

# 5. Register the local compute queue
./scripts/setup-queue.sh
```

The PanDA server is then accessible at:
- HTTP:  `http://localhost:25080/server/panda`
- HTTPS: `https://localhost:25443/server/panda`

The ActiveMQ web console is at `http://localhost:8161/admin/` (admin/admin).

## Configuration

### Environment variables

Copy `.env.example` to `.env` and adjust the values. The most important variables are:

| Variable | Default | Description |
|---|---|---|
| `PANDA_DB_PASSWORD` | `panda_secret` | PostgreSQL password for PanDA |
| `PANDA_ACTIVEMQ_PASSWD_panda` | `panda_mq_secret` | ActiveMQ password for PanDA |
| `PANDA_AUTH` | `None` | Authentication type (`None` = no-auth dev mode, `oidc` for token auth) |
| `HARVESTER_DB_PASSWORD` | `harvester_secret` | MariaDB password for Harvester |

### Config files

Static configuration is mounted read-only into the containers:

| File | Container path | Purpose |
|---|---|---|
| `config/panda/panda_common.cfg` | `/etc/panda/panda_common.cfg` | Logging |
| `config/panda/panda_server.cfg` | `/etc/panda/panda_server.cfg` | PanDA server |
| `config/panda/panda_jedi.cfg` | `/etc/panda/panda_jedi.cfg` | JEDI daemon |
| `config/harvester/panda_harvester.cfg` | `/etc/harvester/panda_harvester.cfg` | Harvester main config |
| `config/harvester/panda_queues.cfg` | `/etc/harvester/panda_queues.cfg` | Compute queue definitions |

The default queue `PANDA_COMPOSE_LOCAL` uses Harvester's local submitter — suitable for
submitting trivial test jobs on the same host (or within the compose network).

## Relation to panda-k8s

This repository intentionally reuses the same container images and environment variable
names as [panda-k8s](https://github.com/PanDAWMS/panda-k8s). If you need a production-
grade deployment, follow the panda-k8s Helm chart instructions instead.

## Developing the jacamar-ci PanDA executor

Point `panda_url` in your jacamar-ci TOML config at `http://localhost:25080/server/panda`
and use the `PANDA_COMPOSE_LOCAL` queue name. See the jacamar-ci PanDA executor
documentation for full configuration details.

## CI

A GitHub Actions smoke-test workflow (`.github/workflows/ci.yml`) starts the full stack
on every push and PR, runs the healthcheck, and verifies all services are up.
