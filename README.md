# sml-resolver

[![CI](https://github.com/sjqtentacles/sml-resolver/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-resolver/actions/workflows/ci.yml)

Wave 3 SAT-backed package dependency resolver. Parses semver ranges via vendored
**sml-semver**, encodes version choice as CNF, and calls **sml-sat** DPLL.
Picks the **maximum** satisfying version per package when multiple candidates
exist.

## Reference scenarios (tests)

| Case | Expected |
|------|----------|
| A → B `^1.0`, B ∈ {1.0, 1.2, 2.0} | B@1.2.0 |
| A → B `^2`, C → B `^1` | conflict |
| Diamond A→B,C; B→D `^1`; C→D `^2` | unsat |

## API sketch

```sml
val asn = Resolver.resolve specs
val opt = Resolver.resolveSafe specs   (* NONE on conflict *)
```

## Example

`make example` builds and runs [`examples/demo.sml`](examples/demo.sml), which
resolves a diamond-shaped dependency graph to the highest mutually compatible
version and shows an unsatisfiable graph returning `NONE` (output is
byte-identical under MLton and Poly/ML):

```
SAT-backed dependency resolver (sml-resolver)

Diamond graph: app -> {left, right} -> util (overlapping ranges)
  resolve      = util@1.2.0, right@1.0.0, left@1.0.0, app@1.0.0

Conflicting graph: app needs util ^2.0.0, legacy needs util ^1.0.0
  resolveSafe  = NONE (unsatisfiable)

  parseVersion "1.2.3" round-trips to "1.2.3"
```

## Building

```sh
make all-tests   # MLton + Poly/ML
```

## Layout

LIB-canonical. Vendors sml-sat, sml-semver, sml-parsec.

## License

MIT. See [LICENSE](LICENSE).
