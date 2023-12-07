//
//  ContentView.swift
//  roll-a-ball
//
//  Created by D on 11/30/23.
//

import SwiftUI
import RealityKit
import Combine


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
    
    @State var showGameOver: Bool = false
    
    var body: some View {
        ZStack {
            ARViewContainer(arView: arView)
                .edgesIgnoringSafeArea(.all)
            
            JoystickView(
                startApplyingForce: arView.startApplyingForce(direction:),
                stopApplyingForce: arView.stopApplyingForce
            )
        }.alert(isPresented: $showGameOver) {
            Alert(
                title: Text("You Win!"),
                dismissButton: .default(Text("Ok")) {
                    showGameOver = false
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: PinSystem.gameOverNotification)) { _ in
            showGameOver = true
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
    
    func findModelEntity(byName name: String, in entity: Entity) -> Entity? {
        if entity.name == name {
            return entity
        }

        for child in entity.children {
            if let foundEntity = findModelEntity(byName: name, in: child) {
                return foundEntity
            }
        }

        return nil
    }

    
    func makeUIView(context: Context) -> ARGameView {
        
        // let arView = ARView(frame: .zero)
        

        guard var ballEntity = GameEntities.ball else {
                fatalError("Failed to load the Bowling Ball USDZ model.")
        }
        
        if let object0 = findModelEntity(in: ballEntity) {
            ballEntity = object0
        } else {
            print("Object_0 not found.")
        }
        
        let physics = PhysicsBodyComponent(massProperties: .init(mass: 10.0), material: .generate(friction: 0.4, restitution: 0) , mode: .dynamic)
        
        
        ballEntity.components.set(physics)
        
        // let motion = PhysicsMotionComponent(linearVelocity: [0.1 ,0, 0], angularVelocity: [3, 3, 3])
        // ballEntity.components.set(motion)
        // ballEntity.components[PhysicsMotionComponent.self] = PhysicsMotionComponent()
        // ballEntity.components[PhysicsBodyComponent.self]?.massProperties =
        
        ballEntity.components[BallComponent.self] = BallComponent()
        

        ballEntity.generateCollisionShapes(recursive: true)
        ballEntity.transform.translation = SIMD3<Float>(0, 0, 0)
        ballEntity.transform.scale = SIMD3<Float>(0.1, 0.1, 0.1)
        
        // ballEntity.components[ModelComponent.self]?.material?.roughness = 0.5

        GameEntities.ball = ballEntity
        
        
        // Download From: https://sketchfab.com/3d-models/bowling-pin-028ccb945012460aa9056ffda5b53e20#comments
        guard var pin0 = try? ModelEntity.load(named: "Bowling_Pin.usdz") else {
                fatalError("Failed to load the Pin USDZ model.")
        }
        
        let pin_main = pin0

        if let object1 = findModelEntity(in: pin0) {
            pin0 = object1
        } else {
            print("Object_1 not found.")
        }
        
        if let object2 = findModelEntity(byName: "Object_1", in: pin_main) {
            pin0.addChild(object2)
        } else {
            print("Can't get child")
        }

        let physics2 = PhysicsBodyComponent(massProperties: .init(mass: 0.001), material: .generate(friction: 0.5, restitution: 0), mode: .kinematic)
        
        pin0.components.set(physics2)
        pin0.generateCollisionShapes(recursive: true)
        pin0.components[PinRotatedComponent.self] = PinRotatedComponent()
        pin0.orientation = simd_quatf(angle: (.pi * -0.25), axis: [1,0,0])
        // pin0.orientation = simd_quatf(angle: (.pi * -0.50), axis: [0,0,1])
        
        // Create three additional copies of the original entity
        let pin1 = pin0.clone(recursive: true)
        pin1.components[PinRotatedComponent.self]?.num = 1

        let pin2 = pin0.clone(recursive: true)
        pin2.components[PinRotatedComponent.self]?.num = 2
        
        let pin3 = pin0.clone(recursive: true)
        pin3.components[PinRotatedComponent.self]?.num = 3
        
        let pin4 = pin0.clone(recursive: true)
        pin4.components[PinRotatedComponent.self]?.num = 4
        

        // Set positions for the additional pins (adjust positions as needed)
        pin1.transform.translation = SIMD3<Float>(0.0, 0.0, 0.4)
        pin2.transform.translation = SIMD3<Float>(0.0, 0.0, -0.4)
        pin3.transform.translation = SIMD3<Float>(0.4, 0.0, 0.0)
        pin4.transform.translation = SIMD3<Float>(-0.4, 0.0, 0.0)
        
        // print(ballEntity, pin1, pin1.isActive)
        
        GameEntities.pins.append(contentsOf: [pin1, pin2, pin3, pin4])
        
        // print("Components", pin0.components[SynchronizationComponent.self], pin0.components[Transform.self])
        
        // Create horizontal plane anchor for the content
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
         anchor.components.set(physics)
         anchor.generateCollisionShapes(recursive: true)
        

       // Add collision to the horizontal plane
        let planeMesh = MeshResource.generatePlane(width: 10, depth: 10)
        let planeCollider = ModelEntity(mesh: planeMesh)
        planeCollider.physicsBody = PhysicsBodyComponent(massProperties: .init(mass: 0.01), material: .generate(friction: 0.8, restitution: 0), mode: .static)
        planeCollider.generateCollisionShapes(recursive: true)
        planeCollider.physicsBody?.massProperties = .init(mass: 0.01)
        // planeCollider.components[PhysicsBodyMode]?.resti
        planeCollider.components[ModelComponent.self] = nil // make the floor invisible
        anchor.addChild(planeCollider)
        

        anchor.children.append(contentsOf: [ballEntity, pin1, pin2, pin3, pin4])
    
        // Add the horizontal plane anchor to the scene
        arView.scene.anchors.append(anchor)
   
        arView.setupCollisionDetection()

        return arView
        
    }
    
    func updateUIView(_ uiView: ARGameView, context: Context) {}
    
}

struct BallComponent: Component {
    var direction: ForceDirection?
    
//    static let query = EntityQuery(where: .has(BallComponent.self))
}

struct PinRotatedComponent: Component {
    var isRotated = false
    var num = 0
}

class PinSystem: System {
    
    static let gameOverNotification = Notification.Name("Game Over")
    static var gameOver = false
    
    required init(scene: RealityKit.Scene) { }
    
    func update(context: SceneUpdateContext) {
        if PinSystem.gameOver {
            return
        }
        
        // Check if all pins are rotated
        let allPinsRotated = GameEntities.pins.allSatisfy { pin in
            return pin.components[PinRotatedComponent.self]?.isRotated ?? false
        }
        
        // If all pins are rotated, mark the game as "game over" and post the notification
        if allPinsRotated {
            PinSystem.gameOver = true
            print("over GAME")
            NotificationCenter.default.post(name: PinSystem.gameOverNotification, object: nil)
        }
    }
}

class ARGameView: ARView {
    private var subscriptions = Set<AnyCancellable>()
    
    func startApplyingForce(direction: ForceDirection) -> Void {
        // print("apply force: \(direction.symbol)")
        var ballState = GameEntities.ball?.components[BallComponent.self] as? BallComponent
        ballState?.direction = direction
        GameEntities.ball?.components[BallComponent.self] = ballState
    }
    
    func stopApplyingForce() -> Void {
        // print("force stop")
        var ballState = GameEntities.ball?.components[BallComponent.self] as? BallComponent
        ballState?.direction = nil
        GameEntities.ball?.components[BallComponent.self] = ballState
    }
    
    func setupCollisionDetection() {
        scene.subscribe(to: CollisionEvents.Began.self) { event in
            if let ball = GameEntities.ball, let pin = GameEntities.pins.first(where: { $0 == event.entityA || $0 == event.entityB }) {
                        // Check if both the ball and pin are involved in the collision
                        if (event.entityA == ball && event.entityB == pin) || (event.entityA == pin && event.entityB == ball) {
                            self.rotatePinOnCollision(pin: pin)
                        }
                    }
        }.store(in: &subscriptions)
    }

    // Add this method in the ARGameView class
    func rotatePinOnCollision(pin: Entity) {
        if var pinRotatedComponent = pin.components[PinRotatedComponent.self] as? PinRotatedComponent, !pinRotatedComponent.isRotated, let physicsBody = pin as? HasPhysicsBody {
            
            var tmpDirection = ForceDirection.right
            
            if let direction = (GameEntities.ball?.components[BallComponent.self] as? BallComponent)?.direction {
                tmpDirection = direction
                // print("HERE DIRECTION ", tmpDirection.vector)
            }
            let v: Float = tmpDirection.vector.x>=0 ? (tmpDirection.vector.z>0 ? 1 : -1) : 1
            
            var transform = pin.transform
            
            transform.rotation = simd_quatf(angle: (.pi * 0.5) * v, axis: [0, 0, 1]) // Rotate 90 degrees around the x-axis
                pin.move(to: transform, relativeTo: pin.parent, duration: 0.5, timingFunction: .easeInOut)
                // pin.orientation = simd_quatf(angle: (.pi * -0.50), axis: [0,0,1])
            
                pinRotatedComponent.isRotated = true
                pin.components[PinRotatedComponent.self] = pinRotatedComponent
             
        }
    }
}

class BallPhysicsSystem: System {
    static var pinNeedsUpdate = false
    
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
        
        /* print("got phy")

                let impulseStrength: Float = 0.002 // Adjust this value based on desired impulse strength
                let impulse = direction.vector * impulseStrength

                physicsBody.applyLinearImpulse(impulse, relativeTo: nil)
                ball.components[PhysicsMotionComponent.self] = physicsBody */
        
        let torqueStrength: Float = 0.02  // Adjust this value based on desired rotation strength
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


//extension Sequence {
//    var first: Element? {
//        var iterator = self.makeIterator()
//        return iterator.next()
//    }
//}



#Preview {
    ContentView()
}
