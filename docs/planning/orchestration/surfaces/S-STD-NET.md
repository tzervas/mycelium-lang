# Surface S-STD-NET — blocking HTTPS client (v0)

**Status:** PRE-FREEZE shape (implement after WP-4)  
**Stack decision:** ureq + rustls, blocking  
**Home:** new pin `mycelium-std-net` OR module under std-io temporarily — **zipper chooses before WP-6 kickoff** (default: **new pin** to avoid std-io bloat)

## API (Mycelium-facing + wild)

```
// planned myc API (pure surface over wild)
http_request(method, url, headers, body, timeout_ms) -> Result<HttpResponse, NetError>
// wild names:
//   wild:http_request
//   wild:dns_resolve (optional v0 — ureq may hide)
```

```rust
// host side (sketch)
fn host_http_request(prim: &str, args: &[&Value]) -> Result<Value, EvalError>;
// uses ureq::Agent with rustls
```

## Non-goals v0

- Server listen / accept
- HTTP/2 multiplexing requirements
- Async/tokio

## Consumers

gha-runner-ctl, tg-agent-relay
