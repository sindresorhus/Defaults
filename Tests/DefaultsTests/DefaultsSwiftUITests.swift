import Foundation
import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
import Testing
import Defaults
import Observation

private let suite_ = createSuite()

#if os(macOS)
typealias XColor = NSColor
#else
typealias XColor = UIColor
#endif

extension Defaults.Keys {
	fileprivate static let hasUnicorn = Key<Bool>("swiftui_hasUnicorn", default: false, suite: suite_)
	fileprivate static let user = Key<User>("swiftui_user", default: User(username: "Hank", password: "123456"), suite: suite_)
	fileprivate static let setInt = Key<Set<Int>>("swiftui_setInt", default: Set(1...3), suite: suite_)
	fileprivate static let color = Key<Color>("swiftui_color", default: .black, suite: suite_)
	fileprivate static let primarySwitchValue = Key<Bool>("swiftui_primarySwitchValue", default: false, suite: suite_)
	fileprivate static let secondarySwitchValue = Key<Bool>("swiftui_secondarySwitchValue", default: false, suite: suite_)
}

struct ContentView: View {
	@Default(.hasUnicorn) var hasUnicorn
	@Default(.user) var user
	@Default(.setInt) var setInt
	@Default(.color) var color

	var body: some View {
		Text("User \(user.username) has Unicorn: \(String(hasUnicorn))")
			.foregroundColor(color)
		Toggle("Toggle Unicorn", isOn: $hasUnicorn)
	}
}

@Observable
final class DefaultKeySwitchingState {
	var useSecondaryKey = false
}

struct KeySwitchingHostView: View {
	@Bindable var state: DefaultKeySwitchingState

	var body: some View {
		KeySwitchingDefaultView(
			key: state.useSecondaryKey ? .secondarySwitchValue : .primarySwitchValue,
			marker: state.useSecondaryKey
		)
	}
}

struct KeySwitchingDefaultView: View {
	@Default private var value: Bool
	private let marker: Bool

	init(key: Defaults.Key<Bool>, marker: Bool) {
		self.marker = marker
		_value = Default(key)
	}

	var body: some View {
		Color.clear
			.task(id: marker) {
				value = marker
			}
	}
}

@Suite(.serialized)
final class DefaultsSwiftUITests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@MainActor
	@Test
	func testSwiftUIObserve() {
		let view = ContentView()
		#expect(!view.hasUnicorn)
		#expect(view.user.username == "Hank")
		#expect(view.setInt.count == 3)
		#expect(XColor(view.color) == XColor(Color.black))

		view.user = User(username: "Chen", password: "123456")
		view.hasUnicorn.toggle()
		view.setInt.insert(4)
		view.color = Color(.sRGB, red: 100, green: 100, blue: 100, opacity: 1)

		#expect(view.hasUnicorn)
		#expect(view.user.username == "Chen")
		#expect(view.setInt == Set(1...4))
		#expect(!Default(.hasUnicorn).defaultValue)
		#expect(!Default(.hasUnicorn).isDefaultValue)
		#expect(XColor(view.color) != XColor(Color.black))
		#expect(XColor(view.color) == XColor(Color(.sRGB, red: 100, green: 100, blue: 100, opacity: 1)))
	}

	@MainActor
	@Test
	func testSwiftUIDefaultUpdatesKeyOnReinit() async throws {
		Defaults[.primarySwitchValue] = false
		Defaults[.secondarySwitchValue] = false

		let state = DefaultKeySwitchingState()

		#if os(macOS)
		let hostingController = NSHostingController(rootView: KeySwitchingHostView(state: state))
		let window = NSWindow(contentViewController: hostingController)
		window.makeKeyAndOrderFront(nil)
		#else
		let hostingController = UIHostingController(rootView: KeySwitchingHostView(state: state))
		let window = UIWindow(frame: UIScreen.main.bounds)
		window.rootViewController = hostingController
		window.makeKeyAndVisible()
		#endif

		_ = hostingController.view
		_ = window

		try await Task.sleep(for: .milliseconds(100))

		#expect(!Defaults[.primarySwitchValue])
		#expect(!Defaults[.secondarySwitchValue])

		state.useSecondaryKey = true
		try await Task.sleep(for: .milliseconds(100))

		#expect(!Defaults[.primarySwitchValue])
		#expect(Defaults[.secondarySwitchValue])
	}
}
