import SwiftUI

struct ContentView: View {
    var sessionHandler = SessionHandler()

    var body: some View {
        ARViewContainer(sessionHandler: sessionHandler)
            .edgesIgnoringSafeArea(.all)
    }
}
