import Foundation
import Combine

extension Defaults {
	/**
	Custom `Subscription` for `UserDefaults` key observation.
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	final class DefaultsSubscription<SubscriberType: Subscriber>: Subscription where SubscriberType.Input == BaseChange {
		private var subscriber: SubscriberType?
		private var observation: UserDefaultsKeyObservation?

		init(subscriber: SubscriberType, suite: UserDefaults, key: String, options: NSKeyValueObservingOptions) {
			self.subscriber = subscriber
			self.observation = UserDefaultsKeyObservation(
				object: suite,
				key: key,
				callback: observationCallback(_:)
			)
			self.observation?.start(options: options)
		}

		func request(_ demand: Subscribers.Demand) {
			// Nothing as we send events only when they occur.
		}

		func cancel() {
			observation?.invalidate()
			observation = nil
			subscriber = nil
		}

		private func observationCallback(_ change: BaseChange) {
			_ = subscriber?.receive(change)
		}
	}
	
	/**
	Custom Publisher, which is using DefaultsSubscription.
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	struct DefaultsPublisher: Publisher {
		typealias Output = BaseChange
		typealias Failure = Never

		private let suite: UserDefaults
		private let key: String
		private let options: NSKeyValueObservingOptions

		init(suite: UserDefaults, key: String, options: NSKeyValueObservingOptions) {
			self.suite = suite
			self.key = key
			self.options = options
		}

		func receive<S>(subscriber: S) where S : Subscriber, DefaultsPublisher.Failure == S.Failure, DefaultsPublisher.Output == S.Input {
			let subscription = DefaultsSubscription(
				subscriber: subscriber,
				suite: suite,
				key: key,
				options: options
			)

			subscriber.receive(subscription: subscription)
		}
	}

	/**
	Returns a type-erased `Publisher` that publishes changes related to the given key.

	```
	extension Defaults.Keys {
		static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
	}

	let publisher = Defaults.publisher(.isUnicornMode).map { $0.newValue }

	let cancellable = publisher.sink { value in
		print(value)
		//=> false
	}
	```
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: Codable>(
		_ key: Defaults.Key<T>,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<KeyChange<T>, Never> {
		let publisher = DefaultsPublisher(suite: key.suite, key: key.name, options: options)
			.map { KeyChange<T>(change: $0, defaultValue: key.defaultValue) }

		return AnyPublisher(publisher)
	}

	/**
	Returns a type-erased `Publisher` that publishes changes related to the given key.
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: NSSecureCoding>(
		_ key: Defaults.NSSecureCodingKey<T>,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<NSSecureCodingKeyChange<T>, Never> {
		let publisher = DefaultsPublisher(suite: key.suite, key: key.name, options: options)
			.map { NSSecureCodingKeyChange<T>(change: $0, defaultValue: key.defaultValue) }

		return AnyPublisher(publisher)
	}

	/**
	Returns a type-erased `Publisher` that publishes changes related to the given optional key.
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: Codable>(
		_ key: Defaults.OptionalKey<T>,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<OptionalKeyChange<T>, Never> {
		let publisher = DefaultsPublisher(suite: key.suite, key: key.name, options: options)
			.map { OptionalKeyChange<T>(change: $0) }

		return AnyPublisher(publisher)
	}
	
	/**
	Returns a type-erased `Publisher` that publishes changes related to the given optional key.
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: NSSecureCoding>(
		_ key: Defaults.NSSecureCodingOptionalKey<T>,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<NSSecureCodingOptionalKeyChange<T>, Never> {
		let publisher = DefaultsPublisher(suite: key.suite, key: key.name, options: options)
			.map { NSSecureCodingOptionalKeyChange<T>(change: $0) }

		return AnyPublisher(publisher)
	}

	/**
	Publisher for multiple `Key<T>` observation, but without specific information about changes.
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: Codable>(
		keys: Defaults.Key<T>...,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<Void, Never> {
		let initial = Empty<Void, Never>(completeImmediately: false).eraseToAnyPublisher()

		let combinedPublisher =
			keys.map { key in
				return Defaults.publisher(key, options: options)
					.map { _ in () }
					.eraseToAnyPublisher()
			}.reduce(initial) { (combined, keyPublisher) in
				combined.merge(with: keyPublisher).eraseToAnyPublisher()
			}

		return combinedPublisher
	}

	/**
	Publisher for multiple `OptionalKey<T>` observation, but without specific information about changes.
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: Codable>(
		keys: Defaults.OptionalKey<T>...,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<Void, Never> {
		let initial = Empty<Void, Never>(completeImmediately: false).eraseToAnyPublisher()

		let combinedPublisher =
			keys.map { key in
				return Defaults.publisher(key, options: options)
					.map { _ in () }
					.eraseToAnyPublisher()
			}.reduce(initial) { (combined, keyPublisher) in
				combined.merge(with: keyPublisher).eraseToAnyPublisher()
			}

		return combinedPublisher
	}

	/**
	Publisher for multiple `NSSecureCodingKey<T>` observation, but without specific information about changes.
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: NSSecureCoding>(
		keys: Defaults.NSSecureCodingKey<T>...,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<Void, Never> {
		let initial = Empty<Void, Never>(completeImmediately: false).eraseToAnyPublisher()

		let combinedPublisher =
			keys.map { key in
				return Defaults.publisher(key, options: options)
					.map { _ in () }
					.eraseToAnyPublisher()
			}.reduce(initial) { (combined, keyPublisher) in
				combined.merge(with: keyPublisher).eraseToAnyPublisher()
			}

		return combinedPublisher
	}

	/**
	Publisher for multiple `NSSecureCodingOptionalKey<T>` observation, but without specific information about changes.
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: NSSecureCoding>(
		keys: Defaults.NSSecureCodingOptionalKey<T>...,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<Void, Never> {
		let initial = Empty<Void, Never>(completeImmediately: false).eraseToAnyPublisher()

		let combinedPublisher =
			keys.map { key in
				return Defaults.publisher(key, options: options)
					.map { _ in () }
					.eraseToAnyPublisher()
			}.reduce(initial) { (combined, keyPublisher) in
				combined.merge(with: keyPublisher).eraseToAnyPublisher()
			}

		return combinedPublisher
	}
	
	/**
	Convenience `Publisher` for all `UserDefaults` key change events. A wrapper around the `UserDefaults.didChangeNotification`.

	- Parameter initialEvent: Trigger an initial event immediately.
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisherAll(initialEvent: Bool = true) -> AnyPublisher<Void, Never> {
		let publisher =
			NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
				.map { _ in () }
		
		if initialEvent {
			return publisher
				.prepend(())
				.eraseToAnyPublisher()
		} else {
			return publisher
				.eraseToAnyPublisher()
		}
	}
}
