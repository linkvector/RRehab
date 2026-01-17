import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
}
