# Java Rules

Stack-specific rules. Load **alongside** `../general-rules.md` when working in a Java project (Spring Boot or general JVM).

---

## Runtime & tooling

- **Java 17 LTS** minimum; **Java 21 LTS** preferred for new services.
- Build: Maven **or** Gradle — one per repo, not mixed.
- Format: Spotless + `google-java-format` (or palantir-java-format).
- Static analysis: Checkstyle / SpotBugs / ErrorProne — wired into the build, not optional.
- `pom.xml` / `build.gradle.kts` enforce versions via dependency management; no floating versions.

---

## File layout (Spring Boot)

- **Package by feature, not by layer**: `com.company.<feature>` containing controller, service, repository, dto, model for that feature.
- `src/main/java/...` and `src/test/java/...` mirror each other.
- `application.yml` for config; profile-specific overrides in `application-<profile>.yml`.
- One public top-level type per file (Java requires this).

---

## Patterns

- **Constructor injection only.** No field `@Autowired`, no setter injection. Makes testing trivial and mutations impossible.
  ```java
  @Service
  @RequiredArgsConstructor  // Lombok-generated constructor
  public class OrderService {
      private final OrderRepository repository;
      private final PaymentClient paymentClient;
  }
  ```
- **Immutable value objects**: `record` for DTOs, `final` fields elsewhere.
- `Optional<T>` for "may be absent" **return** values. Never store `Optional` in a field, never use it as a method parameter.
- Streams for transforms; classic loops when there's side-effecting logic.
- **No raw types.** No unchecked casts without `@SuppressWarnings("unchecked")` + reason.
- Lombok permitted: `@Value`, `@RequiredArgsConstructor`, `@Slf4j`, `@Builder`. **Avoid** `@SneakyThrows`, `@Data` on entities, `@EqualsAndHashCode(callSuper = ...)` foot-guns.
- Pattern matching (`switch` expressions, `instanceof` patterns) over instanceof-cast chains.

---

## Spring Boot specifics

- Controllers thin; business logic in `@Service` beans; data access in `@Repository`.
- **DTOs at the API boundary**; never expose JPA entities directly (lazy loading exceptions, accidental over-fetching, contract coupling).
- Validation via `jakarta.validation` annotations + `@Valid` on controller params.
- Transactions at the service layer (`@Transactional`), not the controller. Read-only operations get `@Transactional(readOnly = true)`.
- `@ConfigurationProperties` for typed config; avoid scattered `@Value("${...}")` strings.
- Exception handling centralized in `@RestControllerAdvice` with `@ExceptionHandler` methods → consistent `ProblemDetail` (RFC 7807) responses.

---

## JPA / persistence

- **Lazy fetching by default**; explicit fetch joins where needed. Watch for N+1 — log SQL in dev (`spring.jpa.show-sql=true` + Hibernate stats).
- **Flyway or Liquibase** for migrations. `ddl-auto=update` is **forbidden** in non-dev environments.
- Index every column used in `WHERE` / `JOIN` / `ORDER BY` at production scale.
- Use `@Query` JPQL or Criteria API — never string-concatenate values into queries.
- Pagination via `Pageable`, not `findAll()` + in-memory slicing.

---

## Testing

- **JUnit 5** + **AssertJ** for assertions. No JUnit 4 in new code.
- **Mockito** for mocks; `@MockBean` only when Spring context is genuinely required.
- **Testcontainers** for integration tests against real DBs / Kafka / Redis — don't mock the database.
- `@SpringBootTest` is heavy — use slice tests (`@WebMvcTest`, `@DataJpaTest`) when you can.
- One assertion concept per test; descriptive method names (`shouldRejectOrderWhenInventoryInsufficient`).

---

## Pre-PR checklist

```bash
./mvnw verify               # or ./gradlew build
./mvnw spotless:check       # or ./gradlew spotlessCheck
```

`verify` runs compile + unit tests + integration tests + static analysis. Zero new warnings.

---

## Logging & observability

- **SLF4J** logging API (`org.slf4j.Logger`), Logback or Log4j2 as the binding.
- Parameterized log messages: `log.info("user {} updated order {}", userId, orderId)` — never string-concat.
- JSON log output in prod (logstash-logback-encoder or equivalent).
- Micrometer for metrics; OpenTelemetry for traces.
- MDC for request/correlation ids, propagated across async boundaries.

---

## Security

- **Spring Security** with method-level `@PreAuthorize` for sensitive operations — not just URL-pattern security.
- Input validation at the controller boundary; never trust client payloads.
- Dependency audit: `mvn org.owasp:dependency-check-maven:check` or `./gradlew dependencyCheckAnalyze`. Resolve high-severity findings before release.
- Parameterized JPQL / Criteria API — never string concatenation in queries.
- Don't log full request bodies on auth endpoints.
- CSRF protection on by default; only disable for stateless APIs with token auth.
- BCrypt / Argon2 for password hashing — never MD5 / SHA1 / plain SHA-256.
