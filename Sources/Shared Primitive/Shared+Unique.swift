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

public import Buffer_Primitive
public import Buffer_Linear_Primitive
public import Storage_Contiguous_Primitives
public import Memory_Heap_Primitives
public import Memory_Allocator_Primitive

// MARK: - Construction (pinned per column; the drain strategy is supplied here)

extension Shared where Element: ~Copyable, B: ~Copyable {
    /// Wraps a dense heap-linear buffer as a shared (CoW-capable) column.
    @inlinable
    public init(_ buffer: consuming Buffer<Storage<Memory.Allocator<Memory.Heap>.System>.Contiguous<Element>>.Linear)
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>.System>.Contiguous<Element>>.Linear {
        self.init(box: Box(buffer, drain: { $0.removeAll(keepingCapacity: true) }))
    }
}

// MARK: - Uniqueness (Copyable elements only — the shipping discipline)
//
// A `~Copyable`-element `Shared` is statically unique (the wrapper cannot be duplicated), so it
// carries no `isUnique`/`ensureUnique` surface at all — there is nothing to check or restore.

extension Shared where Element: Copyable, B: ~Copyable {
    /// Whether this value holds the only reference to its backing box.
    @inlinable
    public var isUnique: Bool {
        mutating get { isKnownUniquelyReferenced(&box) }
    }
}

extension Shared where Element: ~Copyable, B: ~Copyable {
    /// Ensures this value uniquely owns its backing, installing a deep copy of the live
    /// elements when the box is shared — the CoW restore, placed at the SEMANTIC boundary
    /// (every public mutation of a shared column runs through here FIRST; the seam beneath
    /// stays the unchecked fast lane).
    ///
    /// - Returns: `true` if a copy was made to restore uniqueness.
    @inlinable
    @discardableResult
    public mutating func ensureUnique() -> Bool
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>.System>.Contiguous<Element>>.Linear, Element: Copyable {
        guard !isKnownUniquelyReferenced(&box) else { return false }
        box = Box(box.wrapped.clone(), drain: { $0.removeAll(keepingCapacity: true) })
        return true
    }
}

// MARK: - The CoW-checked mutation surface (heap-linear column)

extension Shared where Element: ~Copyable, B: ~Copyable {
    /// Appends an element (grows as needed). CoW-checked for Copyable elements.
    @inlinable
    public mutating func append(_ element: consuming Element)
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>.System>.Contiguous<Element>>.Linear, Element: Copyable {
        ensureUnique()
        box.wrapped.append(element)
    }

    /// Appends an element on the statically-unique (~Copyable-element) column.
    @inlinable
    public mutating func appendAssumingUnique(_ element: consuming Element)
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>.System>.Contiguous<Element>>.Linear {
        box.wrapped.append(element)
    }

    /// Removes and returns the last element. CoW-checked for Copyable elements.
    @inlinable
    public mutating func removeLast()
        -> Element
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>.System>.Contiguous<Element>>.Linear, Element: Copyable {
        ensureUnique()
        return box.wrapped.removeLast()
    }

    /// Removes and returns the last element on the statically-unique column.
    @inlinable
    public mutating func removeLastAssumingUnique()
        -> Element
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>.System>.Contiguous<Element>>.Linear {
        box.wrapped.removeLast()
    }
}
