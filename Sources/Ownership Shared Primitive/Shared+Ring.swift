public import Buffer_Primitive
public import Buffer_Ring_Bounded_Primitive
public import Buffer_Ring_Primitive
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Ownership_Box_Primitives
public import Storage_Contiguous_Primitives

extension Ownership.Shared where Element: ~Copyable, B: ~Copyable {

    @inlinable
    public init(
        _ buffer: consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring
    )
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring {
        self.init(box: Ownership.Box(buffer, drain: { $0.removeAll() }))
    }

    @inlinable
    public init(
        _ buffer:
            consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring
            .Bounded
    )
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring.Bounded {
        self.init(box: Ownership.Box(buffer, drain: { $0.remove.all() }))
    }
}

extension Ownership.Shared where Element: Copyable, B: ~Copyable {

    @inlinable
    public init(
        _ buffer: consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring
    )
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring {
        self.init(
            box: Ownership.Box(
                buffer,
                drain: { $0.removeAll() },
                clone: { $0.clone() }
            )
        )
    }

    @inlinable
    public init(
        _ buffer:
            consuming Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring
            .Bounded
    )
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Ring.Bounded {
        self.init(
            box: Ownership.Box(
                buffer,
                drain: { $0.remove.all() },
                clone: { $0.clone() }
            )
        )
    }
}
