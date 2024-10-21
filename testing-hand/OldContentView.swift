////
////  ContentView.swift
////  testing-hand
////
////  Created by kotars01 on 13/06/2023.
////
//
//import SwiftUI
//import RealityKit
//import ARKit
//import Vision
//
//struct OldContentView : View {
//    var sessionHandler = SessionHandler()
//    var body: some View {
//        ARViewContainer(sessionHandler: sessionHandler).edgesIgnoringSafeArea(.all)
//    }
//}
//
//struct ARViewContainer: UIViewRepresentable {
//    
//    @ObservedObject var sessionHandler: SessionHandler
//    
//    func makeUIView(context: Context) -> ARView {
//        
//        let arView = ARView(frame: .zero)
//        
//        let config = ARWorldTrackingConfiguration()
//        
//        arView.session.run(config)
//        
//        guard ARConfiguration.isSupported else { return arView }
//        
//        arView.automaticallyConfigureSession = true
//        
//        arView.session.delegate = sessionHandler
//        
//        sessionHandler.createCircleForThumb(view: arView)
//        sessionHandler.attachMesh = {
//            let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
//            let material = SimpleMaterial(color: .red, roughness: 0.15, isMetallic: true)
//            let model = ModelEntity(mesh: mesh, materials: [material])
//            
//            // Create horizontal plane anchor for the content
//            let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
//            anchor.children.append(model)
//            
//            // Add the horizontal plane anchor to the scene
//            arView.scene.anchors.append(anchor)
//        }
//        //
//        return arView
//        
//    }
//    
//    func updateUIView(_ uiView: ARView, context: Context) {}
//}
//
//class SessionHandler: NSObject, ObservableObject, ARSessionDelegate {
//    
//    var attachMesh: (() -> ())?
//    
//    private let manager = OperationManager()
//    
//    private var thumbTipLayer: CALayer!
//    private var indexTipLayer: CALayer!
//    
//    private var handPoseRequest = VNDetectHumanHandPoseRequest()
//    private var lastFrameTimestamp: TimeInterval?
//    
//    override var description: String { "Custom description" }
//    
//    override func isEqual(_ object: Any?) -> Bool {
//        // Custom implementation for isEqual method
//        // Return true if the objects are equal, false otherwise
//        return true
//    }
//    
//    func createCircleForThumb(view: UIView) {
//        // Create thumb tip layer
//        thumbTipLayer = createFingerSignLayer(view: view)
//        indexTipLayer = createFingerSignLayer(view: view)
//        
//        handPoseRequest.maximumHandCount = 2 // Set the maximum number of hands to detect
//    }
//    
//    private func createFingerSignLayer(view: UIView) -> CALayer {
//        // Create thumb tip layer
//        let fingerLayer = CALayer()
//        fingerLayer.bounds = CGRect(x: 0, y: 0, width: 10, height: 10)
//        fingerLayer.backgroundColor = UIColor.green.cgColor
//        fingerLayer.cornerRadius = 10
//        fingerLayer.isHidden = true
//        view.layer.addSublayer(fingerLayer)
//        
//        return fingerLayer
//    }
//    
//    func session(
//        _ session: ARSession,
//        didUpdate frame: ARFrame
//    ) {
//        // Create a pixel buffer from the current frame
//        let pixelBuffer = frame.capturedImage
//        
//        // Create a handler to perform the hand pose detection
//        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right ,options: [:])
//
//        Task {
//            do {
//                try await performRequest(handler: handler)
//            } catch {
//                print("Error performing hand pose detection: \(error)")
//            }
//        }
//    }
//
//    private func performRequest(handler: VNImageRequestHandler) async throws {
//        // Perform hand pose detection
//        try handler.perform([handPoseRequest])
//
//        // Access the detected hands
//        if let observation = handPoseRequest.results?.first as? VNHumanHandPoseObservation {
//            // Get the points representing the hand joints
//            let jointPoints = try observation.recognizedPoints(.all)
//
//            if let jointPoint = jointPoints[.thumbTip] {
//                obtainJointPointAndUpdatePosition(jointPoint, layer: thumbTipLayer)
//            } else {
//                thumbTipLayer.isHidden = true
//            }
//            if let jointPoint = jointPoints[.indexTip] {
//                obtainJointPointAndUpdatePosition(jointPoint, layer: indexTipLayer)
//            } else {
//                indexTipLayer.isHidden = true
//            }
//            await MainActor.run {
//                verifyIfHandIsPinching()
//            }
//        } else {
//            print("\(Date.now): No hands")
//            thumbTipLayer.isHidden = true
//            indexTipLayer.isHidden = true
//        }
//    }
//
//    private func shouldProcessImageHandRequest(from frame: ARFrame) -> Bool {
//        let timestamp = frame.timestamp
//        guard let lastFrameTimestamp = lastFrameTimestamp else {
//            lastFrameTimestamp = timestamp
//            return true
//        }
//        
//        return lastFrameTimestamp - timestamp > 1
//    }
//    
//    private func obtainJointPointAndUpdatePosition(_ jointPoint: VNRecognizedPoint, layer: CALayer) {
//        // Convert the thumb tip point to the screen coordinate system
//        let screenFingerTipPoint = self.convertPointFromVision(point: jointPoint.location, frameSize: UIScreen.main.bounds.size)
//        
//        // Update the position of the thumb tip layer
//        layer.position = screenFingerTipPoint
//        layer.isHidden = false
//    }
//    
//    // Helper method to convert a point from Vision coordinate system to screen coordinate system
//    private func convertPointFromVision(point: CGPoint, frameSize: CGSize) -> CGPoint {
//        let flippedPoint = CGPoint(x: point.x, y: 1 - point.y)
//        return CGPoint(x: flippedPoint.x * frameSize.width, y: flippedPoint.y * frameSize.height)
//    }
//    
//    private func verifyIfHandIsPinching() {
//        if CGPointDistance(from: thumbTipLayer.position, to: indexTipLayer.position) > 30 {
//            thumbTipLayer.backgroundColor = UIColor.green.cgColor
//            indexTipLayer.backgroundColor = UIColor.green.cgColor
//        } else {
//            thumbTipLayer.backgroundColor = UIColor.black.cgColor
//            indexTipLayer.backgroundColor = UIColor.black.cgColor
//            performAttachMech()
//        }
//    }
//    
//    private func performAttachMech() {
//        guard let attachMesh = attachMesh else { return }
//        
//        manager.performOperation(action: attachMesh)
//    }
//}
//
//func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat { (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y) }
//
//func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat { sqrt(CGPointDistanceSquared(from: from, to: to)) }
//
//import VideoToolbox
//
//extension UIImage {
//    public convenience init?(pixelBuffer: CVPixelBuffer) {
//        var cgImage: CGImage?
//        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
//        
//        guard let cgImage = cgImage else {
//            return nil
//        }
//        
//        self.init(cgImage: cgImage)
//    }
//}
