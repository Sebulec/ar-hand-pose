import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var sessionHandler: SessionHandler

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        arView.session.run(config)

        guard ARConfiguration.isSupported else { return arView }

        arView.session.delegate = sessionHandler

        sessionHandler.createCircleForThumb(view: arView)
        sessionHandler.attachMesh = {
            sessionHandler.attachMeshToScene(in: arView)
        }

        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
