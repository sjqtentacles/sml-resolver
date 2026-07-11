(* demo.sml - SAT-backed package dependency resolution over semver ranges:
   resolves a diamond-shaped dependency graph to the highest mutually
   compatible versions, then shows an unsatisfiable graph returning NONE.
   Deterministic: identical output on every run and both compilers. *)

structure R = Resolver

fun v s = R.parseVersion s
fun r s = R.parseRange s

fun showAssignment asn =
  String.concatWith ", "
    (List.map (fn (p, ver) => p ^ "@" ^ R.versionString ver) asn)

val () = print "SAT-backed dependency resolver (sml-resolver)\n\n"

val diamond =
  [ { name = "app",   versions = [v "1.0.0"]
    , requires = [("left", r "^1.0.0"), ("right", r "^1.0.0")] }
  , { name = "left",  versions = [v "1.0.0"], requires = [("util", r "^1.1.0")] }
  , { name = "right", versions = [v "1.0.0"], requires = [("util", r ">=1.0.0 <2.0.0")] }
  , { name = "util",  versions = [v "1.0.0", v "1.1.0", v "1.2.0", v "2.0.0"], requires = [] }
  ]
val () = print "Diamond graph: app -> {left, right} -> util (overlapping ranges)\n"
val asn = R.resolve diamond
val () = print ("  resolve      = " ^ showAssignment asn ^ "\n")

val conflicting =
  [ { name = "app",    versions = [v "1.0.0"], requires = [("util", r "^2.0.0")] }
  , { name = "legacy", versions = [v "1.0.0"], requires = [("util", r "^1.0.0")] }
  , { name = "util",   versions = [v "1.0.0", v "1.2.0", v "2.0.0"], requires = [] }
  ]
val () = print "\nConflicting graph: app needs util ^2.0.0, legacy needs util ^1.0.0\n"
val () =
  case R.resolveSafe conflicting of
    NONE => print "  resolveSafe  = NONE (unsatisfiable)\n"
  | SOME asn' => print ("  resolveSafe  = " ^ showAssignment asn' ^ "\n")

val () = print ("\n  parseVersion \"1.2.3\" round-trips to \"" ^ R.versionString (v "1.2.3") ^ "\"\n")
