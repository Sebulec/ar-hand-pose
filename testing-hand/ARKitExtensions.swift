import UIKit

extension CGPoint {
    func distance(to: CGPoint) -> CGFloat {
        return sqrt(pow(x - to.x, 2) + pow(y - to.y, 2))
    }
}

// Helper method to convert a point from Vision coordinate system to screen coordinate system
func convertPointFromVision(point: CGPoint, frameSize: CGSize) -> CGPoint {
    let flippedPoint = CGPoint(x: point.x, y: 1 - point.y)
    return CGPoint(x: flippedPoint.x * frameSize.width, y: flippedPoint.y * frameSize.height)
}

func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat { sqrt(CGPointDistanceSquared(from: from, to: to)) }

func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat { (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y) }
