//
//  ContentView.swift
//  roll-a-ball
//
//  Created by D on 11/30/23.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        
        let physics = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .dynamic)
        
        guard let ballEntity = try? ModelEntity.load(named: "Bowling_Ball.usdz") else {
                fatalError("Failed to load the Bowling Ball USDZ model.")
        }
        ballEntity.generateCollisionShapes(recursive: true)
        ballEntity.components.set(physics)
        
        
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
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

#Preview {
    ContentView()
}
