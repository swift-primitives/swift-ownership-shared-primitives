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
public import Storage_Primitive
public import Storage_Contiguous_Primitives
public import Memory_Heap_Primitives
public import Memory_Allocator_Primitive
public import Hash_Indexed_Primitive
import Hash_Primitives

// MARK: - Construction, pinned for the ORDERED HASHED column ([MEM-COPY-017] split)
//
// The set/dictionary families' CoW column: ONE box around the COMPOSITE (dense plane +
// index engine), one clone strategy (the dense clone + the engine's seed-preserving
// plane copy — bucket positions stay valid verbatim).

extension Shared where Element: ~Copyable, B: ~Copyable {
    /// Wraps an ordered hashed column as a statically-unique (move-only element) column.
    @inlinable
    public init(_ column: consuming Hash.Indexed<Buffer<Storage<Memory.Allocator<Memory.Heap>.System>.Contiguous<Element>>.Linear>)
    where B == Hash.Indexed<Buffer<Storage<Memory.Allocator<Memory.Heap>.System>.Contiguous<Element>>.Linear>, Element: Hash.Key & SendableMetatype {
        self.init(box: Box(column, drain: { $0.removeAll(keepingCapacity: true) }))
    }
}

extension Shared where Element: Copyable, B: ~Copyable {
    /// Wraps an ordered hashed column as a shared (CoW-capable) column.
    @inlinable
    public init(_ column: consuming Hash.Indexed<Buffer<Storage<Memory.Allocator<Memory.Heap>.System>.Contiguous<Element>>.Linear>)
    where B == Hash.Indexed<Buffer<Storage<Memory.Allocator<Memory.Heap>.System>.Contiguous<Element>>.Linear>, Element: Hash.Key & SendableMetatype {
        self.init(box: Box(
            column,
            drain: { $0.removeAll(keepingCapacity: true) },
            clone: { $0.clone() }
        ))
    }
}
