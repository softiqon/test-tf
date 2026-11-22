# Practice repo: dairy auction platform

This is dummy application code written for interview practice. It is NOT GDT's code.
It imitates what an interviewer might hand over: a small app you have never seen, which
you must containerise, deploy and run safely, cheaply and at scale.

What is here is the application only. There are no Dockerfiles, no Terraform, no pipelines
and no Kubernetes manifests. Those are your job.

## What the app does

| Part | Tech | Port | What it is |
|------|------|------|------------|
| `bid-api` | .NET 8 minimal API | 5000 | Round clock, bid submission, health and metrics |
| `catalog-api` | Spring Boot 3.3, Java 21 | 8080 | Products and event calendar, with Actuator |
| `web` | React 18 + Vite | 5173 dev, static when built | Bidder console that polls the round and submits bids |
| `db/schema.sql` | SQL | n/a | Reference schema. The APIs do not use it yet |

## Things in the code worth noticing (they matter for your design)

1. `bid-api` has `/healthz` (liveness) and `/readyz` (readiness). Readiness checks the
   `Dependencies__Sql` and `Dependencies__Redis` settings, each as `host:port`.
2. `bid-api` reads settings from environment variables with a double underscore,
   for example `Auction__RoundSeconds=30`.
3. `POST /api/bids` needs an `Idempotency-Key` header. Retries with the same key are safe.
4. `bid-api` keeps bids IN MEMORY. Two replicas would not agree. What does that mean for scaling?
5. The round clock starts when the process starts. What does that mean for several replicas?
6. `catalog-api` returns `Cache-Control: public, max-age=60` on `/api/products`.
7. `catalog-api` exposes `/actuator/health/liveness`, `/actuator/health/readiness` and
   `/actuator/prometheus`, and shuts down gracefully.
8. `bid-api` exposes `/metrics` with `bids_accepted_total`, `bids_rejected_total`, `bids_replayed_total`.
9. The React app uses relative URLs (`/api/...`). Something in front must route them.
10. `/api/products` and `/api/calendar` go to catalog-api. `/api/events` and `/api/bids` go to bid-api.

## Run it locally first (no containers)

```bash
# catalog-api
cd catalog-api && mvn spring-boot:run

# bid-api (needs the .NET 8 SDK)
cd bid-api && dotnet run --urls http://localhost:5000

# web
cd web && npm install && npm run dev      # http://localhost:5173
```

Check that it works:

```bash
curl localhost:8080/api/products
curl localhost:5000/api/events/current
curl -X POST localhost:5000/api/bids \
  -H "Content-Type: application/json" -H "Idempotency-Key: demo-1" \
  -d '{"bidder":"BIDDER-001","productCode":"WMP","quantity":100}'
```

Send the last request twice. What is different about the second response body?
(Look at `/metrics` after.)

## Your brief

Context: assume the platform runs two auction events a month, with the busiest traffic in
the first few minutes of each round. The rest of the month is quiet. Budget ceiling for
your design: NZD 8,000 per month for production.

Work through these in order. Stop at each "done when" line and check yourself.
There are no model answers in this repo.

### Step 1: Make each app run in a container
- Write one Dockerfile per app.
- Done when: all three build, run as a non-root user, and `docker image ls` shows sizes you could defend.

### Step 2: Run the whole thing together
- Write a `docker-compose.yml` with a reverse proxy in front, so the browser only sees one origin.
- Done when: `http://localhost` shows the console, products load, and a bid can be submitted.

### Step 3: Describe the Azure infrastructure in Terraform
- Cover: networking, a container platform, a registry, a database, secrets, logging.
- Keep secrets out of state and out of the repo.
- Done when: `terraform validate` passes and `terraform plan` reads clearly to a stranger.

### Step 4: Build the pipeline
- GitHub Actions: build, test, scan, push an image once, deploy to a test environment, then promote.
- Use OIDC to Azure, not stored credentials.
- Done when: a pull request runs checks, and a merge deploys without anyone typing a command.

### Step 5: Make it survive an auction
- Decide how bid-api scales when its state is in memory. Fix the design, not just the replica count.
- Decide how you pre-scale for an event, and how you scale back down.
- Done when: you can say what you would load-test, with which numbers, and what "good" looks like.

### Step 6: Watch it
- Choose the three signals you would put on a wall screen during an auction.
- Write alert rules for them.
- Done when: every alert has an owner and an action, and none fires for something nobody can act on.

### Step 7: Cost
- Write down what each piece costs per month at idle, and at event peak.
- Done when: your total is under the ceiling, and you can name your two biggest levers.

### Step 8: Break it on purpose
- Kill a replica, take the database away, and make a bad deployment. Observe what happens.
- Done when: you can describe each failure from the user's side and from the operator's side.

### Step 9: Tell the story
- Prepare five minutes: the architecture, the three decisions you are least sure about, and what you would do with two more weeks.
