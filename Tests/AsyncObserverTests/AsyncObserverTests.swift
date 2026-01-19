import Foundation
import Testing
@testable import AsyncObserver

@Test func addObserverReturnsUniqueTokenAndTracksCount() async {
    let observable = TestObservable()
    
    let id1 = await observable.addAsyncObserver { _ in }
    let id2 = await observable.addAsyncObserver { _ in }
    
    #expect(id1 != id2)
    #expect(await observable.observerCount() == 2)
}

@Test func removeObserverStopsNotifications() async {
    let observable = TestObservable()
    let box = ValueBox()
    
    let token = await observable.addAsyncObserver { value in
        await box.append(value)
    }
    await observable.removeAsyncObserver(id: token)
    
    await observable.notifyAsyncObservers(99)
    let didStayEmpty = await waitUntil({ await box.count() == 0 }, timeout: 0.2)
    
    #expect(didStayEmpty)
}

@Test func notifyInvokesAllObservers() async {
    let observable = TestObservable()
    let box = ValueBox()
    
    _ = await observable.addAsyncObserver { value in
        await box.append(value)
    }
    _ = await observable.addAsyncObserver { value in
        await box.append(value)
    }
    
    await observable.notifyAsyncObservers(5)
    let didReceiveAll = await waitUntil({ await box.count() == 2 })
    
    #expect(didReceiveAll)
    #expect(await box.all().allSatisfy { $0 == 5 })
}

@Test func realWorldMutationTriggersNotifications() async {
    let scheduler = TestScheduler()
    let box = ValueBox()
    
    _ = await scheduler.addAsyncObserver { jobs in
        await box.appendSnapshot(jobs)
    }
    
    await scheduler.setJobs([1, 2, 3])
    let didReceive = await waitUntil({ await box.snapshotCount() == 1 })
    
    #expect(didReceive)
    #expect(await box.allSnapshots().first == [1, 2, 3])
}

@Test func realWorldRemoveObserverStopsFurtherMutationNotifications() async {
    let scheduler = TestScheduler()
    let box = ValueBox()
    
    let token = await scheduler.addAsyncObserver { jobs in
        await box.appendSnapshot(jobs)
    }
    
    await scheduler.setJobs([1])
    _ = await waitUntil({ await box.snapshotCount() == 1 })
    
    await scheduler.removeAsyncObserver(id: token)
    
    await scheduler.setJobs([1, 2])
    let didStayAtOne = await waitUntil({ await box.snapshotCount() == 1 }, timeout: 0.2)
    
    #expect(didStayAtOne)
    #expect(await box.allSnapshots().count == 1)
    #expect(await box.allSnapshots().first == [1])
}

private actor TestScheduler: AsyncObservable {
    
    var asyncObservers: [AsyncObserver<[Int]>] = []
    
    private var jobs: [Int] = [] {
        didSet {
            notifyAsyncObservers(jobs)
        }
    }
    
    func setJobs(_ newValue: [Int]) {
        jobs = newValue
    }
}

private actor TestObservable: AsyncObservable {
    
    var asyncObservers: [AsyncObserver<Int>] = []
    
    func observerCount() -> Int {
        asyncObservers.count
    }
}

private actor ValueBox {
    private var values: [Int] = []
    private var snapshots: [[Int]] = []
    
    func append(_ value: Int) {
        values.append(value)
    }
    
    func appendSnapshot(_ value: [Int]) {
        snapshots.append(value)
    }
    
    func count() -> Int {
        values.count
    }
    
    func snapshotCount() -> Int {
        snapshots.count
    }
    
    func allSnapshots() -> [[Int]] {
        snapshots
    }
    
    func all() -> [Int] {
        values
    }
}

private func waitUntil(
    _ condition: @escaping () async -> Bool,
    timeout: TimeInterval = 1.0
) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while !(await condition()) && Date() < deadline {
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
    return await condition()
}
