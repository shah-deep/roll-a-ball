//
//  ContentView.swift
//  roll-a-ball
//
//  Created by D on 11/30/23.
//

import SwiftUI
import RealityKit

enum ForceDirection {
    case up, down, left, right
    
    var symbol: String {
        switch self {
        case .up:
            return "arrow.up.circle.fill"
        case .down:
            return "arrow.down.circle.fill"
        case .left:
            return "arrow.left.circle.fill"
        case .right:
            return "arrow.right.circle.fill"
        }
    }
    
    var vector: SIMD3<Float> {
        switch self {
            case .up:
                return SIMD3<Float>(0, 0, -1)
            case .down:
                return SIMD3<Float>(0, 0, 1)
            case .left:
                return SIMD3<Float>(-1, 0, 0)
            case .right:
                return SIMD3<Float>(1, 0, 0)
        }
    }
}

struct GameEntities {
    // Download From: https://sketchfab.com/3d-models/bowling-ball-fc8f1162901a4e38b506fe1ab229f296
    static var ball = try? ModelEntity.load(named: "Bowling_Ball.usdz")
    static var pins: [Entity] = []
}

struct ContentView : View {
    private let arView = ARGameView()
    
    var body: some View {
        ZStack {
            ARViewContainer(arView: arView)
                .edgesIgnoringSafeArea(.all)
            
            JoystickView(
                startApplyingForce: arView.startApplyingForce(direction:),
                stopApplyingForce: arView.stopApplyingForce
            )
        }
    }
}


struct ARViewContainer: UIViewRepresentable {
    
    let arView: ARGameView
    
    func makeUIView(context: Context) -> ARGameView {
        
        // let arView = ARView(frame: .zero)
        
        let physics = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .dynamic)
        let motion = PhysicsMotionComponent(linearVelocity: [0.1 ,0, 0], angularVelocity: [3, 3, 3])
        
        guard let ballEntity = GameEntities.ball else {
                fatalError("Failed to load the Bowling Ball USDZ model.")
        }
        
       
        ballEntity.components.set(physics)
        ballEntity.components.set(motion)
//        ballEntity.components[PhysicsMotionComponent.self] = PhysicsMotionComponent()
        
        ballEntity.components[BallComponent.self] = BallComponent()
        

        ballEntity.generateCollisionShapes(recursive: true)
        
        print(ballEntity)
        
        


        
        // Download From: https://sketchfab.com/3d-models/bowling-pin-028ccb945012460aa9056ffda5b53e20#comments
        guard let pin0 = try? ModelEntity.load(named: "Bowling_Pin.usdz") else {
                fatalError("Failed to load the Pin USDZ model.")
        }
        
        pin0.components.set(physics)
        pin0.generateCollisionShapes(recursive: true)
        
        // Create three additional copies of the original entity
        let pin1 = pin0.clone(recursive: true)
        let pin2 = pin0.clone(recursive: true)
        let pin3 = pin0.clone(recursive: true)
        let pin4 = pin0.clone(recursive: true)

        // Set positions for the additional pins (adjust positions as needed)
        pin1.transform.translation = SIMD3<Float>(0.0, 0.0, 0.4)
        pin2.transform.translation = SIMD3<Float>(0.0, 0.0, -0.4)
        pin3.transform.translation = SIMD3<Float>(0.4, 0.0, 0.0)
        pin4.transform.translation = SIMD3<Float>(-0.4, 0.0, 0.0)
        
        GameEntities.pins.append(contentsOf: [pin1, pin2, pin3, pin4])
        
        // Create horizontal plane anchor for the content
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        anchor.children.append(contentsOf: [ballEntity, pin1, pin2, pin3, pin4])

        // Add the horizontal plane anchor to the scene
        arView.scene.anchors.append(anchor)

        return arView
        
    }
    
    func updateUIView(_ uiView: ARGameView, context: Context) {}
    
}

struct BallComponent: Component {
    static let query = EntityQuery(where: .has(BallComponent.self))
    
    var direction: ForceDirection?
}

class ARGameView: ARView {
    func startApplyingForce(direction: ForceDirection) -> Void {
//        print("apply force: \(direction.symbol)")
        if let ball = scene.performQuery(BallComponent.query).first {
            print(ball as? ModelEntity)
            var ballState = ball.components[BallComponent.self] as? BallComponent
            ballState?.direction = direction
            ball.components[BallComponent.self] = ballState
        }
        
    }
    
    func stopApplyingForce() -> Void {
//        print("force stop")
        if let ball = scene.performQuery(BallComponent.query).first {
            var ballState = ball.components[BallComponent.self] as? BallComponent
            ballState?.direction = nil
            ball.components[BallComponent.self] = ballState
        }
    }
}

class BallPhysicsSystem: System {
    required init(scene: RealityKit.Scene) { }
    
    func update(context: SceneUpdateContext) {
        if let ball = context.scene.performQuery(BallComponent.query).first {
            move(ball: ball)
        }
    }
    
    private func move(ball: Entity) {
        guard let ballComponent = ball.components[BallComponent.self] as? BallComponent,
                      let direction = ballComponent.direction,
              let physicsBody = ball as? HasPhysicsBody
        else {
//            print(ball.isActive)
            return
        }
        print("got phy")

                let impulseStrength: Float = 0.5 // Adjust this value based on desired impulse strength
                let impulse = direction.vector * impulseStrength

                physicsBody.applyLinearImpulse(impulse, relativeTo: nil)
//                ball.components[PhysicsMotionComp onent.self] = physicsBody
    }
}

struct JoystickView: View {
    let startApplyingForce: (ForceDirection) -> Void
    let stopApplyingForce: () -> Void
    @State private var position = CGPoint.zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle() // Outer circle representing the joystick base
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                Circle() // Inner circle representing the joystick knob
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .offset(x: position.x, y: position.y)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let vector = CGVector(dx: value.translation.width, dy: value.translation.height)
                                let direction = vectorToDirection(vector)
                                startApplyingForce(direction)

                                // Update position with limits
                                position = CGPoint(
                                    x: min(max(value.translation.width, -30), 30),
                                    y: min(max(value.translation.height, -30), 30)
                                )
                            }
                            .onEnded { _ in
                                stopApplyingForce()
                                position = .zero
                            }
                    )
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height - 50)
        }
    }

    private func vectorToDirection(_ vector: CGVector) -> ForceDirection {
        if abs(vector.dx) > abs(vector.dy) {
            return vector.dx > 0 ? .right : .left
        } else {
            return vector.dy > 0 ? .down : .up
        }
    }
}


extension Sequence {
    var first: Element? {
        var iterator = self.makeIterator()
        return iterator.next()
    }
}


#Preview {
    ContentView()
}
