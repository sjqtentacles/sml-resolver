structure Tests =
struct
  open Harness
  structure R = Resolver

  fun v s = R.parseVersion s
  fun find pkg asn =
      case List.find (fn (p, _) => p = pkg) asn of SOME (_, ver) => SOME ver | NONE => NONE

  fun run () =
  let
    val () = section "simple resolve"
    val bVers = [v "1.0.0", v "1.2.0", v "2.0.0"]
    val specs =
      [ { name = "A", versions = [v "1.0.0"], requires = [("B", R.parseRange "^1.0.0")] }
      , { name = "B", versions = bVers, requires = [] }
      ]
    val asn = R.resolve specs
    val () = check "resolves A" (find "A" asn = SOME (v "1.0.0"))
    val () = check "picks B 1.2.0" (find "B" asn = SOME (v "1.2.0"))

    val () = section "conflict"
    val conflictSpecs =
      [ { name = "A", versions = [v "1.0.0"], requires = [("B", R.parseRange "^2.0.0")] }
      , { name = "C", versions = [v "1.0.0"], requires = [("B", R.parseRange "^1.0.0")] }
      , { name = "B", versions = bVers, requires = [] }
      ]
    val () = check "conflict is NONE" (R.resolveSafe conflictSpecs = NONE)
    val () = checkRaises "conflict raises" (fn () => ignore (R.resolve conflictSpecs))

    val () = section "diamond"
    val dSpecs =
      [ { name = "A", versions = [v "1.0.0"], requires = [("B", R.parseRange ">=1.0.0"), ("C", R.parseRange ">=1.0.0")] }
      , { name = "B", versions = [v "1.0.0"], requires = [("D", R.parseRange "^1.0.0")] }
      , { name = "C", versions = [v "1.0.0"], requires = [("D", R.parseRange "^2.0.0")] }
      , { name = "D", versions = [v "1.0.0", v "2.0.0"], requires = [] }
      ]
    val () = check "diamond unsat" (R.resolveSafe dSpecs = NONE)

    val () = section "semver helpers"
    val () = checkString "version round-trip" ("1.2.3", R.versionString (v "1.2.3"))
  in
    Harness.run ()
  end
end
