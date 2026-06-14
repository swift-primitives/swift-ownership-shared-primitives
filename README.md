# Shared Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-primitives/swift-shared-primitives/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-primitives/swift-shared-primitives/actions/workflows/ci.yml)

`Shared<Element, B>` — the copy-on-write column. It wraps a backing column (`B: Store.Protocol & Buffer.Protocol`) in a single refcounted box and presents a **value-semantic** surface over it: copying a `Shared` shares the backing (no element copy), and the backing diverges **copy-on-write** only when a holder mutates while the box is shared. This is how a move-only (`~Copyable`) column becomes a freely-copyable value without giving up its zero-copy storage.

The unchecked storage lane lives behind the CoW-checked surface; box identity is observable in tests (`_boxID`) so divergence can be asserted. `Shared` is `Copyable` when its element is, and `Sendable` when its backing is.

---

## Key Features

- **Value semantics over move-only storage** — a `~Copyable` column gains copy/assign without an eager element copy.
- **Copy-on-write divergence** — shared holders read the same backing; the first mutation under sharing copies once, then proceeds in place.
- **Column-agnostic** — wraps any `Store.Protocol & Buffer.Protocol` backing.
- **Observable identity** — box identity is exposed (package-internal) so CoW behavior is testable, not assumed.

---

## Quick Start

```swift
import Shared_Primitive

// `Shared` gives a move-only column value semantics:
var a = Shared(/* backing column */)
var b = a          // shares a's backing — no element copy
b.mutate { … }     // copy-on-write: b diverges, a is untouched
```

---

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-shared-primitives.git", branch: "main")
]
```

Add the product to your target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Shared Primitive", package: "swift-shared-primitives")
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.3 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the corresponding Linux / Windows toolchain).

---

## Architecture

| Product | Contents | When to import |
|---------|----------|----------------|
| `Shared Primitive` | `Shared<Element, B>` — the copy-on-write column | Value-semantic sharing of a column |

---

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS 26         | Yes | Full support |
| Linux            | Yes | Full support |
| Windows          | Yes | Full support |
| iOS/tvOS/watchOS | —   | Supported    |
| Swift Embedded   | —   | Pending (nightly-toolchain follow-up) |

---

## Related Packages

- [`swift-store-primitives`](https://github.com/swift-primitives/swift-store-primitives) — `Store.Protocol`, the column capability `Shared` wraps.
- [`swift-buffer-primitives`](https://github.com/swift-primitives/swift-buffer-primitives) — `Buffer.Protocol`, the logical-count capability `Shared` requires.
- [`swift-column-primitives`](https://github.com/swift-primitives/swift-column-primitives) — `Column`, the canonical backings a `Shared` is typically built over.

---

## Community

<!-- BEGIN: discussion -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
