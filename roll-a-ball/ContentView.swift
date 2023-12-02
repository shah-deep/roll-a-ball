//
//  ContentView.swift
//  roll-a-ball
//
//  Created by D on 11/30/23.
//

import SwiftUI
import RealityKit

enum ForceDirection {
    case up, right, down, left
    
    var symbol: String {
        switch self {
        case .up:
            return "arrow.up.circle.fill"
        case .right:
            return "arrow.right.circle.fill"
        case .down:
            return "arrow.down.circle.fill"
        case .left:
            return "arrow.left.circle.fill"
        }
    }
}

struct ContentView : View {
    private let arView = ARGameView()
    
    var body: some View {
        ZStack {
            ARViewContainer(arView: arView)
                .edgesIgnoringSafeArea(.all)
            
            ControlsView(
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
        // Download From: https://sketchfab.com/3d-models/bowling-ball-fc8f1162901a4e38b506fe1ab229f296
        guard let ballEntity = try? ModelEntity.load(named: "Bowling_Ball.usdz") else {
                fatalError("Failed to load the Bowling Ball USDZ model.")
        }
        ballEntity.generateCollisionShapes(recursive: true)
        ballEntity.components.set(physics)
        
        // Download From: https://sketchfab.com/3d-models/bowling-pin-028ccb945012460aa9056ffda5b53e20#comments
        guard let pin1 = try? ModelEntity.load(named: "Bowling_Pin.usdz") else {
                fatalError("Failed to load the Pin 1 USDZ model.")
        }
        
        pin1.generateCollisionShapes(recursive: true)
        pin1.components.set(physics)
        
        // Create three additional copies of the original entity
        let pin2 = pin1.clone(recursive: true)
        let pin3 = pin1.clone(recursive: true)
        let pin4 = pin1.clone(recursive: true)

        // Set positions for the additional pins (adjust positions as needed)
        pin1.transform.translation = SIMD3<Float>(0.0, 0.0, 0.4)
        pin2.transform.translation = SIMD3<Float>(0.0, 0.0, -0.4)
        pin3.transform.translation = SIMD3<Float>(0.4, 0.0, 0.0)
        pin4.transform.translation = SIMD3<Float>(-0.4, 0.0, 0.0)
        
        // Create horizontal plane anchor for the content
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        anchor.children.append(contentsOf: [ballEntity, pin1, pin2, pin3, pin4])

        // Add the horizontal plane anchor to the scene
        arView.scene.anchors.append(anchor)

        return arView
        
    }
    
    func updateUIView(_ uiView: ARGameView, context: Context) {}
    
}

class ARGameView: ARView {
    func startApplyingForce(direction: ForceDirection) -> Void {
        print("apply force: \(direction.symbol)")
    }
    
    func stopApplyingForce() -> Void {
        print("force stop")
    }
}

struct ControlsView: View {
    let startApplyingForce: (ForceDirection) -> Void
    let stopApplyingForce: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                arrowButton(direction: .up)
                Spacer()
            }
            
            HStack {
                arrowButton(direction: .left)
                Spacer()
                arrowButton(direction: .right)
            }
            
            HStack {
                Spacer()
                arrowButton(direction: .down)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    func arrowButton(direction: ForceDirection) -> some View {
        Image(systemName: direction.symbol)
            .resizable()
            .frame(width: 75, height: 75)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        startApplyingForce(direction)
                    })
                    .onEnded({ _ in
                        stopApplyingForce()
                    })
            )
    }
}

#Preview {
    ContentView()
}
