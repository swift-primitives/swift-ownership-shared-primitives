public import Buffer_Linear_Primitive
public import Buffer_Primitive
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Ownership_Box_Primitives
public import Storage_Contiguous_Primitives

extension Ownership.Shared where Element: ~Copyable, B: ~Copyable {

    @inlinable
    public func withSpan<R, Failure: Swift.Error>(
        _ body: (Swift.Span<Element>) throws(Failure) -> R
    ) throws(Failure) -> R
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear {
        try Self._withSpan(box.unguarded, body)
    }

    @inlinable
    public mutating func withMutableSpan<R, Failure: Swift.Error>(
        _ body: (inout Swift.MutableSpan<Element>) throws(Failure) -> R
    ) throws(Failure) -> R
    where
        B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear,
        Element: Copyable
    {
        ensureUnique()
        return try Self._withMutableSpan(&box.unguarded, body)
    }

    @inlinable
    public mutating func withMutableSpanAssumingUnique<R, Failure: Swift.Error>(
        _ body: (inout Swift.MutableSpan<Element>) throws(Failure) -> R
    ) throws(Failure) -> R
    where B == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear {
        assert(box.isUnique, "AssumingUnique on a shared box")
        return try Self._withMutableSpan(&box.unguarded, body)
    }

    @inlinable
    package static func _withSpan<R, Failure: Swift.Error>(
        _ buffer:
            borrowing Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear,
        _ body: (Swift.Span<Element>) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(buffer.span)
    }

    @inlinable
    package static func _withMutableSpan<R, Failure: Swift.Error>(
        _ buffer: inout Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear,
        _ body: (inout Swift.MutableSpan<Element>) throws(Failure) -> R
    ) throws(Failure) -> R {
        var span = buffer.mutableSpan
        return try body(&span)
    }
}
