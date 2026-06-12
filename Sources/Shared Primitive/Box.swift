// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

/// The one class in the tower above Memory — the refcounted box behind `Shared`.
///
/// ## The drain-box rule (R-5, binding)
///
/// The box's `deinit` OWNS element teardown: it drains the wrapped buffer through public
/// mutating API (the column-correct strategy captured at construction), then closes with
/// `_fixLifetime(self)` — the stdlib `_ContiguousArrayStorage` idiom. Relying on the wrapped
/// struct's own deinit oracle is UNSOUND here: under `-O`, once `isKnownUniquelyReferenced`
/// has been applied to the box, the devirtualized release synthesizes a destroy of the
/// generic-namespace-nested `~Copyable` struct that OMITS its user deinit while still
/// destroying its fields (elements leak, bytes are freed). Durable repro:
/// `swift-institute/Experiments/cow-box-deinit-omission-miscompile`. With the drain, the
/// struct oracle behind the box tears down an EMPTY buffer — count-driven, so correctness no
/// longer depends on whether the compiler runs it.
///
/// The drain strategy is a stored `@Sendable` closure so the box stays COLUMN-AGNOSTIC: each
/// pinned `Shared` construction site supplies the drain its column needs (linear prefix today;
/// ring/linked disciplines supply theirs when their ADTs arrive).
@safe
@usableFromInline
internal final class Box<Wrapped: ~Copyable> {
    /// The column lives OUT-OF-LINE behind the box's own allocation (B-1′,
    /// seat-ruled (c)): a `let` pointer field carries no class-field write
    /// access, and address-projected use carries no per-op dynamic exclusivity
    /// bookkeeping — the ~3.9 ns cross-module barrier tax the in-line stored
    /// property paid on every seam-door crossing. This also EXITS the
    /// R-6/#89832 miscompile shape: there is no struct-in-class-field deinit
    /// for `-O` to omit — teardown is the explicit drain + pointer
    /// deinitialize below, count-driven per the drain-box rule.
    ///
    /// Ownership (the `Storage.Contiguous` idiom, one tier up): the box
    /// allocates and initializes at construction, and is the SOLE owner — the
    /// pointer never escapes the box's projections; `deinit` drains through
    /// public mutating API, then deinitializes and deallocates.
    @usableFromInline
    internal let _payload: UnsafeMutablePointer<Wrapped>

    /// Address-projected access to the wrapped column (no copies, no
    /// class-field exclusivity; the borrow/mutation scoping is the enclosing
    /// access of the projected address — the stdlib addressor discipline).
    @usableFromInline
    internal var wrapped: Wrapped {
        unsafeAddress {
            unsafe UnsafePointer(_payload)
        }
        unsafeMutableAddress {
            unsafe _payload
        }
    }

    @usableFromInline
    internal let _drain: @Sendable (inout Wrapped) -> Void

    /// The column-correct deep-copy strategy, captured at construction alongside the drain.
    /// `nil` on statically-unique columns (`~Copyable` elements — the wrapper cannot be
    /// duplicated, so uniqueness never needs restoring). Non-`nil` whenever the element is
    /// `Copyable`, where the box CAN become shared: `prepareForMutation()` clones through it.
    @usableFromInline
    internal let _clone: (@Sendable (borrowing Wrapped) -> Wrapped)?

    @usableFromInline
    internal init(
        _ wrapped: consuming Wrapped,
        drain: @escaping @Sendable (inout Wrapped) -> Void,
        clone: (@Sendable (borrowing Wrapped) -> Wrapped)? = nil
    ) {
        let payload = UnsafeMutablePointer<Wrapped>.allocate(capacity: 1)
        unsafe payload.initialize(to: wrapped)
        unsafe self._payload = payload
        self._drain = drain
        self._clone = clone
    }

    deinit {
        _drain(&wrapped)
        unsafe _payload.deinitialize(count: 1)
        unsafe _payload.deallocate()
        _fixLifetime(self)
    }
}

/// `@unchecked` is load-bearing: the box carries mutable column state the compiler
/// cannot prove Sendable — held OUT-OF-LINE behind `_payload` (B-1′), so the unchecked
/// claim now covers the pointer too: the allocation is box-owned for the box's whole
/// life, reached only through the box's address projections, and mutated only on the
/// uniqueness-restored paths. Soundness is the CoW discipline AROUND the box — every
/// public mutation path restores uniqueness before writing (the `Shared: Sendable`
/// note), both strategies are themselves `@Sendable` by stored type, and the only
/// unchecked lane (`…AssumingUnique`) asserts uniqueness in debug. Adversarial record:
/// the W2 concurrency suites (detach races, sibling storms, span windows) under the
/// arc's TSan gate — REPORT-arc-shared-soundness-W2; re-run on this shape at the B-1′
/// gate (REPORT-engine-fix-W3).
extension Box: @unchecked Sendable where Wrapped: Sendable & ~Copyable {}
