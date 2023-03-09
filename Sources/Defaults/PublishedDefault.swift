import Combine

/**
PublishedDefault will trigger `objectWillChange` in the `ObservableObject` when the value is changed.

- Important: By default, `PublishedDefault` does not observe changes made to the corresponding value outside of the `PublishedDefault`.
Only changes made via this `@PublishedDefault` will trigger `objectWillChange`.

To ensure that changes made to Defaults elsewhere also trigger `objectWillChange`, you need to call `observeDefaults` once in the `ObservableObject`.

```swift
extension Defaults.Keys {
    static let opacity = Key<Double>("opacity", default: 1)
}

class ViewModel: ObservableObject {
    @PublishedDefault(.opacity) var opacity

    init() {
        observeDefaults()
    }
}
```
*/
@propertyWrapper
public class PublishedDefault<Value: _DefaultsSerializable> {
    private let key: Defaults.Key<Value>
    private var defaultPublisher: AnyPublisher<Value, Never>?
    private var objectSubscription: AnyCancellable?

    private var value: Value {
        get { Defaults[key] }
        set { Defaults[key] = newValue }
    }

    public init(_ key: Defaults.Key<Value>) {
        self.key = key
    }

    /**
    The getter/setter in a `ObservableObject`.
    */
    public static subscript<Object: AnyObject>(
        _enclosingInstance instance: Object,
        wrapped _: ReferenceWritableKeyPath<Object, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Object, PublishedDefault>
    ) -> Value {
        get {
            instance[keyPath: storageKeyPath].value
        }
        set {
            // Skip if subscrition is already acting
            if instance[keyPath: storageKeyPath].objectSubscription == nil,
               let observable = instance as? any ObservableObject,
               let objectWillChange = observable.objectWillChange as any Publisher as? ObservableObjectPublisher
            {
                objectWillChange.send()
            }
            instance[keyPath: storageKeyPath].value = newValue
        }
    }

    @available(*, unavailable, message: "@PublishedDefault is only available on properties of AnyObject")
    public var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }

    public var projectedValue: some Publisher<Value, Never> {
        if defaultPublisher == nil {
            defaultPublisher = Defaults.publisher(key, options: [.initial])
                .map(\.newValue)
                .eraseToAnyPublisher()
        }
        return defaultPublisher!
    }

    /**
    Reset the key back to its default value.

    ```swift
    extension Defaults.Keys {
        static let opacity = Key<Double>("opacity", default: 1)
    }

    class ViewModel: ObservableObject {
        @PublishedDefault(.opacity) var opacity

        func reset() {
            _opacity.reset()
        }
    }
    ```
    */
    public func reset() {
        key.reset()
    }
}

// A type-erase protocol used to subscribe Defaults on ObservableObject.
protocol _PublishedDefaultProtocol {
    func subscribe(to publisher: ObservableObjectPublisher)
}

extension PublishedDefault: _PublishedDefaultProtocol {
    func subscribe(to publisher: ObservableObjectPublisher) {
        objectSubscription = projectedValue
            .dropFirst()
            .sink { _ in
                publisher.send()
            }
    }
}

public extension ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
    /**
    Begin observing the Default value so that changes made to Defaults outside of the ObservableObject will also trigger objectWillChange.
    */
    func observeDefaults() {
        for (_, property) in Mirror(reflecting: self).children {
            (property as? _PublishedDefaultProtocol)?.subscribe(to: objectWillChange)
        }
    }
}
