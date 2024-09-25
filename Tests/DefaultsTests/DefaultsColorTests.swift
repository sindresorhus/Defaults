import SwiftUI
import Testing
import Defaults

private let suite_ = createSuite()

@Suite(.serialized)
final class DefaultsColorTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, visionOS 1.0, *)
	@Test
	func testPreservesColorSpace() {
		let fixture = Color(.displayP3, red: 1, green: 0.3, blue: 0.7, opacity: 1)
		let key = Defaults.Key<Color?>("independentColorPreservesColorSpaceKey", suite: suite_)
		Defaults[key] = fixture
		#expect(Defaults[key]?.cgColor != nil)
		#expect(Defaults[key]?.cgColor?.colorSpace == fixture.cgColor?.colorSpace)
		#expect(Defaults[key]?.cgColor == fixture.cgColor)
	}
}

@Suite(.serialized)
final class DefaultsColorResolvedTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
	@Test
	func test() {
		let fixture = Color(.displayP3, red: 1, green: 0.3, blue: 0.7, opacity: 1).resolve(in: .init())
		let key = Defaults.Key<Color.Resolved?>("independentColorResolvedKey", suite: suite_)
		Defaults[key] = fixture
		#expect(Defaults[key]?.cgColor == fixture.cgColor)
	}
}
