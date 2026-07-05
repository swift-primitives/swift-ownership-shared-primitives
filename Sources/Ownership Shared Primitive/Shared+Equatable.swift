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

// MARK: - Element-keyed semantics (the W4 re-materialization)
//
// The phantom buffers carried these conformances through the `S.Element` lie; the truthful
// columns cannot. `Shared`'s DIRECT `Element` parameter restores them lawfully — and ADTs
// chain via S5 (`Array<S>: Equatable where S: Equatable`). The walks read the live prefix
// `[0, count)` through the seam (the linear-family contract; wrapped/sparse disciplines get
// their carriers with their own ADT columns).

extension Ownership.Shared: Equatable where Element: Equatable, B: ~Copyable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var slot: Index<Element> = .zero
        let end = lhs.count.map(Ordinal.init)
        while slot < end {
            guard lhs[slot] == rhs[slot] else { return false }
            slot += .one
        }
        return true
    }
}
