/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A `Pose` is a collection of "landmarks" and connections between select landmarks.
 Each `Pose` can draw itself as a wireframe to a Core Graphics context.
*/

import UIKit
import Vision
import CoreML

/// Stores the landmarks and connections of a human body pose and draws them as a wireframe.
struct Pose {
    /// The names and locations of the significant points on a human body.
    private let landmarks: [Landmark]

    /// A list of lines between landmarks for drawing a wireframe.
    private var connections: [Connection]!

    /// The locations of the pose's landmarks as a multiarray.
    let multiArray: MLMultiArray?

    /// A rough approximation of the landmarks' area.
    let area: CGFloat

    /// Creates a `Pose` for each human body pose observation in the array.
    /// - Parameter observations: An array of human body pose observations.
    /// - Returns: A `Pose` array.
    static func fromObservations(_ observations: [VNHumanBodyPoseObservation]?) -> [Pose]? {
        // Convert each observation to a `Pose`.
        observations?.compactMap { Pose($0) }
    }

    /// Creates a wireframe from a human body pose observation.
    /// - Parameter observation: A human body pose observation.
    init?(_ observation: VNHumanBodyPoseObservation) {
        // Create a landmark for each joint in the observation.
        landmarks = observation.availableJointNames.compactMap { jointName in
            guard jointName != JointName.root else {
                return nil
            }
            guard let point = try? observation.recognizedPoint(jointName) else {
                return nil
            }
            return Landmark(point)
        }

        guard !landmarks.isEmpty else { return nil }

        // Compute area and multiarray.
        area = Pose.areaEstimateOfLandmarks(landmarks)
        multiArray = try? observation.keypointsMultiArray()

        // Build drawing connections.
        buildConnections()
    }

    /// Draws all the valid connections and landmarks of the wireframe.
    /// - Parameters:
    ///   - context: A context the method uses to draw the wireframe.
    ///   - transform: A transform that modifies the point locations.
    func drawWireframeToContext(_ context: CGContext,
                                applying transform: CGAffineTransform? = nil) {
        let scale = drawingScale

        // Draw the connection lines first.
        connections.forEach { line in
            line.drawToContext(context,
                                applying: transform,
                                at: scale)
        }

        // Draw the landmarks on top of the lines' endpoints.
        landmarks.forEach { landmark in
            landmark.drawToContext(context,
                                   applying: transform,
                                   at: scale)
        }
    }

    /// Adjusts the landmarks radius and connection thickness when the pose draws
    /// itself as a wireframe.
    private var drawingScale: CGFloat {
        let typicalLargePoseArea: CGFloat = 0.35
        let max: CGFloat = 1.0
        let min: CGFloat = 0.6
        let ratio = area / typicalLargePoseArea
        return ratio >= max ? max : (ratio * (max - min)) + min
    }
}

// MARK: - Helper methods

extension Pose {
    /// Creates an array of connections from the available landmarks.
    mutating func buildConnections() {
        // Only build the connections once.
        guard connections == nil else { return }
        connections = [Connection]()

        let joints = landmarks.map { $0.name }
        let locations = landmarks.map { $0.location }
        let jointLocations = Dictionary(uniqueKeysWithValues: zip(joints, locations))

        for jointPair in Pose.jointPairs {
            guard let one = jointLocations[jointPair.joint1],
                  let two = jointLocations[jointPair.joint2]
            else { continue }
            connections.append(Connection(one, two))
        }
    }

    /// Returns a rough estimate of the landmarks' collective area.
    /// - Parameter landmarks: A `Landmark` array.
    /// - Returns: A `CGFloat` ≥ 0.
    static func areaEstimateOfLandmarks(_ landmarks: [Landmark]) -> CGFloat {
        let xs = landmarks.map { $0.location.x }
        let ys = landmarks.map { $0.location.y }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max()
        else { return 0.0 }
        return (maxX - minX) * (maxY - minY)
    }
}
