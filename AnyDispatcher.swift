//
//  AnyDispatcher
//  RxAnyDispatcher
//
//  Created by marty-suzuki on 2017/04/01.
//  Copyright © 2017 marty-suzuki. All rights reserved.
//

import RxSwift

public protocol Dispatchable {
    /*
     * typealias StateType = State
     *
     * // Needs to implement `State` enum at each Dispatcher.
     * eunm State {
     *     case isEnabled(Bool)
     *     case isHidden(Bool)
     * }
     */
    associatedtype StateType
    
    static var shared: Self { get }
    
    var observerState: AnyObserver<StateType> { get }
    var observableState: Observable<StateType> { get }
   
    /*
     * // Needs to implement `init()` like this at each Dispatcher.
     * init() {
     *     (self.observerState, self.observableState) = type(of: self).properties()
     * }
     */
    init()
}

public extension Dispatchable {
    static func properties() -> (observer: AnyObserver<StateType>, observable: Observable<StateType>) {
        let state = PublishSubject<StateType>()
        return (state.asObserver(), state.asObservable().shareReplayLatestWhileConnected())
    }
}

// A state observer `Dispatcher`.
public final class AnyObserverDispatcher<DispatcherType: Dispatchable>: ObserverType {
    public typealias E = DispatcherType.StateType
    
    private let state: AnyObserver<E>
    
    init(_ dispatcher: DispatcherType = .shared) {
        self.state = dispatcher.observerState
    }
    
    public func on(_ event: Event<E>) {
        state.on(event)
    }
    
    func dispatch(_ value: E) {
        on(.next(value))
    }
}

// A state observable `Dispatcher`.
public final class AnyObservableDispatcher<DispatcherType: Dispatchable>: ObservableType {
    public typealias E = DispatcherType.StateType
    
    private let state: Observable<E>
    
    init(_ dispatcher: DispatcherType = .shared) {
        self.state = dispatcher.observableState
    }
    
    public func subscribe<O : ObserverType>(_ observer: O) -> Disposable where O.E == E {
        return state.subscribe(observer)
    }
}
