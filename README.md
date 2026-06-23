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

## Building

```sh
make all-tests   # MLton + Poly/ML
```

## Layout

LIB-canonical. Vendors sml-sat, sml-semver, sml-parsec.

## License

MIT. See [LICENSE](LICENSE).
