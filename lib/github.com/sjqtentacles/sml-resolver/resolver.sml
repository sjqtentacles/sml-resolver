structure Resolver :> RESOLVER =
struct
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

  fun versionString v = Semver.toString v
  fun parseVersion s = Semver.parseExn s
  fun parseRange s = Semver.parseRangeExn s

  fun insertPkg (p, ps) =
      if List.exists (fn x => x = p) ps then ps else p :: ps

  fun collectPackages specs =
      List.foldl
        (fn ({name, requires, ...}, acc) =>
           List.foldl (fn ((p, _), a) => insertPkg (p, a)) (insertPkg (name, acc)) requires)
        [] specs

  fun specFor specs name =
      case List.find (fn s => #name s = name) specs of
          SOME s => s
        | NONE => raise Conflict ("unknown package " ^ name)

  fun varsFor specs =
      let
        fun addSpec ({name, versions, ...}, acc) =
            List.foldr (fn (ver, a) => (name, ver) :: a) acc versions
      in List.foldl addSpec [] specs end

  fun varId vars key =
      let
        fun findAt (i, k :: ks) = if k = key then i else findAt (i + 1, ks)
          | findAt (_, []) = raise Conflict "internal var"
      in findAt (1, vars) end

  fun litPos i = i
  fun litNeg i = ~i

  fun pairwiseAtMostOne [] = []
    | pairwiseAtMostOne [x] = []
    | pairwiseAtMostOne (x :: xs) =
        List.map (fn y => [litNeg x, litNeg y]) xs @ pairwiseAtMostOne xs

  fun atMostOneClauses ids = pairwiseAtMostOne ids

  fun atLeastOneClause ids = [map litPos ids]

  fun compatibleVersions specs target range =
      let val {versions, ...} = specFor specs target
      in List.filter (fn v => Semver.satisfies (v, range)) versions end

  fun dependencyClauses specs vars =
      let
        fun clausesForVersion (name, ver, requires, acc) =
            let val src = varId vars (name, ver)
            in
              List.foldl
                (fn ((dep, range), cs) =>
                   let
                     val cands = compatibleVersions specs dep range
                     val depVar = fn cv => varId vars (dep, cv)
                   in
                     if null cands then cs
                     else (litNeg src :: map (litPos o depVar) cands) :: cs
                   end)
                acc requires
            end
        fun clausesForSpec ({name, versions, requires}, acc) =
            List.foldl (fn (ver, a) => clausesForVersion (name, ver, requires, a)) acc versions
      in List.foldl clausesForSpec [] specs end

  fun lookupVar model i =
      case List.find (fn (j, b) => j = i) model of SOME (_, true) => true | _ => false

  fun assignmentFromModel vars model =
      List.foldr
        (fn (key, acc) =>
           let val i = varId vars key
           in if lookupVar model i then key :: acc else acc end)
        [] vars

  fun lookupVersion assignment pkg =
      case List.find (fn (p, _) => p = pkg) assignment of
          SOME (_, v) => SOME v
        | NONE => NONE

  fun maximize specs assignment =
      let
        fun rangesFor target =
            List.foldl
              (fn ({name, requires, ...}, acc) =>
                 case lookupVersion assignment name of
                     NONE => acc
                   | SOME _ =>
                       List.foldl
                         (fn ((dep, range), acc') =>
                            if dep = target then range :: acc' else acc')
                         acc requires)
              [] specs
        fun bestFor pkg =
            let val {versions, ...} = specFor specs pkg
            in
              case rangesFor pkg of
                  [] => lookupVersion assignment pkg
                | ranges =>
                    let
                      fun pickBest (ranges, soFar) =
                          case ranges of
                              [] => soFar
                            | r :: rs =>
                                (case Semver.maxSatisfying (versions, r) of
                                     NONE => pickBest (rs, soFar)
                                   | SOME v =>
                                       (case soFar of
                                            NONE => pickBest (rs, SOME v)
                                          | SOME b =>
                                              if Semver.gt (v, b)
                                              then pickBest (rs, SOME v)
                                              else pickBest (rs, soFar)))
                    in pickBest (ranges, NONE) end
            end
        fun bump [] acc = rev acc
          | bump (p :: ps) acc =
              case bestFor p of
                  NONE => bump ps acc
                | SOME v => bump ps ((p, v) :: acc)
      in bump (collectPackages specs) [] end

  fun resolve specs =
      let
        val vars = varsFor specs
        val pkgNames = collectPackages specs
        fun idsForPkg p =
            let val {versions, ...} = specFor specs p
            in map (fn ver => varId vars (p, ver)) versions end
        val idsByPkg = map idsForPkg pkgNames
        val clauses =
            List.concat (map atMostOneClauses idsByPkg)
            @ List.concat (map atLeastOneClause idsByPkg)
            @ dependencyClauses specs vars
      in
        case Sat.solve clauses of
            NONE => raise Conflict "unsatisfiable constraints"
          | SOME model =>
              let val picked = maximize specs (assignmentFromModel vars model)
              in
                if length picked = length pkgNames then picked
                else raise Conflict "incomplete assignment"
              end
      end

  fun resolveSafe specs = (SOME (resolve specs) handle Conflict _ => NONE)
end
