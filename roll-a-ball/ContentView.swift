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

struct ContentView: View {
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
    
    func findModelEntity(in entity: Entity) -> ModelEntity? {
        if let modelEntity = entity as? ModelEntity {
            return modelEntity
        }
        
        for child in entity.children {
            if let foundModelEntity = findModelEntity(in: child) {
                return foundModelEntity
            }
        }
        
        return nil
    }
    
    func makeUIView(context: Context) -> ARGameView {
        
        // let arView = ARView(frame: .zero)
        
        let physics = PhysicsBodyComponent(
            massProperties: .default, material: .default, mode: .dynamic)
        
//        let motion = PhysicsMotionComponent(linearVelocity: [0.1 ,0, 0], angularVelocity: [3, 3, 3])

        guard var ballEntity = GameEntities.ball else {
                fatalError("Failed to load the Bowling Ball USDZ model.")
        }
        
        if let object0 = findModelEntity(in: ballEntity) {
            ballEntity = object0
        } else {
            print("Object_0 not found.")
        }
        

        ballEntity.components.set(physics)
//        ballEntity.components.set(motion)
//        ballEntity.components[PhysicsMotionComponent.self] = PhysicsMotionComponent()
        
        ballEntity.components[BallComponent.self] = BallComponent()
        

        ballEntity.generateCollisionShapes(recursive: true)
        ballEntity.transform.translation = SIMD3<Float>(0, 0, 0)
        ballEntity.transform.scale = SIMD3<Float>(0.1, 0.1, 0.1)
//        print("here")
//        print(ballEntity as? ModelEntity)
//        print(ballEntity as? HasPhysicsBody)
        GameEntities.ball = ballEntity

        
        // Download From: https://sketchfab.com/3d-models/bowling-pin-028ccb945012460aa9056ffda5b53e20#comments
        guard var pin0 = try? ModelEntity.load(named: "Bowling_Pin.usdz") else {
                fatalError("Failed to load the Pin USDZ model.")
        }
        
        if let object1 = findModelEntity(in: pin0) {
            pin0 = object1
        } else {
            print("Object_1 not found.")
        }
        
        pin0.components.set(physics)
        pin0.generateCollisionShapes(recursive: true)
//        pin0.orientation = simd_quatf(angle: .pi/2, axis: [0,0,0])
        
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
        print(pin0)
        
        GameEntities.pins.append(contentsOf: [pin1, pin2, pin3, pin4])
        
        // Create horizontal plane anchor for the content
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
//        anchor.components.set(physics)
//        anchor.generateCollisionShapes(recursive: true)
        

       // Add collision to the horizontal plane
        let planeMesh = MeshResource.generatePlane(width: 10, depth: 10)
        let planeCollider = ModelEntity(mesh: planeMesh)
        planeCollider.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
        planeCollider.generateCollisionShapes(recursive: true)
        planeCollider.components[ModelComponent.self] = nil // make the floor invisible
        anchor.addChild(planeCollider)
        

        anchor.children.append(contentsOf: [ballEntity, pin1, pin2, pin3, pin4])
        

        // Add the horizontal plane anchor to the scene
        arView.scene.anchors.append(anchor)

        return arView
        
    }
    
    func updateUIView(_ uiView: ARGameView, context: Context) {}
    
}

struct BallComponent: Component {
    var direction: ForceDirection?
    
    static let query = EntityQuery(where: .has(BallComponent.self))
}

class ARGameView: ARView {
    func startApplyingForce(direction: ForceDirection) -> Void {
//        print("apply force: \(direction.symbol)")
        var ballState = GameEntities.ball?.components[BallComponent.self] as? BallComponent
        ballState?.direction = direction
        GameEntities.ball?.components[BallComponent.self] = ballState
    }
    
    func stopApplyingForce() -> Void {
//        print("force stop")
        var ballState = GameEntities.ball?.components[BallComponent.self] as? BallComponent
        ballState?.direction = nil
        GameEntities.ball?.components[BallComponent.self] = ballState
    }
}

class BallPhysicsSystem: System {
    required init(scene: RealityKit.Scene) { }
    
    func update(context: SceneUpdateContext) {
        if let ball = GameEntities.ball {
            move(ball: ball)
        }
    }
    
    private func move(ball: Entity) {
        guard let ballComponent = ball.components[BallComponent.self] as? BallComponent,
              let physicsBody = ball as? HasPhysicsBody
        else {
            return
        }
        guard let direction = ballComponent.direction else {
            return
        }
//        print("got phy")

//                let impulseStrength: Float = 0.0005 // Adjust this value based on desired impulse strength
//                let impulse = direction.vector * impulseStrength

//                physicsBody.addForce(impulse, relativeTo: nil)
//                ball.components[PhysicsMotionComponent.self] = physicsBody
        
        let torqueStrength: Float = 0.05  // Adjust this value based on desired rotation strength
        let torque = SIMD3<Float>(direction.vector.z, 0, -direction.vector.x) * torqueStrength
            physicsBody.addTorque(torque, relativeTo: nil)
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


#Preview {
    ContentView()
}
