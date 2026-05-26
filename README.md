[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]

# Spring Application Advisor Upgrade Example

A scripted live demo that takes a Spring Boot 2.6 / Java 8 app, uses [Spring Application Advisor](https://enterprise.spring.io/spring-application-advisor) to upgrade it to Spring Boot 4.0 / Java 25, then builds a GraalVM native image — printing a startup-time and memory comparison table at the end.

## What the demo does

1. Clones [`dashaun/hello-spring-boot-2-6`](https://github.com/dashaun/hello-spring-boot-2-6) into `upgrade-example/`.
2. Runs the app on **Java 8 / Spring Boot 2.6** and records startup time and memory.
3. Captures a build config with `advisor build-config get`, then applies an upgrade plan via `advisor upgrade-plan apply --squash 10`.
4. Re-runs the app on **Java 25 / Spring Boot 4.0** (JVM) and records metrics.
5. Builds a **GraalVM native image** with Liberica NIK and records metrics.
6. Prints a colored comparison table of startup time and memory savings across all three runs.

## Quick Start

```bash
./demo.sh
```

> **Heads up:** the script kills every running `java` process on the host before starting — it assumes any JVM is a leftover Spring Boot from a prior run. Don't run it on a machine with unrelated JVMs you care about.

## Prerequisites

- [Spring Application Advisor](https://enterprise.spring.io/spring-application-advisor) — the `advisor` CLI must be on your `PATH` and authenticated against the Spring Enterprise Repository.
- [SDKMAN](https://sdkman.io/install) — `curl -s "https://get.sdkman.io" | bash`. The demo runs `sdk env install` against [`.sdkmanrc`](.sdkmanrc) to install any missing Java versions on first run.
- [HTTPie](https://httpie.io/) — `brew install httpie`.
- [Vendir](https://carvel.dev/vendir/) — `brew tap carvel-dev/carvel && brew install vendir`.
- `bc`, `pv`, `zip`, `unzip`, `gcc`, `zlib1g-dev` — e.g. `sudo apt install -y bc pv zip unzip gcc zlib1g-dev` on Debian/Ubuntu.

### Java versions

Declared in [`.sdkmanrc`](.sdkmanrc) — change them there:

| Identifier | Used for |
| --- | --- |
| `8.0.482-librca` | Baseline (Spring Boot 2.6) |
| `25.0.3-librca` | Upgraded JVM run (Spring Boot 4.0) |
| `25.0.3.r25-nik` | Native image build (Liberica NIK) |

## Attributions

- [Demo Magic](https://github.com/paxtonhare/demo-magic) is pulled via `vendir sync`.

## Related Videos

- https://www.youtube.com/live/qQAXXwkaveM?si=4KunXZaretBrPZs3
- https://www.youtube.com/live/ck4AP7kRQkc?si=lDl203vbfZysrX5e
- https://www.youtube.com/live/VWPrYcyjG8Q?si=z7Q2Rm_XOlBwCiei

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[forks-shield]: https://img.shields.io/github/forks/dashaun-tanzu/saa-hello-world-2-6-demo.svg?style=for-the-badge
[forks-url]: https://github.com/dashaun-tanzu/saa-hello-world-2-6-demo/forks
[stars-shield]: https://img.shields.io/github/stars/dashaun-tanzu/saa-hello-world-2-6-demo.svg?style=for-the-badge
[stars-url]: https://github.com/dashaun-tanzu/saa-hello-world-2-6-demo/stargazers
[issues-shield]: https://img.shields.io/github/issues/dashaun-tanzu/saa-hello-world-2-6-demo.svg?style=for-the-badge
[issues-url]: https://github.com/dashaun-tanzu/saa-hello-world-2-6-demo/issues
