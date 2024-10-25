import SwiftUI

struct ContentView: View {
    private let sessionHandler = SessionHandler()

    var body: some View {
        ARViewContainer(sessionHandler: sessionHandler)
            .edgesIgnoringSafeArea(.all)
    }
}
