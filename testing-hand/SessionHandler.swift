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
        //        return
        let pixelBuffer = frame.capturedImage
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

        //        Task {
        DispatchQueue.global().sync { [weak self] in
            do {
                try self?.performRequest(handler: handler)
            } catch {
                print("Error performing hand pose detection: \(error)")
            }
        }
        //        }
    }

    private func performRequest(handler: VNImageRequestHandler) throws {
        try handler.perform([handPoseRequest])

        if let observation = handPoseRequest.results?.first as? VNHumanHandPoseObservation {
            let jointPoints = try observation.recognizedPoints(.all)
            updateFingerTipPositions(jointPoints)
            //            await MainActor.run {
            DispatchQueue.main.async {
                self.verifyIfHandIsPinching()
            }
            //            }
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

        // Add the anchor to the session
        arView.session.add(anchor: planeAnchor)

        // Create a node for the anchor and add the box as its child
        let anchorNode = SCNNode()
        anchorNode.addChildNode(boxNode)

        // Add the anchor node to the scene
        arView.scene.rootNode.addChildNode(anchorNode)

        // Set up a delegate to handle anchor updates
        arView.delegate = self





        // Create a box geometry
        //        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.005)
        //
        //        // Create a material for the box
        //        let material = SCNMaterial()
        //        material.diffuse.contents = UIColor.red
        //        material.metalness.contents = 1.0
        //        material.roughness.contents = 0.15
        //        box.materials = [material]
        //
        //        // Create a node with the box geometry
        //        let boxNode = SCNNode(geometry: box)
        //
        //        // Create an ARAnchor for horizontal plane
        //        let anchor = ARAnchor(transform: simd_float4x4(1))
        //
        //        // Add the anchor to the AR session
        //        arView.session.add(anchor: anchor)
        //
        //        // When the anchor is added, the renderer delegate will be called to attach the node to the anchor
        //        arView.scene.rootNode.addChildNode(boxNode)




        //        let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
        //        let material = SimpleMaterial(color: .red, roughness: 0.15, isMetallic: true)
        //        let model = ModelEntity(mesh: mesh, materials: [material])
        //
        //        // Create horizontal plane anchor for the content
        //        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        //        anchor.children.append(model)
        //
        //        // Add the horizontal plane anchor to the scene
        //        arView.session.add(anchor: anchor)
        ////        arView.scene.anchors.append(anchor)
    }
}

extension SessionHandler: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            print("Plane detected")
            // Get the position of the plane in world coordinates
//            let position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)

            // Attach the mesh (box) to the detected plane
//            attachMeshToScene(in: arView, at: position)
        }

        return nil
    }
}
