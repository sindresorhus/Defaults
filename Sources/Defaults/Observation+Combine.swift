import Foundation
import Combine

extension Defaults {
	/**
	Custom `Subscription` for `UserDefaults` key observation.
	*/
	final class DefaultsSubscription<SubscriberType: Subscriber>: Subscription where SubscriberType.Input == BaseChange {
		private var subscriber: SubscriberType?
		private var observation: UserDefaultsKeyObservation?
		private let options: ObservationOptions

		init(subscriber: SubscriberType, suite: UserDefaults, key: String, options: ObservationOptions) {
			self.subscriber = subscriber
			self.options = options
			self.observation = UserDefaultsKeyObservation(
				object: suite,
				key: key,
				callback: observationCallback(_:)
			)
		}

		func request(_ demand: Subscribers.Demand) {
			// Nothing as we send events only when they occur.
		}

		func cancel() {
			observation = nil
			subscriber = nil
		}

		func start() {
			observation?.start(options: options)
		}

		private func observationCallback(_ change: BaseChange) {
			_ = subscriber?.receive(change)
		}
	}

	/**
	Custom Publisher, which is using DefaultsSubscription.
	*/
	struct DefaultsPublisher: Publisher {
		typealias Output = BaseChange
		typealias Failure = Never

		private let suite: UserDefaults
		private let key: String
		private let options: ObservationOptions

		init(suite: UserDefaults, key: String, options: ObservationOptions) {
			self.suite = suite
			self.key = key
			self.options = options
		}

		func receive(subscriber: some Subscriber<Output, Failure>) {
			let subscription = DefaultsSubscription(
				subscriber: subscriber,
				suite: suite,
				key: key,
				options: options
			)

			subscriber.receive(subscription: subscription)
			subscription.start()
		}
	}

	/**
	Returns a type-erased `Publisher` that publishes changes related to the given key.

	```swift
	extension Defaults.Keys {
		static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
	}

	let publisher = Defaults.publisher(.isUnicornMode).map(\.newValue)

	let cancellable = publisher.sink { value in
		print(value)
		//=> false
	}
	```

	- Warning: This method exists for backwards compatibility and will be deprecated sometime in the future. Use ``Defaults/updates(_:initial:)-88orv`` instead.
	*/
	public static func publisher<Value: Serializable>(
		_ key: Key<Value>,
		options: ObservationOptions = [.initial]
	) -> AnyPublisher<KeyChange<Value>, Never> {
		let publisher = DefaultsPublisher(suite: key.suite, key: key.name, options: options)
			.map { KeyChange<Value>(change: $0, defaultValue: key.defaultValue) }

		return AnyPublisher(publisher)
	}

	/**
	Publisher for multiple `Key<T>` observation, but without specific information about changes.

	- Warning: This method exists for backwards compatibility and will be deprecated sometime in the future. Use ``Defaults/updates(_:initial:)-88orv`` instead.
	*/
	public static func publisher(
		keys: [_AnyKey],
		options: ObservationOptions = [.initial]
	) -> AnyPublisher<Void, Never> {
		let initial = Empty<Void, Never>(completeImmediately: false).eraseToAnyPublisher()

		return
			keys
				.map { key in
					DefaultsPublisher(suite: key.suite, key: key.name, options: options)
						.map { _ in () }
						.eraseToAnyPublisher()
				}
				.reduce(initial) { combined, keyPublisher in
					combined.merge(with: keyPublisher).eraseToAnyPublisher()
				}
	}

	/**
	Publisher for multiple `Key<T>` observation, but without specific information about changes.

	- Warning: This method exists for backwards compatibility and will be deprecated sometime in the future. Use ``Defaults/updates(_:initial:)-88orv`` instead.
	*/
	public static func publisher(
		keys: _AnyKey...,
		options: ObservationOptions = [.initial]
	) -> AnyPublisher<Void, Never> {
		publisher(keys: keys, options: options)
	}
}
