import ProjectDescription

/// Build-time enforcement of the declared graph at the `import` level.
///
/// Tuist's graph only controls *linking*: every static framework lands in the same
/// `BUILT_PRODUCTS_DIR`, so the compiler happily resolves `import MainScreen_Presentation` in
/// `App` even though `App` only declares `Router_Impl` — the module is merely a transitive
/// dependency. This pre-build phase closes that gap: a target's sources may import only its
/// own direct local dependencies. System and remote modules are never checked — only names
/// from the local architecture graph are forbidden.
enum ImportGuard {
    static func script(
        targetName: String,
        sourcesPath: String,
        allowedLocalImports: [String],
        allLocalTargets: [String]
    ) -> TargetScript {
        let allowed = Set(allowedLocalImports + [targetName])
        let forbidden = allLocalTargets.filter { !allowed.contains($0) }.sorted()

        return .pre(
            script: """
            forbidden="\(forbidden.joined(separator: " "))"
            status=0
            for module in $forbidden; do
              pattern="^[[:space:]]*(@[_a-zA-Z]+[[:space:]]+)*import[[:space:]]+((class|struct|enum|protocol|func|var|let|typealias)[[:space:]]+)?${module}([[:space:]]|\\\\.|$)"
              matches=$(grep -rnE --include='*.swift' "$pattern" "$SRCROOT/\(sourcesPath)" || true)
              if [ -n "$matches" ]; then
                echo "$matches" | while IFS=: read -r file line _; do
                  echo "$file:$line: error: \(targetName) не может импортировать ${module}: это не прямая зависимость таргета (Project.swift)"
                done
                status=1
              fi
            done
            [ "$status" -eq 0 ] && touch "$DERIVED_FILE_DIR/ImportGuard.stamp"
            exit $status
            """,
            name: "Architecture: Import Guard",
            inputPaths: ["$(SRCROOT)/\(sourcesPath)/**/*.swift"],
            outputPaths: ["$(DERIVED_FILE_DIR)/ImportGuard.stamp"]
        )
    }
}
