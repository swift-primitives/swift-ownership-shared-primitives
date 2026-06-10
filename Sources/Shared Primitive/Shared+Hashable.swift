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

public import Index_Primitives
import Ordinal_Primitives_Standard_Library_Integration
import Affine_Primitives_Standard_Library_Integration

// Element-keyed carrier — see `Shared+Equatable.swift` for the re-materialization note.

extension Shared: Hashable where Element: Hashable, B: ~Copyable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(Int(bitPattern: count.underlying.rawValue))
        var slot: Index<Element> = .zero
        let end = count.map(Ordinal.init)
        while slot < end {
            hasher.combine(self[slot])
            slot += .one
        }
    }
}
