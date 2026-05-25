# MongoDB Rules

Stack-specific rules. Load **alongside** `../general-rules.md` and the relevant runtime stack (`nodejs`, `nextjs-react`, `react-vite`, `python`, `java`).

---

## 1. Naming conventions

Consistent naming end-to-end (DB → ORM → server → client) is **non-negotiable** — mismatches cause silent bugs and bloat payload-transform code.

| Layer | Convention | Example |
|---|---|---|
| MongoDB database | lowercase, kebab or snake | `app_prod`, `analytics-staging` |
| MongoDB collection | lowercase, **plural**, camelCase | `blogPosts`, `userSessions`, `orderItems` |
| MongoDB field name | camelCase | `createdAt`, `userId`, `isActive` |
| MongoDB `_id` | `ObjectId` unless there's a reason | (default) |
| Mongoose model name | **PascalCase, singular** | `BlogPost`, `User`, `OrderItem` |
| Mongoose schema variable | `<entity>Schema` | `blogPostSchema` |
| Backend model file | `<Entity>.model.ts` or `<entity>.model.ts` | `BlogPost.model.ts` |
| Repository / DAO file | `<entity>.repository.ts` | `blogPost.repository.ts` |
| Service file | `<entity>.service.ts` | `blogPost.service.ts` |
| API route file | `<entity>.routes.ts` / `route.ts` (App Router) | `blogPosts.routes.ts` |
| API endpoint path | lowercase, plural, kebab | `/api/blog-posts`, `/api/order-items` |
| Frontend API client | camelCase, singular service | `blogPostService.ts`, `userApi.ts` |
| Frontend type / interface | **PascalCase, singular**, matches schema exactly | `interface BlogPost { ... }` |
| Frontend state | camelCase, plural for lists | `const [posts, setPosts] = useState<BlogPost[]>([])` |
| Index name | `<field>_<dir>` or `<purpose>_idx` | `userId_1`, `email_unique_idx` |

Rules:

- **Field names match end-to-end.** What's stored as `createdAt` in Mongo stays `createdAt` in the API response and in the TS interface. No silent `created_at` ↔ `createdAt` translation layers — they hide bugs.
- **Collection name = plural of the Mongoose model name, camelCased.** Mongoose pluralizes automatically; verify it produces what you expect for irregular nouns (`Person` → `people`, not `persons`) and override with `mongoose.model('Person', schema, 'people')` when it doesn't.
- **No reserved-ish keys** as top-level field names: avoid `type`, `class`, `new`, `default` unless schema-required.
- **Booleans are positive predicates**: `isActive`, `hasPaid`, `isDeleted` — not `inactive` or `notPaid`.
- **Foreign references end in `Id`** for scalar refs (`userId`, `organizationId`) and `Ids` for arrays (`tagIds`).
- **Timestamps**: `createdAt`, `updatedAt`, `deletedAt` (soft delete), `<verb>At` for events (`publishedAt`, `archivedAt`).

---

## 2. Schema design

- **Model around access patterns**, not relational normalization. Embed when reads dominate and the embedded data is bounded; reference when data is shared, mutated independently, or unbounded.
- **Bounded arrays**: any array field must have a documented upper bound. Unbounded growth on a document (comments, events, logs) is a defect — split into a separate collection.
- **Document size**: stay well under the 16 MB limit. In practice, target < 1 MB; anything larger is a design smell.
- **Schema versioning**: include a `schemaVersion` field on documents whose shape will evolve. Migrate forward in a controlled job, not lazily in business code.
- **Soft deletes**: prefer `deletedAt: Date | null` over a boolean. Filter at the repository layer, not in every query site.
- **Discriminators** (Mongoose): use for genuine subtypes sharing a collection; don't abuse them for cosmetic variants.
- **Polymorphic refs** (`refPath`): allowed, but document and test thoroughly — they bypass static typing guarantees.

---

## 3. Mongoose conventions

- **Strict mode on**: `mongoose.set('strictQuery', true)` and schema `strict: true`. Unknown fields should be rejected, not silently dropped.
- **Schema options**:
  ```js
  new Schema({ ... }, {
    timestamps: true,           // createdAt + updatedAt
    versionKey: false,          // disable __v unless you use optimistic concurrency
    toJSON: { virtuals: true, versionKey: false },
    toObject: { virtuals: true, versionKey: false },
  })
  ```
- **Validation in the schema**, not the controller. Use `required`, `min`/`max`, `enum`, `match`, and custom validators. Translate validation errors to HTTP at the error-handling boundary.
- **Virtuals** for derived fields that should appear in API responses but aren't stored.
- **Pre/post hooks**: use sparingly. Hooks that mutate other documents create hidden coupling — prefer explicit service-layer calls.
- **`lean()` for read-only queries** that don't need Mongoose documents — measurably faster and lower memory.
- **Use `.exec()`** on queries for proper stack traces — don't rely on the thenable shortcut in production.
- **One schema per file**: `src/models/<Entity>.model.ts` exports the compiled model as a named export.

---

## 4. Indexing

- **Every field used in a query filter, sort, or join (`$lookup`) at production scale must be indexed.** Verify with `.explain('executionStats')` — `COLLSCAN` on a hot path is a defect.
- **Compound indexes follow the ESR rule**: **Equality → Sort → Range**. Order the fields in the index in that priority.
- **Unique indexes** on natural keys (`email`, `slug`, external IDs). Always with a partial filter when the field is optional: `{ partialFilterExpression: { email: { $type: 'string' } } }`.
- **Don't over-index** — every index slows writes and consumes memory. Audit with `db.collection.aggregate([{ $indexStats: {} }])` and drop unused ones.
- **TTL indexes** for ephemeral data (sessions, password reset tokens, rate-limit buckets). Set on a `Date` field.
- **Text / geo indexes**: at most one text index per collection; design the index fields deliberately. For full-text at scale, prefer Atlas Search over `$text`.
- **Index creation in production**: `{ background: true }` (default on modern versions) or roll out in maintenance windows — never block writes on a foreground build.

---

## 5. Query patterns

- **Always project**: `find(filter, { name: 1, email: 1, _id: 0 })`. Fetching whole documents over the network is wasteful and leaks fields.
- **Always paginate**: never return an unbounded `find()`. Default to cursor-based pagination (`_id > lastSeenId`) over `skip/limit` — `skip` scans every prior doc.
- **Atomic operators over read-modify-write**: prefer `$inc`, `$push`, `$pull`, `$set`, `$addToSet`, `findOneAndUpdate` with `{ returnDocument: 'after' }` over fetching, mutating in app code, and saving back. Read-modify-write loses concurrent updates.
- **`upsert`** with `findOneAndUpdate(filter, { $setOnInsert: {...}, $set: {...} }, { upsert: true, new: true })`. Combine with a unique index on the filter fields to avoid duplicate-on-race.
- **Bulk writes**: use `bulkWrite()` for batches > ~50 ops. Ordered vs unordered: unordered is faster but doesn't guarantee sequence — pick deliberately.
- **Avoid `$where` and JavaScript expressions**: slow and a code-injection surface.
- **`$regex`** without a left-anchored prefix won't use an index. Don't build full-text search on `$regex` — use Atlas Search or a real search engine.
- **`$lookup` (joins)** are expensive — they shouldn't be the primary access pattern. If you `$lookup` on hot paths, reconsider the schema (embed, denormalize, or maintain a derived view).

---

## 6. Aggregation pipelines

- **Filter early**: `$match` before `$lookup`, `$project`, `$group`. Push every filter as close to the start as possible so it can use indexes.
- **Project early**: drop unused fields before expensive stages.
- **`$lookup` with `pipeline`** (sub-pipeline form) is preferred over the legacy `localField`/`foreignField` form when you need filtering on the joined side.
- **Pipeline files**: complex aggregations belong in dedicated files (`src/aggregations/<purpose>.pipeline.ts`) exporting a function that returns the pipeline array — testable in isolation.
- **`.explain()` complex pipelines** during development. Watch for `COLLSCAN`, full `$lookup` cartesian products, and stages that block (`$group`, `$sort` without index).
- **`allowDiskUse: true`** only for known-heavy admin/reporting queries — never the default for request-path queries.

---

## 7. Transactions

- Multi-document transactions cost latency and lock contention. Don't reach for them when atomic operators on a single document suffice.
- Wrap transactional code in `session.withTransaction(async () => { ... })` — handles retries on `TransientTransactionError` automatically.
- **All operations inside a transaction must pass `{ session }`.** Forgetting it silently runs them outside the transaction.
- Keep transactions **short** — they hold locks and can blow past the default 60s window.

---

## 8. Connection & client management

- **One `MongoClient` (or Mongoose connection) per process.** Reuse across requests — connecting per request exhausts the pool.
- Connection string in env, never in code. Use a secret manager in prod (see `general-rules.md` §4.3).
- Configure explicitly:
  - `maxPoolSize` (default 100 — often too high for serverless, too low for high-throughput services).
  - `serverSelectionTimeoutMS` (default 30s — usually want lower for user-facing paths).
  - `readPreference` (`primary` by default; `secondaryPreferred` only when you've thought about staleness).
  - `w` write concern (`majority` for anything you care about).
- **Serverless / Lambda / Vercel Functions**: cache the connection across invocations (`globalThis._mongoClient`) — don't reconnect per cold start unless the platform guarantees freezing won't kill the socket.
- **Healthcheck endpoint** pings the DB; readiness probe fails if the connection is down.

---

## 9. Migrations & data changes

- **All schema/data migrations go through a migration tool** — `migrate-mongo`, `mongock` (Java/Spring), or an equivalent. Never apply ad-hoc shell commands to production.
- Migrations are **forward-only and idempotent**: rerunning must be safe.
- **Backfills run as background jobs**, in batches with a `_id` cursor — never one big `updateMany` on a multi-million-doc collection.
- Validate the migration on a production-shaped dataset (Atlas snapshot or anonymized clone) before running it in production.
- Keep the prior shape readable while migration is in progress — code reads must handle both old and new shape until backfill completes.

---

## 10. Security

- **Never construct query objects from raw user input.** Untrusted input as the *value* of a known field is fine; untrusted input controlling the *operator* or *field name* is a NoSQL injection vector.
  - Bad: `User.find(req.body)` — caller can send `{ password: { $ne: null } }` and bypass auth.
  - Good: `User.find({ email: req.body.email })` with explicit, typed fields.
- **Sanitize / validate** at the API boundary: zod / joi / class-validator (Node), pydantic (Python), bean validation (Java). Reject unknown fields.
- **Least-privilege users**: the application user has only `readWrite` on the app database — not `dbAdmin`, not `root`. Migrations and backups use separate, scoped users.
- **TLS required** in transit. Atlas enforces this; on self-hosted, configure `tls=true` and verify certs.
- **Encryption at rest** at the storage layer (Atlas: automatic; self-hosted: WiredTiger or volume-level encryption).
- **Field-level encryption** (CSFLE / Queryable Encryption) for highly sensitive fields (PII, health, payment) where regulation demands it.
- **No PII in logs**: don't log full documents on error paths. Log `_id`s, not bodies.
- **Audit logs** for admin actions and sensitive data access (ISO 27001 alignment per `general-rules.md` §4.1).

---

## 11. Performance

- **Watch the slow query log** (`db.setProfilingLevel`) in dev and staging. Anything over the budget (usually 100 ms) gets indexed or rewritten.
- **`countDocuments`** is O(n) on a filter without a matching index — `estimatedDocumentCount` is O(1) for full-collection counts.
- **`$in` arrays** should be bounded (< ~100 elements). Larger sets need a different access pattern (join collection, batch query).
- **Hot-key writes**: avoid making every write target the same document (e.g., a global counter). Shard the write across N docs and aggregate on read.
- **Caching**: read-through cache (Redis) for hot read paths that don't need real-time consistency. Invalidate on the write path.
- **Sharding**: only when a single replica set is genuinely saturated. Shard key is a one-way decision — high cardinality, evenly distributed, used in common queries.

---

## 12. Testing

- **Don't mock the database.** Integration tests run against a real MongoDB — `mongodb-memory-server` for Node, Testcontainers for Java/Python. (Reinforces `general-rules.md` §3.2.)
- **Fresh database per test suite** (or per test for isolation-critical cases). Drop collections in `afterEach` / `afterAll`.
- **Test the indexes**: assert that the queries you care about hit the indexes you expect (`.explain('executionStats').executionStats.totalDocsExamined`).
- **Seed via factories**, not fixture JSON dumps that rot.

---

## 13. Observability

- **Structured logs** with `_id`s, operation names, and durations — not raw query objects.
- **Metrics** (Datadog / Prometheus): query duration P50/P95/P99 per operation, connection pool saturation, error rate by error code.
- **Slow query alerts** on operations exceeding the budget for the route.
- **Replica lag** monitored on production; alert when secondaries fall behind primary by > a few seconds.

---

## Pre-PR checklist (MongoDB-touching changes)

- [ ] New queries verified with `.explain()` — no unintended `COLLSCAN`.
- [ ] New indexes added for any new query/sort/filter pattern.
- [ ] Migrations are forward-only and idempotent; backfills batched.
- [ ] Validation at the API boundary rejects unknown fields and unexpected operators.
- [ ] Naming matches the table in §1 end-to-end (DB → API → frontend types).
- [ ] No raw user input flowing into query objects as operators or field names.
- [ ] Tests run against a real MongoDB instance, not a mock.
