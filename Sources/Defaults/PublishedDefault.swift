import Combine

@propertyWrapper
public struct PublishedDefault<Value: _DefaultsSerializable> {
    private let key: Defaults.Key<Value>
    private var publisher: AnyPublisher<Value, Never>?
    
    private var value: Value {
        get { Defaults[key] }
        set { Defaults[key] = newValue }
    }
    
    /**
    Get/set a `Defaults` item and also trigger `objectWillChange` in the `ObservableObject` when the value changes.
     
    - Important: Like `@Published`, `@PublishedDefault` does not observe the change of the corresponding value. Only changes made via this `@PublishedDefault` will trigger `ObservableObject`'s `objectWillChange`.
     
    ```swift
    extension Defaults.Keys {
        static let opacity = Key<Double>("opacity", default: 1)
    }
     
    class ViewModel: ObservableObject {
        @PublishedDefault(.opacity) var opacity
    }
    ```
    */
    public init(_ key: Defaults.Key<Value>) {
        self.key = key
    }
    
    /**
    The getter/setter in a `ObservableObject`.
    */
    public static subscript<Object: AnyObject>(
        _enclosingInstance instance: Object,
        wrapped _: ReferenceWritableKeyPath<Object, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>
    ) -> Value {
        get {
            instance[keyPath: storageKeyPath].value
        }
        set {
            if let observable = instance as? any ObservableObject,
               let objectWillChange = observable.objectWillChange as any Publisher as? ObservableObjectPublisher
            {
                objectWillChange.send()
            }
            instance[keyPath: storageKeyPath].value = newValue
        }
    }
    
    @available(*, unavailable, message: "@Published is only available on properties of AnyObject")
    public var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }
    
    public var projectedValue: some Publisher<Value, Never> {
        mutating get {
            if publisher == nil {
                publisher = Defaults.publisher(key, options: [.initial])
                    .map(\.newValue)
                    .eraseToAnyPublisher()
            }
            return publisher!
        }
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
