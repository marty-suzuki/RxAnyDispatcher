# RxAnyDispatcher

Data flow of `Flux` is single direction. When implementing `Dispatcher` with `RxSwift`, might be using `PublishSubject`. But `PublishSubject` is at once `Observer` and `Observable`. Therefore, an `Action` can subscribe dispatcher's observables and a `Store` can observe on dispatcher's observers. Those are in the reverse direction on data flow of `Flux`. So no need to be able to call those in each class.

> ![flux.png](https://qiita-image-store.s3.amazonaws.com/0/60325/adb959fd-8b05-0d26-8323-954f5a8137ae.png)
>
> https://facebook.github.io/flux/

## Ordinary Dispatcher sample

Implementing properties with `PublishSubject`.

```swift
class SearchUserDispatcher {
    static let shared = SearchUserDispatcher()

    let loading = PublishSubject<Bool>()
    let error = PublishSubject<Error>()
    let searchUser = PublishSubject<(Int, SearchModel<User>)>()
}
```

## RxAnyDispatcher sample

Using associated values enum instead of properties.

```swift
final class SearchUserDispatcher: Dispatchable {
    enum State {
        case loading(Bool)
        case error(Error)
        case searchUser(Int, SearchModel<User>)
    }

    static let shared = SearchUserDispatcher()

    let observerState: AnyObserver<State>
    let observableState: Observable<State>

    required init() {
        (self.observerState, self.observableState) = SearchUserDispatcher.properties()
    }
}
```

Wrapping SearchUserDispatcher as AnyObserverDispatcher because no need to subscribe values in `Action`.

```swift
class SearchUserAction {
    typealias Dispatcher = AnyObserverDispatcher<SearchUserDispatcher>

    static let shared = SearchUserAction()

    private let dispatcher: Dispatcher

    init(dispatcher: Dispatcher = AnyObserverDispatcher(.shared)) {
        self.dispatcher = dispatcher
    }

    func loading(_ value: Bool) {
        self.dispatcher.state.onNext(.loading(value))
    }
}
```

Wrapping SearchUserDispatcher as AnyObservableDispatcher because no need to observe values in `Store`.

```swift
class SearchUserStore {
    typealias Dispatcher = AnyObservableDispatcher<SearchUserDispatcher>

    static let shared = SearchUserStore()

    let searchUser = Variable<SearchModel<User>>(SearchModel())
    let loading = Variable<Bool>(false)
    let error = PublishSubject<Error>()

    init(dispatcher: Dispatcher = AnyObservableDispatcher(.shared)) {
        dispatcher.state
            .subscribe(onNext: { [unowned self] in
                switch $0 {
                case .loading(let value):
                    self.loading.value = value
                case .error(let value):
                    self.error.onNext(value)
                case .searchUser(let value):
                    if value.0 == 0 {
                        self.searchUser.value = value.1
                    } else {
                        self.searchUser.value = self.searchUser.value.concat(searchModel: value.1)
                    }
                }
            })
            .addDisposableTo(disposeBag)
    }
}
```

## License

RxAnyDispatcher is available under the MIT license. See the LICENSE file for more info.
