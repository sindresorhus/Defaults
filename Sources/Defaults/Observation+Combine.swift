//
//  Observation+Combine.swift
//  Defaults-macOS
//
//  Created by Kacper Raczy on 29/12/2019.
//  Copyright © 2019 Defaults. All rights reserved.
//

#if canImport(Combine)

import Foundation
import Combine

extension Defaults {
	/**
		Custom Subscription for user defaults key observation
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	final class DefaultsSubscription<SubscriberType: Subscriber>: Subscription where SubscriberType.Input == BaseChange {
		private var subscriber: SubscriberType?
		private var observation: UserDefaultsKeyObservation?
		
		init(subscriber: SubscriberType, suite: UserDefaults, key: String, options: NSKeyValueObservingOptions) {
			self.subscriber = subscriber
			self.observation = UserDefaultsKeyObservation(object: suite, key: key, callback: observationCallback(_:))
			self.observation?.start(options: options)
		}
		
		func request(_ demand: Subscribers.Demand) {
			// nothing as we send events only when they occur
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
		Custom Publisher, which is using DefaultsSubscription
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
			let subscription = DefaultsSubscription(subscriber: subscriber,
													suite: suite,
													key: key,
													options: options)
			subscriber.receive(subscription: subscription)
		}
	}

	/**
		Returns type-erased Publisher object, publishing changes related to specified key.

		```
		extension Defaults.Keys {
			static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
		}

		let publisher = Defaults.publisher(.isUnicornMode).map { $0.newValue }
		let cancellable = publisher.sink { (value)
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
		let publisher =
			DefaultsPublisher(suite: key.suite, key: key.name, options: options)
				.map({
					return KeyChange<T>(change: $0, defaultValue: key.defaultValue)
				})
		
		return AnyPublisher(publisher)
	}

	/**
		Returns type-erased Publisher object, publishing changes related to specified key.
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: NSSecureCoding>(
		_ key: Defaults.NSSecureCodingKey<T>,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<NSSecureCodingKeyChange<T>, Never> {
		let publisher =
			DefaultsPublisher(suite: key.suite, key: key.name, options: options)
				.map({
					return NSSecureCodingKeyChange<T>(change: $0, defaultValue: key.defaultValue)
				})
		
		return AnyPublisher(publisher)
	}

	/**
		Returns type-erased Publisher object, publishing changes related to specified optional key.
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: Codable>(
		_ key: Defaults.OptionalKey<T>,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<OptionalKeyChange<T>, Never> {
		let publisher =
			DefaultsPublisher(suite: key.suite, key: key.name, options: options)
				.map({
					return OptionalKeyChange<T>(change: $0)
				})
		
		return AnyPublisher(publisher)
	}
	
	/**
		Returns type-erased Publisher object, publishing changes related to specified optional key.
	*/
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: NSSecureCoding>(
		_ key: Defaults.NSSecureCodingOptionalKey<T>,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<NSSecureCodingOptionalKeyChange<T>, Never> {
		let publisher =
			DefaultsPublisher(suite: key.suite, key: key.name, options: options)
				.map({
					return NSSecureCodingOptionalKeyChange<T>(change: $0)
				})
		
		return AnyPublisher(publisher)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisherAll() -> AnyPublisher<UserDefaults, Never> {
		let publisher = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
		return publisher
			.map { $0.object as! UserDefaults }
			.eraseToAnyPublisher()
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: Codable>(
		keys: Defaults.Key<T>...,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<Void, Never> {
		let initial =
			Empty<Void, Never>(completeImmediately: false)
				.eraseToAnyPublisher()

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

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: Codable>(
		keys: Defaults.OptionalKey<T>...,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<Void, Never> {
		let initial =
			Empty<Void, Never>(completeImmediately: false)
				.eraseToAnyPublisher()

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

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: NSSecureCoding>(
		keys: Defaults.NSSecureCodingKey<T>...,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<Void, Never> {
		let initial =
			Empty<Void, Never>(completeImmediately: false)
				.eraseToAnyPublisher()

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

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	public static func publisher<T: NSSecureCoding>(
		keys: Defaults.NSSecureCodingOptionalKey<T>...,
		options: NSKeyValueObservingOptions = [.initial, .old, .new]
	) -> AnyPublisher<Void, Never> {
		let initial =
			Empty<Void, Never>(completeImmediately: false)
				.eraseToAnyPublisher()

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
}

#endif
