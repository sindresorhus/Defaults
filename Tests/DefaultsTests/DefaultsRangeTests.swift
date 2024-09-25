import Foundation
import Testing
import Defaults

private let suite_ = createSuite()

private struct CustomDate {
	let year: Int
	let month: Int
	let day: Int
}

extension CustomDate: Defaults.Serializable {
	public struct CustomDateBridge: Defaults.Bridge {
		public typealias Value = CustomDate
		public typealias Serializable = [Int]

		public func serialize(_ value: Value?) -> Serializable? {
			guard let value else {
				return nil
			}

			return [value.year, value.month, value.day]
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			guard let object else {
				return nil
			}

			return .init(year: object[0], month: object[1], day: object[2])
		}
	}

	public static let bridge = CustomDateBridge()
}

extension CustomDate: Comparable {
	static func < (lhs: CustomDate, rhs: CustomDate) -> Bool {
		if lhs.year != rhs.year {
			return lhs.year < rhs.year
		}

		if lhs.month != rhs.month {
			return lhs.month < rhs.month
		}

		return lhs.day < rhs.day
	}

	static func == (lhs: CustomDate, rhs: CustomDate) -> Bool {
		lhs.year == rhs.year && lhs.month == rhs.month
			&& lhs.day == rhs.day
	}
}

// Fixtures:
private let fixtureRange = 0..<10
private let nextFixtureRange = 1..<20
private let fixtureDateRange = CustomDate(year: 2022, month: 4, day: 0)..<CustomDate(year: 2022, month: 5, day: 0)
private let nextFixtureDateRange = CustomDate(year: 2022, month: 6, day: 1)..<CustomDate(year: 2022, month: 7, day: 1)
private let fixtureClosedRange = 0...10
private let nextFixtureClosedRange = 1...20
private let fixtureDateClosedRange = CustomDate(year: 2022, month: 4, day: 0)...CustomDate(year: 2022, month: 5, day: 0)
private let nextFixtureDateClosedRange = CustomDate(year: 2022, month: 6, day: 1)...CustomDate(year: 2022, month: 7, day: 1)

@Suite(.serialized)
final class DefaultsClosedRangeTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testKey() {
		// Test native support Range type
		let key = Defaults.Key<Range>("independentRangeKey", default: fixtureRange, suite: suite_)
		#expect(fixtureRange.upperBound == Defaults[key].upperBound)
		#expect(fixtureRange.lowerBound == Defaults[key].lowerBound)
		Defaults[key] = nextFixtureRange
		#expect(nextFixtureRange.upperBound == Defaults[key].upperBound)
		#expect(nextFixtureRange.lowerBound == Defaults[key].lowerBound)

		// Test serializable Range type
		let dateKey = Defaults.Key<Range<CustomDate>>("independentRangeDateKey", default: fixtureDateRange, suite: suite_)
		#expect(fixtureDateRange.upperBound == Defaults[dateKey].upperBound)
		#expect(fixtureDateRange.lowerBound == Defaults[dateKey].lowerBound)
		Defaults[dateKey] = nextFixtureDateRange
		#expect(nextFixtureDateRange.upperBound == Defaults[dateKey].upperBound)
		#expect(nextFixtureDateRange.lowerBound == Defaults[dateKey].lowerBound)

		// Test native support ClosedRange type
		let closedKey = Defaults.Key<ClosedRange>("independentClosedRangeKey", default: fixtureClosedRange, suite: suite_)
		#expect(fixtureClosedRange.upperBound == Defaults[closedKey].upperBound)
		#expect(fixtureClosedRange.lowerBound == Defaults[closedKey].lowerBound)
		Defaults[closedKey] = nextFixtureClosedRange
		#expect(nextFixtureClosedRange.upperBound == Defaults[closedKey].upperBound)
		#expect(nextFixtureClosedRange.lowerBound == Defaults[closedKey].lowerBound)

		// Test serializable ClosedRange type
		let closedDateKey = Defaults.Key<ClosedRange<CustomDate>>("independentClosedRangeDateKey", default: fixtureDateClosedRange, suite: suite_)
		#expect(fixtureDateClosedRange.upperBound == Defaults[closedDateKey].upperBound)
		#expect(fixtureDateClosedRange.lowerBound == Defaults[closedDateKey].lowerBound)
		Defaults[closedDateKey] = nextFixtureDateClosedRange
		#expect(nextFixtureDateClosedRange.upperBound == Defaults[closedDateKey].upperBound)
		#expect(nextFixtureDateClosedRange.lowerBound == Defaults[closedDateKey].lowerBound)
	}

	@Test
	func testOptionalKey() {
		// Test native support Range type
		let key = Defaults.Key<Range<Int>?>("independentRangeOptionalKey", suite: suite_)
		#expect(Defaults[key] == nil)
		Defaults[key] = fixtureRange
		#expect(fixtureRange.upperBound == Defaults[key]?.upperBound)
		#expect(fixtureRange.lowerBound == Defaults[key]?.lowerBound)

		// Test serializable Range type
		let dateKey = Defaults.Key<Range<CustomDate>?>("independentRangeDateOptionalKey", suite: suite_)
		#expect(Defaults[dateKey] == nil)
		Defaults[dateKey] = fixtureDateRange
		#expect(fixtureDateRange.upperBound == Defaults[dateKey]?.upperBound)
		#expect(fixtureDateRange.lowerBound == Defaults[dateKey]?.lowerBound)

		// Test native support ClosedRange type
		let closedKey = Defaults.Key<ClosedRange<Int>?>("independentClosedRangeOptionalKey", suite: suite_)
		#expect(Defaults[closedKey] == nil)
		Defaults[closedKey] = fixtureClosedRange
		#expect(fixtureClosedRange.upperBound == Defaults[closedKey]?.upperBound)
		#expect(fixtureClosedRange.lowerBound == Defaults[closedKey]?.lowerBound)

		// Test serializable ClosedRange type
		let closedDateKey = Defaults.Key<ClosedRange<CustomDate>?>("independentClosedRangeDateOptionalKey", suite: suite_)
		#expect(Defaults[closedDateKey] == nil)
		Defaults[closedDateKey] = fixtureDateClosedRange
		#expect(fixtureDateClosedRange.upperBound == Defaults[closedDateKey]?.upperBound)
		#expect(fixtureDateClosedRange.lowerBound == Defaults[closedDateKey]?.lowerBound)
	}

	@Test
	func testArrayKey() {
		// Test native support Range type
		let key = Defaults.Key<[Range]>("independentRangeArrayKey", default: [fixtureRange], suite: suite_)
		#expect(fixtureRange.upperBound == Defaults[key][0].upperBound)
		#expect(fixtureRange.lowerBound == Defaults[key][0].lowerBound)
		Defaults[key].append(nextFixtureRange)
		#expect(fixtureRange.upperBound == Defaults[key][0].upperBound)
		#expect(fixtureRange.lowerBound == Defaults[key][0].lowerBound)
		#expect(nextFixtureRange.upperBound == Defaults[key][1].upperBound)
		#expect(nextFixtureRange.lowerBound == Defaults[key][1].lowerBound)

		// Test serializable Range type
		let dateKey = Defaults.Key<[Range<CustomDate>]>("independentRangeDateArrayKey", default: [fixtureDateRange], suite: suite_)
		#expect(fixtureDateRange.upperBound == Defaults[dateKey][0].upperBound)
		#expect(fixtureDateRange.lowerBound == Defaults[dateKey][0].lowerBound)
		Defaults[dateKey].append(nextFixtureDateRange)
		#expect(fixtureDateRange.upperBound == Defaults[dateKey][0].upperBound)
		#expect(fixtureDateRange.lowerBound == Defaults[dateKey][0].lowerBound)
		#expect(nextFixtureDateRange.upperBound == Defaults[dateKey][1].upperBound)
		#expect(nextFixtureDateRange.lowerBound == Defaults[dateKey][1].lowerBound)

		// Test native support ClosedRange type
		let closedKey = Defaults.Key<[ClosedRange]>("independentClosedRangeArrayKey", default: [fixtureClosedRange], suite: suite_)
		#expect(fixtureClosedRange.upperBound == Defaults[closedKey][0].upperBound)
		#expect(fixtureClosedRange.lowerBound == Defaults[closedKey][0].lowerBound)
		Defaults[closedKey].append(nextFixtureClosedRange)
		#expect(fixtureClosedRange.upperBound == Defaults[closedKey][0].upperBound)
		#expect(fixtureClosedRange.lowerBound == Defaults[closedKey][0].lowerBound)
		#expect(nextFixtureClosedRange.upperBound == Defaults[closedKey][1].upperBound)
		#expect(nextFixtureClosedRange.lowerBound == Defaults[closedKey][1].lowerBound)

		// Test serializable ClosedRange type
		let closedDateKey = Defaults.Key<[ClosedRange<CustomDate>]>("independentClosedRangeDateArrayKey", default: [fixtureDateClosedRange], suite: suite_)
		#expect(fixtureDateClosedRange.upperBound == Defaults[closedDateKey][0].upperBound)
		#expect(fixtureDateClosedRange.lowerBound == Defaults[closedDateKey][0].lowerBound)
		Defaults[closedDateKey].append(nextFixtureDateClosedRange)
		#expect(fixtureDateClosedRange.upperBound == Defaults[closedDateKey][0].upperBound)
		#expect(fixtureDateClosedRange.lowerBound == Defaults[closedDateKey][0].lowerBound)
		#expect(nextFixtureDateClosedRange.upperBound == Defaults[closedDateKey][1].upperBound)
		#expect(nextFixtureDateClosedRange.lowerBound == Defaults[closedDateKey][1].lowerBound)
	}

	@Test
	func testDictionaryKey() {
		// Test native support Range type
		let key = Defaults.Key<[String: Range]>("independentRangeDictionaryKey", default: ["0": fixtureRange], suite: suite_)
		#expect(fixtureRange.upperBound == Defaults[key]["0"]?.upperBound)
		#expect(fixtureRange.lowerBound == Defaults[key]["0"]?.lowerBound)
		Defaults[key]["1"] = nextFixtureRange
		#expect(fixtureRange.upperBound == Defaults[key]["0"]?.upperBound)
		#expect(fixtureRange.lowerBound == Defaults[key]["0"]?.lowerBound)
		#expect(nextFixtureRange.upperBound == Defaults[key]["1"]?.upperBound)
		#expect(nextFixtureRange.lowerBound == Defaults[key]["1"]?.lowerBound)

		// Test serializable Range type
		let dateKey = Defaults.Key<[String: Range<CustomDate>]>("independentRangeDateDictionaryKey", default: ["0": fixtureDateRange], suite: suite_)
		#expect(fixtureDateRange.upperBound == Defaults[dateKey]["0"]?.upperBound)
		#expect(fixtureDateRange.lowerBound == Defaults[dateKey]["0"]?.lowerBound)
		Defaults[dateKey]["1"] = nextFixtureDateRange
		#expect(fixtureDateRange.upperBound == Defaults[dateKey]["0"]?.upperBound)
		#expect(fixtureDateRange.lowerBound == Defaults[dateKey]["0"]?.lowerBound)
		#expect(nextFixtureDateRange.upperBound == Defaults[dateKey]["1"]?.upperBound)
		#expect(nextFixtureDateRange.lowerBound == Defaults[dateKey]["1"]?.lowerBound)

		// Test native support ClosedRange type
		let closedKey = Defaults.Key<[String: ClosedRange]>("independentClosedRangeDictionaryKey", default: ["0": fixtureClosedRange], suite: suite_)
		#expect(fixtureClosedRange.upperBound == Defaults[closedKey]["0"]?.upperBound)
		#expect(fixtureClosedRange.lowerBound == Defaults[closedKey]["0"]?.lowerBound)
		Defaults[closedKey]["1"] = nextFixtureClosedRange
		#expect(fixtureClosedRange.upperBound == Defaults[closedKey]["0"]?.upperBound)
		#expect(fixtureClosedRange.lowerBound == Defaults[closedKey]["0"]?.lowerBound)
		#expect(nextFixtureClosedRange.upperBound == Defaults[closedKey]["1"]?.upperBound)
		#expect(nextFixtureClosedRange.lowerBound == Defaults[closedKey]["1"]?.lowerBound)

		// Test serializable ClosedRange type
		let closedDateKey = Defaults.Key<[String: ClosedRange<CustomDate>]>("independentClosedRangeDateDictionaryKey", default: ["0": fixtureDateClosedRange], suite: suite_)
		#expect(fixtureDateClosedRange.upperBound == Defaults[closedDateKey]["0"]?.upperBound)
		#expect(fixtureDateClosedRange.lowerBound == Defaults[closedDateKey]["0"]?.lowerBound)
		Defaults[closedDateKey]["1"] = nextFixtureDateClosedRange
		#expect(fixtureDateClosedRange.upperBound == Defaults[closedDateKey]["0"]?.upperBound)
		#expect(fixtureDateClosedRange.lowerBound == Defaults[closedDateKey]["0"]?.lowerBound)
		#expect(nextFixtureDateClosedRange.upperBound == Defaults[closedDateKey]["1"]?.upperBound)
		#expect(nextFixtureDateClosedRange.lowerBound == Defaults[closedDateKey]["1"]?.lowerBound)
	}
}
