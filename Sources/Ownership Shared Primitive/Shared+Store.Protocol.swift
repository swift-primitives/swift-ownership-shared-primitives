public import Buffer_Protocol_Primitives
public import Index_Primitives
public import Ownership_Box_Primitives
public import Store_Protocol_Primitives

extension Ownership.Shared: Store.`Protocol` where Element: ~Copyable, B: ~Copyable {

    @inlinable
    public var capacity: Index<Element>.Count { box.unguarded.capacity }

    @inlinable
    public subscript(slot: Index<Element>) -> Element {
        _read { yield box.unguarded[slot] }
        _modify {
            ensureUnique()
            yield &box.unguarded[slot]
        }
    }

    @inlinable
    public mutating func initialize(at slot: Index<Element>, to element: consuming Element) {
        ensureUnique()
        box.unguarded.initialize(at: slot, to: element)
    }

    @inlinable
    public mutating func move(at slot: Index<Element>) -> Element {
        ensureUnique()
        return box.unguarded.move(at: slot)
    }

    @inlinable
    public mutating func swapAt(_ i: Index<Element>, _ j: Index<Element>) {
        ensureUnique()
        box.unguarded.swapAt(i, j)
    }

    @inlinable
    public mutating func unshare() {
        ensureUnique()
    }
}

extension Ownership.Shared: Buffer.`Protocol` where Element: ~Copyable, B: ~Copyable {

    @inlinable
    public var count: Index<Element>.Count { box.unguarded.count }
}
