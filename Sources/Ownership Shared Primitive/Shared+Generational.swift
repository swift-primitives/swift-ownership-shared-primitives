public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Ownership_Box_Primitives
public import Storage_Generational_Primitives
public import Storage_Primitive
public import Store_Primitive

extension Ownership.Shared where Element: ~Copyable, B: ~Copyable {

    @inlinable
    public init(
        _ store: consuming Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Element>
    )
    where B == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Element> {
        self.init(box: Ownership.Box(store, drain: { $0.removeAll() }))
    }
}

extension Ownership.Shared where Element: Copyable, B: ~Copyable {

    @inlinable
    public init(
        _ store: consuming Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Element>
    )
    where B == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Element> {
        self.init(
            box: Ownership.Box(
                store,
                drain: { $0.removeAll() },
                clone: { $0.clone() }
            )
        )
    }
}

extension Ownership.Shared where Element: ~Copyable, B: ~Copyable {

    @inlinable
    public mutating func insert(_ element: consuming Element) -> Store.Generational.Handle
    where B == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Element> {
        ensureUnique()
        return box.unguarded.insert(element)
    }

    @inlinable
    public mutating func remove(_ handle: Store.Generational.Handle) -> Element?
    where B == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Element> {
        ensureUnique()
        return box.unguarded.remove(handle)
    }

    @inlinable
    public subscript(_ handle: Store.Generational.Handle) -> Element
    where B == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Element> {
        _read { yield box.unguarded[handle] }
        _modify {
            ensureUnique()
            yield &box.unguarded[handle]
        }
    }

    @inlinable
    public func contains(_ handle: Store.Generational.Handle) -> Bool
    where B == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Element> {
        box.unguarded.contains(handle)
    }

    @inlinable
    public mutating func grow(to slotCapacity: Index<Element>.Count)
    where B == Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Element> {
        ensureUnique()
        box.unguarded.grow(to: slotCapacity)
    }
}
