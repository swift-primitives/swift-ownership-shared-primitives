import Buffer_Linear_Bounded_Primitive
import Buffer_Linear_Primitive
import Buffer_Primitive
import Index_Primitives
import Memory_Allocator_Primitive
import Memory_Heap_Primitives
import Ownership_Shared_Primitive
import Storage_Contiguous_Primitives
import Synchronization
import Testing

private typealias HeapColumn<E: ~Copyable> =
    Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Linear
private typealias SharedColumn<E: ~Copyable> = Ownership.Shared<E, HeapColumn<E>>
private typealias BoundedColumn<E: ~Copyable> =
    Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Linear.Bounded
private typealias SharedBounded<E: ~Copyable> = Ownership.Shared<E, BoundedColumn<E>>

private func makeShared<E>(capacity: UInt) -> SharedColumn<E> {
    SharedColumn<E>(HeapColumn<E>(minimumCapacity: Index<E>.Count(capacity)))
}

private enum Ledger {}

extension Ledger {
    static let created = Atomic<Int>(0)
    static let destroyed = Atomic<Int>(0)
    static func reset() {
        created.store(0, ordering: .sequentiallyConsistent)
        destroyed.store(0, ordering: .sequentiallyConsistent)
    }
}

private final class Payload: Sendable {
    let value: Int
    init(_ value: Int) {
        self.value = value
        _ = Ledger.created.wrappingAdd(1, ordering: .relaxed)
    }
    deinit {
        _ = Ledger.destroyed.wrappingAdd(1, ordering: .relaxed)
    }
}

@Suite
struct `Shared Concurrency Detach Trivial Tests` {

    @Test(arguments: [2, 8, 32])
    func `concurrent mutate-detach: every sibling matches its forked model`(width: Int) async {
        var proto: SharedColumn<Int> = makeShared(capacity: 16)
        for i in 0..<8 { proto.append(i) }
        let frozen = proto
        let outcomes = await withTaskGroup(of: (Int, [Int]).self, returning: [Int: [Int]].self) {
            group in
            for t in 0..<width {
                group.addTask {
                    var mine = frozen
                    mine.append(100 &+ t)
                    mine.withMutableSpan { span in
                        for i in 0..<span.count { span[i] &+= t }
                    }
                    _ = mine.removeLast()
                    let snapshot = mine.withSpan { span in
                        var out: [Int] = []
                        out.reserveCapacity(span.count)
                        for i in 0..<span.count { out.append(span[i]) }
                        return out
                    }
                    return (t, snapshot)
                }
            }
            var collected: [Int: [Int]] = [:]
            for await (t, snapshot) in group { collected[t] = snapshot }
            return collected
        }
        #expect(outcomes.count == width)
        for t in 0..<width {
            var model = Array(0..<8)
            model.append(100 &+ t)
            model = model.map { $0 &+ t }
            model.removeLast()
            #expect(outcomes[t] == model)
        }
        let source = proto.withSpan { span in
            var out: [Int] = []
            for i in 0..<span.count { out.append(span[i]) }
            return out
        }
        #expect(source == Array(0..<8))
    }

    @Test(arguments: [2, 8])
    func `bounded column: concurrent detach preserves capacity exactly`(width: Int) async {
        var proto = SharedBounded<Int>(BoundedColumn<Int>(minimumCapacity: Index<Int>.Count(8)))
        proto.initialize(at: 0, to: 10)
        proto.initialize(at: 1, to: 11)
        let frozen = proto
        let outcomes = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for t in 0..<width {
                group.addTask {
                    var mine = frozen
                    mine[0] = 1000 &+ t
                    let mine0 = mine[0]
                    let mine1 = mine[1]
                    let theirs0 = frozen[0]
                    let capacityPreserved = (mine.capacity == frozen.capacity)
                    return mine0 == 1000 &+ t && mine1 == 11 && theirs0 == 10 && capacityPreserved
                }
            }
            var out: [Bool] = []
            for await ok in group { out.append(ok) }
            return out
        }
        #expect(outcomes.count == width)
        #expect(outcomes.allSatisfy { $0 })
        let source0 = proto[0]
        #expect(source0 == 10)
    }
}

@Suite(.serialized)
struct `Shared Concurrency Detach Teardown Tests` {

    @Test
    func `refcounted elements: exact teardown after a concurrent detach storm`() async {
        Ledger.reset()
        do {
            var proto: SharedColumn<Payload> = makeShared(capacity: 16)
            for i in 0..<8 { proto.append(Payload(i)) }
            let frozen = proto
            let checks = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
                for t in 0..<16 {
                    group.addTask {
                        var mine = frozen
                        mine.append(Payload(100 &+ t))
                        mine.withMutableSpan { span in
                            for i in 0..<span.count where i % 2 == 0 {
                                span[i] = Payload(span[i].value &+ 1000)
                            }
                        }

                        let values = mine.withSpan { span in
                            var out: [Int] = []
                            out.reserveCapacity(span.count)
                            for i in 0..<span.count { out.append(span[i].value) }
                            return out
                        }
                        var model: [Int] = []
                        for i in 0..<8 { model.append(i % 2 == 0 ? i &+ 1000 : i) }
                        model.append(1100 &+ t)
                        return values == model
                    }
                }
                var out: [Bool] = []
                for await ok in group { out.append(ok) }
                return out
            }
            #expect(checks.count == 16)
            #expect(checks.allSatisfy { $0 })
        }

        let created = Ledger.created.load(ordering: .sequentiallyConsistent)
        let destroyed = Ledger.destroyed.load(ordering: .sequentiallyConsistent)
        #expect(created == 104)
        #expect(destroyed == created)
    }
}
