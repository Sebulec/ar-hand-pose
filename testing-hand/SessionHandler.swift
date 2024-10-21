import SwiftUI
import RealityKit
import ARKit
import Vision

class SessionHandler: NSObject, ObservableObject, ARSessionDelegate {
    var attachMesh: (() -> ())?

    private let manager = OperationManager()
    private var thumbTipLayer: CALayer!
    private var indexTipLayer: CALayer!
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    private var lastFrameTimestamp: TimeInterval?

    func createCircleForThumb(view: UIView) {
        thumbTipLayer = createFingerSignLayer(view: view)
        indexTipLayer = createFingerSignLayer(view: view)
        handPoseRequest.maximumHandCount = 2
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let pixelBuffer = frame.capturedImage
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

        DispatchQueue.global().sync { [weak self] in
            do {
                try self?.performRequest(handler: handler)
            } catch {
                print("Error performing hand pose detection: \(error)")
            }
        }
    }

    private func performRequest(handler: VNImageRequestHandler) throws {
        try handler.perform([handPoseRequest])

        if let observation = handPoseRequest.results?.first as? VNHumanHandPoseObservation {
            let jointPoints = try observation.recognizedPoints(.all)
            updateFingerTipPositions(jointPoints)
            DispatchQueue.main.async { [weak self] in
                self?.verifyIfHandIsPinching()
            }
        } else {
            print("\(Date.now): No hands")
            thumbTipLayer.isHidden = true
            indexTipLayer.isHidden = true
        }
    }

    private func updateFingerTipPositions(_ jointPoints: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint]) {
        if let jointPoint = jointPoints[.thumbTip] {
            obtainJointPointAndUpdatePosition(jointPoint, layer: thumbTipLayer)
        } else {
            thumbTipLayer.isHidden = true
        }
        if let jointPoint = jointPoints[.indexTip] {
            obtainJointPointAndUpdatePosition(jointPoint, layer: indexTipLayer)
        } else {
            indexTipLayer.isHidden = true
        }
    }

    private func obtainJointPointAndUpdatePosition(_ jointPoint: VNRecognizedPoint, layer: CALayer) {
        let screenFingerTipPoint = convertPointFromVision(point: jointPoint.location, frameSize: UIScreen.main.bounds.size)
        layer.position = screenFingerTipPoint
        layer.isHidden = false
    }

    private func verifyIfHandIsPinching() {
        if CGPointDistance(from: thumbTipLayer.position, to: indexTipLayer.position) > 30 {
            thumbTipLayer.backgroundColor = UIColor.green.cgColor
            indexTipLayer.backgroundColor = UIColor.green.cgColor
        } else {
            thumbTipLayer.backgroundColor = UIColor.black.cgColor
            indexTipLayer.backgroundColor = UIColor.black.cgColor
            performAttachMech()
        }
    }

    private func performAttachMech() {
        guard let attachMesh = attachMesh else { return }
        manager.performOperation(action: attachMesh)
    }

    private func createFingerSignLayer(view: UIView) -> CALayer {
        let fingerLayer = CALayer()
        fingerLayer.bounds = CGRect(x: 0, y: 0, width: 10, height: 10)
        fingerLayer.backgroundColor = UIColor.green.cgColor
        fingerLayer.cornerRadius = 10
        fingerLayer.isHidden = true
        view.layer.addSublayer(fingerLayer)
        return fingerLayer
    }

    // Add the attachMeshToScene method
    func attachMeshToScene(in arView: ARSCNView) {
        // Create a box geometry
        let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.005)

        // Create a material for the box
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.roughness.contents = 0.15
        material.metalness.contents = 1.0

        // Apply the material to the box geometry
        boxGeometry.materials = [material]

        // Create a node with the box geometry
        let boxNode = SCNNode(geometry: boxGeometry)

        // Create a horizontal plane anchor for the content
        let planeAnchor = ARAnchor(name: "horizontalPlane", transform: simd_float4x4(SCNMatrix4Identity))

        if let position = performHitTestForHorizontalPlane(in: arView) {
            boxNode.position = position
        }
        // Add the anchor to the session
        arView.session.add(anchor: planeAnchor)

        // Create a node for the anchor and add the box as its child
        let anchorNode = SCNNode()
        anchorNode.addChildNode(boxNode)

        // Add the anchor node to the scene
        arView.scene.rootNode.addChildNode(anchorNode)
    }
}

func performHitTestForHorizontalPlane(in arView: ARSCNView) -> SCNVector3? {
    // Get the center point of the screen
    let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)

    // Perform a hit test at the center of the screen
    let hitTestResults = arView.hitTest(screenCenter, types: .estimatedHorizontalPlane)

    // Check if we hit a horizontal plane
    if let result = hitTestResults.first {
        // Get the world transform of the hit test result (position in the real world)
        let hitPosition = SCNVector3(
            x: result.worldTransform.columns.3.x,
            y: result.worldTransform.columns.3.y,
            z: result.worldTransform.columns.3.z
        )
        return hitPosition
    }

    // Return nil if no plane was found
    return nil
}
