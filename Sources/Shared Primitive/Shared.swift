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

public import Buffer_Protocol_Primitives
public import Store_Protocol_Primitives
public import Index_Primitives

/// The CoW column combinator — where conditional copyability enters the tower (the ratified
/// W4 design, `PROPOSAL-tower-perfected-design.md` §1.3 / R-1 / R-2).
///
/// `Shared` wraps a MOVE-ONLY buffer column in a refcounted box and is `Copyable` exactly when
/// the ELEMENT is copyable (the stdlib `Array` posture): copies share the box until the first
/// mutation restores uniqueness (`ensureUnique()`); `~Copyable`-element instantiations are
/// move-only and statically unique (no CoW surface exists for them at all). Copyability flows
/// from the COLUMN: `Array<Shared<E, …Linear>>` is the value-semantic column,
/// `Array<…Linear>` stays the zero-cost move-only column.
///
/// ## The SE-0427-forced spelling
///
/// Conditional `Copyable` may not depend on `B.Element` ("conditional conformance to
/// suppressible protocol 'Copyable' cannot depend on 'B.Element: Copyable'"), so the element is
/// a DIRECT generic parameter welded to the buffer's element — and that direct parameter is
/// also what makes `Shared` the ELEMENT-KEYED CONFORMANCE CARRIER (`Equatable`/`Hashable`/…):
/// the semantics the phantom buffers faked through `S.Element` re-materialize here, where the
/// element type is genuinely first-class.
///
/// ## Teardown (the drain-box rule, R-5)
///
/// The box's class `deinit` OWNS element teardown (it drains the buffer through public mutating
/// API, closed with `_fixLifetime(self)` — the stdlib `_ContiguousArrayStorage` idiom). Never
/// rely on a struct deinit running behind a class hop: under `-O` +
/// `isKnownUniquelyReferenced`, the devirtualized destroy of a generic-namespace-nested
/// `~Copyable` struct OMITS the user deinit (the durable repro:
/// `swift-institute/Experiments/cow-box-deinit-omission-miscompile`). With the drain, the
/// storage oracle behind the box tears down an EMPTY buffer — correct whether or not it runs.
public struct Shared<
    Element: ~Copyable,
    B: Store.`Protocol` & Buffer.`Protocol` & ~Copyable
>: ~Copyable where B.Element == Element, B.Count == Index<Element>.Count {

    /// The single refcounted backing (internal — the unchecked lane lives behind the
    /// CoW-checked surface).
    @usableFromInline
    internal var box: Box<B>

    @usableFromInline
    internal init(box: Box<B>) {
        self.box = box
    }

    /// Identity of the current backing box — CoW divergence is observable here (test window).
    @usableFromInline
    package var _boxID: ObjectIdentifier { ObjectIdentifier(box) }
}

// MARK: - Conditional Conformances (co-located per [COPY-FIX-004])

/// The union, in one type: `Copyable` exactly when `Element` is (the stored property is a class
/// reference — always Copyable-layout — and the struct carries no deinit, so SE-0427 is
/// satisfied; `B` stays explicitly `~Copyable` as the diagnostic demands). For `~Copyable`
/// elements no clone path exists, so the instantiation is move-only by construction.
extension Shared: Copyable where Element: Copyable, B: ~Copyable {}

/// Sendable via the CoW discipline: a shared box is never mutated while shared — every mutation
/// path restores uniqueness first.
extension Shared: Sendable where Element: ~Copyable, B: Sendable & ~Copyable {}
