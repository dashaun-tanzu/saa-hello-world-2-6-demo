# AGENTS.md

This file provides guidance to coding agents (e.g. Claude Code, claude.ai/code) when working with code in this repository.

## What this repo is

This is a **scripted live demo**, not a library or application. The single artifact is `demo.sh`, which drives a terminal walkthrough of upgrading a Spring Boot 2.6 / Java 8 app to Spring Boot 4.0 / Java 25 (then a GraalVM native image) using Spring Application Advisor. The demo is intentionally narrated via [demo-magic](https://github.com/paxtonhare/demo-magic), so changes should preserve its readability when projected on a screen.

There is no build, test, or lint command. The "test" is running the demo end-to-end.

## Running the demo

```bash
./demo.sh
```

`demo.sh` will:
1. Check for required CLI deps (`vendir`, `http` (httpie), `bc`, `git`, `mvn`, `tar`) and exit if any are missing.
2. Check that `ADVISOR_VERSION` is exported (e.g. `export ADVISOR_VERSION=1.5.7`); exits otherwise.
3. `vendir sync` — pulls `demo-magic` into `vendir/` (config in `vendir.yml`).
4. Source `vendir/demo-magic/demo-magic.sh` for the `pei` / `displayMessage` helpers.
5. `kill -9` any running `java` processes (assumes any Java process is a leftover Spring Boot from a prior run — do not run this against a machine with unrelated JVMs).
6. Source SDKMAN and run `sdk env install` against `.sdkmanrc` to install any missing Java versions. Versions are declared in `.sdkmanrc` at the repo root (one `java=<version>` line per major) and parsed into `JAVA8_VERSION`, `JAVA25_VERSION`, `JAVA25_NIK_VERSION` at the top of `demo.sh`.
7. Recreate the `upgrade-example/` working directory from scratch (`rm -rf` then `mkdir`), clone `dashaun/hello-spring-boot-2-6` into it, and download the pinned `ADVISOR_VERSION` advisor CLI via `mvn dependency:get` (extracted to `upgrade-example/cli-binary/`).

`upgrade-example/` is **gitignored and recreated each run** — any committed files inside it on disk are stale artifacts from a prior demo, not source of truth.

## Demo flow (what `main` at the bottom of `demo.sh` actually does)

The script runs three phases and collects metrics from each into log files in `upgrade-example/`:

| Phase | Java | Boot | Memory log | Startup log |
|---|---|---|---|---|
| Baseline | 8 | 2.6 | `java8with2.6.log2` | `java8with2.6.log` |
| Upgraded (JVM) | 25 | 4.0 | `java21with4.0.log2` | `java21with4.0.log` |
| Upgraded (native) | 25 + NIK | 4.0 | `nativeWith4.0.log2` | `nativeWith4.0.log` |

> Note: the `java21*` filenames are historical — the demo currently runs Java 25. If you rename them, update both `springBootStart`/`showMemoryUsage` callsites and `statsSoFarTableColored` (which reads them) together.

Between phases the script calls `./cli-binary/advisor build-config get` and `./cli-binary/advisor upgrade-plan apply --squash 10`. The CLI is downloaded per-run (not the system `advisor`) from the Spring Enterprise Maven repo via `download_advisor`, which uses `mvn dependency:get` against `com.vmware.tanzu.spring:application-advisor-cli-<os>[-arch]:${ADVISOR_VERSION}:tar`. The runner's Maven `settings.xml` must already be authenticated against the Spring Enterprise repo.

`statsSoFarTableColored` at the end prints a colored comparison table; it depends on all six log files existing, so partial runs will produce `bc` / `cat` errors at the tail.

## Editing conventions

- **Java versions live in `.sdkmanrc`** at the repo root (one `java=<version>` line per major). `demo.sh` greps them into `JAVA8_VERSION`, `JAVA25_VERSION`, `JAVA25_NIK_VERSION` at startup. The two Java 25 entries are disambiguated by suffix (`-librca` vs `-nik`) — preserve that suffix if you change versions, or the grep will match the wrong line.
- **`pei` echoes then runs** a command (from demo-magic). Use it for anything the audience should see typed; use plain bash for setup that should stay invisible.
- **`talkingPoint`** waits for a keypress and clears the screen — it's the pacing primitive between steps. Don't remove them without a reason; they're how the presenter controls flow.
- The `cleanUp` function kills **every** `java` process on the host. Keep this in mind before running on a dev machine with other JVMs.

## Prerequisites (from README)

System tools: SDKMAN, httpie, vendir, Maven, plus `bc pv zip unzip gcc zlib1g-dev`. Maven's `settings.xml` must be authenticated against the Spring Enterprise repo so `download_advisor` can pull the CLI tar. `ADVISOR_VERSION` must be exported before the demo runs.
