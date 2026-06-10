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

public import Store_Protocol_Primitives
public import Buffer_Protocol_Primitives
public import Index_Primitives

// MARK: - The seam (the UNCHECKED lane) + the count surface
//
// `Shared` forwards the 4-op seam through the box so seam-generic composition reaches the
// shared column uniformly. The MUTABLE half of this surface performs NO uniqueness check —
// mutating a SHARED box through it aliases the other value (the stdlib unchecked-buffer-path
// shape). The CoW-checked public surface (`Shared+Unique.swift`) is the semantic boundary;
// ADTs route their mutations through it FIRST and may then use the seam as the fast lane.

extension Shared: Store.`Protocol` where Element: ~Copyable, B: ~Copyable {
    @inlinable
    public var capacity: Index<Element>.Count { box.wrapped.capacity }

    @inlinable
    public subscript(slot: Index<Element>) -> Element {
        _read { yield box.wrapped[slot] }
        _modify { yield &box.wrapped[slot] }
    }

    @inlinable
    public mutating func initialize(at slot: Index<Element>, to element: consuming Element) {
        box.wrapped.initialize(at: slot, to: element)
    }

    @inlinable
    public mutating func move(at slot: Index<Element>) -> Element {
        box.wrapped.move(at: slot)
    }
}

extension Shared: Buffer.`Protocol` where Element: ~Copyable, B: ~Copyable {
    public typealias Count = Index<Element>.Count

    /// The number of live elements (forwarded from the wrapped buffer's cursor).
    @inlinable
    public var count: Index<Element>.Count { box.wrapped.count }
}
