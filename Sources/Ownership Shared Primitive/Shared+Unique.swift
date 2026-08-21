public import Buffer_Linear_Primitive
public import Buffer_Primitive
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Ownership_Box_Primitives
public import Storage_Contiguous_Primitives

extension Ownership.Shared where Element: ~Copyable, B: ~Copyable {

    @inlinable
    public init(
        _ buffer:
            consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear
    )
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear {
        self.init(box: Ownership.Box(buffer, drain: { $0.removeAll(keepingCapacity: true) }))
    }
}

extension Ownership.Shared where Element: Copyable, B: ~Copyable {

    @inlinable
    public init(
        _ buffer:
            consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear
    )
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear {
        self.init(
            box: Ownership.Box(
                buffer,
                drain: { $0.removeAll(keepingCapacity: true) },
                clone: { $0.clone() }
            )
        )
    }
}

extension Ownership.Shared where Element: Copyable, B: ~Copyable {

    @inlinable
    public var isUnique: Bool {
        mutating get { box.isUnique }
    }
}

extension Ownership.Shared where Element: ~Copyable, B: ~Copyable {

    @inlinable
    @discardableResult
    public mutating func ensureUnique() -> Bool {

        box.ensureUnique()
    }
}

extension Ownership.Shared where Element: ~Copyable, B: ~Copyable {

    @inlinable
    public mutating func append(_ element: consuming Element)
    where
        B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear,
        Element: Copyable
    {
        ensureUnique()
        box.unguarded.append(element)
    }

    @inlinable
    public mutating func appendAssumingUnique(_ element: consuming Element)
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear {
        assert(box.isUnique, "AssumingUnique on a shared box")
        box.unguarded.append(element)
    }

    @inlinable
    public mutating func removeLast()
        -> Element
    where
        B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear,
        Element: Copyable
    {
        ensureUnique()
        return box.unguarded.removeLast()
    }

    @inlinable
    public mutating func removeLastAssumingUnique()
        -> Element
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear {
        assert(box.isUnique, "AssumingUnique on a shared box")
        return box.unguarded.removeLast()
    }

    @inlinable
    public mutating func reserveCapacity(_ minimumCapacity: Index<Element>.Count)
    where
        B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear,
        Element: Copyable
    {
        ensureUnique()
        box.unguarded.reserveCapacity(minimumCapacity)
    }

    @inlinable
    public mutating func reallocate(capacity newCapacity: Index<Element>.Count)
    where
        B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear,
        Element: Copyable
    {
        ensureUnique()
        box.unguarded.reallocate(capacity: newCapacity)
    }
}
