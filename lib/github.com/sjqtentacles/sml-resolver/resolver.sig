(* resolver.sig — SAT-backed package dependency resolution using sml-semver ranges. *)

signature RESOLVER =
sig
  type package = string
  type version = Semver.version
  type range = Semver.range

  type pkgSpec =
    { name : package
    , versions : version list
    , requires : (package * range) list
    }

  type assignment = (package * version) list

  exception Conflict of string

  val resolve : pkgSpec list -> assignment
  val resolveSafe : pkgSpec list -> assignment option

  val versionString : version -> string
  val parseVersion : string -> version
  val parseRange : string -> range
end
