import XCTest
import Combine
import Defaults

@available(macOS 11.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
private extension Defaults.Keys {
    static let opacity = Key<Double>("opacity", default: 0.5)
}

@available(macOS 11.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
final class ViewModel: ObservableObject {
    @PublishedDefault(.opacity) var opacity
}

@available(macOS 11.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
final class DefaultsPublishedDefaultTests: XCTestCase {
    
    var cancellables: [AnyCancellable] = []
    
    override func setUp() {
        Defaults.removeAll()
    }

    override func tearDown() {
        cancellables = []
    }

    func testObjectWillChange() {
        let viewModel = ViewModel()
        let objectExpectation = expectation(description: "Expected ObservableObject's fire")

        viewModel.objectWillChange
            .sink {
                objectExpectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.opacity = 1
        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(viewModel.opacity, 1)
        XCTAssertEqual(Defaults[.opacity], 1)
    }
    
    func testProjectValue() {
        let viewModel = ViewModel()
        let valueExpectation = expectation(description: "Expected Opacity Value")
        var receivedValue: Double?
        
        viewModel.$opacity
            // skip the initial value
            .dropFirst()
            .sink { newValue in
                receivedValue = newValue
                valueExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Changing value via Defaults directly also fire the projecttedValue
        Defaults[.opacity] = 1
        waitForExpectations(timeout: 1)
        XCTAssertEqual(receivedValue, 1)
    }
    
    func testObservation() {
        let viewModel = ViewModel()
        // To enable Defaults observation, call observeDefaults.
        viewModel.observeDefaults()
        let objectExpectation = expectation(description: "Expected ObservableObject's fire")
        
        viewModel.objectWillChange
            .sink {
                objectExpectation.fulfill()
            }
            .store(in: &cancellables)

        // Change value via Defaults instead of ObservableObject itself
        Defaults[.opacity] = 1
        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(viewModel.opacity, 1)
    }
}
