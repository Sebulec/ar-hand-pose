import SwiftUI
import RealityKit
import ARKit
import Vision

final class SessionHandler: NSObject, ObservableObject, ARSessionDelegate {
    weak var arView: ARSCNView?

    private let manager = OperationManager()
    private var thumbTipView: UIView!
    private var indexTipView: UIView!
    private var handPoseRequest = VNDetectHumanHandPoseRequest()

    func createCircleForThumb(view: UIView) {
        thumbTipView = createFingerView(in: view)
        indexTipView = createFingerView(in: view)
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
            DispatchQueue.main.async { [weak self] in
                self?.updateFingerTipPositions(jointPoints)
                self?.verifyIfHandIsPinching()
            }
        } else {
            print("\(Date.now): No hands")
            thumbTipView.isHidden = true
            indexTipView.isHidden = true
        }
    }

    private func updateFingerTipPositions(_ jointPoints: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint]) {
        if let jointPoint = jointPoints[.thumbTip] {
            obtainJointPointAndUpdatePosition(jointPoint, layer: thumbTipView)
        } else {
            thumbTipView.isHidden = true
        }
        if let jointPoint = jointPoints[.indexTip] {
            obtainJointPointAndUpdatePosition(jointPoint, layer: indexTipView)
        } else {
            indexTipView.isHidden = true
        }
    }

    private func obtainJointPointAndUpdatePosition(_ jointPoint: VNRecognizedPoint, layer: UIView) {
        let screenFingerTipPoint = convertPointFromVision(point: jointPoint.location, frameSize: UIScreen.main.bounds.size)
        layer.frame.origin = screenFingerTipPoint
        layer.isHidden = false
    }
    
    private func createFingerView(in view: UIView) -> UIView {
        let finger = UIView(frame: .init(x: 0, y: 0, width: 10, height: 10))

        finger.backgroundColor = .green
        finger.layer.cornerRadius = 10
        finger.isHidden = true
        view.addSubview(finger)

        return finger
    }

    private func verifyIfHandIsPinching() {
        if thumbTipView.frame.origin.distance(to: indexTipView.frame.origin) > 30 {
            thumbTipView.backgroundColor = UIColor.green
            indexTipView.backgroundColor = UIColor.green
        } else {
            thumbTipView.backgroundColor = UIColor.black
            indexTipView.backgroundColor = UIColor.black
            performAttachMech()
        }
    }

    private func performAttachMech() {
        guard let arView else { return }

        manager.performOperation(action: { [weak self] in
            self?.attachMeshToScene(in: arView)
        })
    }

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

        if let position = performRaycastForHorizontalPlane(in: arView) {
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

    private func performRaycastForHorizontalPlane(in arView: ARSCNView) -> SCNVector3? {
        // Get the center point of the screen
        let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)

        // Create a ray from the touch location
        guard let raycastQuery = arView.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: .any) else {
            return nil
        }

        // Perform the raycast
        let results = arView.session.raycast(raycastQuery)

        if let result = results.first {
            let translation = result.worldTransform.columns.3
            let position = SCNVector3(translation.x, translation.y, translation.z)

            return position
        }

        return nil
    }
}
