//
//  ViewController.swift
//  Cocoaheads
//
//  Created by Ethan Jackwitz on 6/6/17.
//  Copyright © 2017 Ethan Jackwitz. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!

    var pointsInCloud: [SCNNode] = []

    var ambientLightNode: SCNNode!
    var globeNode: SCNNode!

    var pointGeom: SCNGeometry = {
        let geo = SCNSphere(radius: 0.01)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.locksAmbientWithDiffuse = true
        geo.firstMaterial = material
        return geo
    }()

    override func viewDidLoad() {
        super.viewDidLoad()


        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()

        // Set the scene to the view
        sceneView.scene = scene

        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = SCNLight.LightType.omni
        lightNode.position = SCNVector3(x: 0, y: 5, z: 5)
        scene.rootNode.addChildNode(lightNode)


        let theAmbientLight = SCNLight()
        theAmbientLight.type = SCNLight.LightType.ambient
        theAmbientLight.color = UIColor(white: 0.5, alpha: 1.0)
        self.ambientLightNode = SCNNode()
        self.ambientLightNode.light = theAmbientLight

        self.globeNode = SCNNode()
        let theGlobeGeometry = SCNSphere(radius: 0.5)
        theGlobeGeometry.firstMaterial?.diffuse.contents = UIImage(named:"earth_diffuse.jpg")
        theGlobeGeometry.firstMaterial?.ambient.contents = UIImage(named:"earth_ambient2.jpeg")
        //        theGlobeGeometry.firstMaterial?.ambient.contents = UIImage(named:"earth_ambient.jpg")
        theGlobeGeometry.firstMaterial?.specular.contents = UIImage(named:"earth_specular.jpg")
        theGlobeGeometry.firstMaterial?.emission.contents = nil
        theGlobeGeometry.firstMaterial?.transparent.contents = nil
        theGlobeGeometry.firstMaterial?.reflective.contents = nil
        theGlobeGeometry.firstMaterial?.multiply.contents = nil
        theGlobeGeometry.firstMaterial?.normal.contents = UIImage(named:"earth_normal.jpg")

        let theGlobeModelNode = SCNNode(geometry: theGlobeGeometry)
        self.globeNode.addChildNode(theGlobeModelNode)

        let theCloudGeometry = SCNSphere(radius:0.505)
        theCloudGeometry.firstMaterial?.diffuse.contents = nil
        theCloudGeometry.firstMaterial?.ambient.contents = nil
        theCloudGeometry.firstMaterial?.specular.contents = nil
        theCloudGeometry.firstMaterial?.emission.contents = nil
        theCloudGeometry.firstMaterial?.transparent.contents = UIImage(named:"earth_clouds.png")
        theCloudGeometry.firstMaterial?.reflective.contents = nil
        theCloudGeometry.firstMaterial?.multiply.contents = nil
        theCloudGeometry.firstMaterial?.normal.contents = nil

        let theCloudModelNode = SCNNode(geometry: theCloudGeometry)
        self.globeNode.addChildNode(theCloudModelNode)

        // animate the 3d object
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "rotation")
        animation.toValue = NSValue(scnVector4: SCNVector4(x: 1, y: 1, z: 0, w: Float.pi*2))
        animation.duration = 250
        animation.repeatCount = MAXFLOAT //repeat forever
        self.globeNode.addAnimation(animation, forKey: nil)


        // animate the 3d object
        let cloudAnimation: CABasicAnimation = CABasicAnimation(keyPath: "rotation")
        cloudAnimation.toValue = NSValue(scnVector4: SCNVector4(x: -1, y: 2, z: 0, w: Float.pi*2))
        cloudAnimation.duration = 525
        cloudAnimation.repeatCount = .infinity //repeat forever
        theCloudModelNode.addAnimation(cloudAnimation, forKey: nil)

        scene.rootNode.addChildNode(self.ambientLightNode)
        scene.rootNode.addChildNode(self.globeNode)

        self.globeNode.position = SCNVector3(x: 0, y: -0.5, z: -2.5)

        let gr = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        sceneView.addGestureRecognizer(gr)

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [unowned self] _ in
            self.redrawPointCloud()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.

        pointsInCloud.forEach({ $0.removeFromParentNode() })
        pointsInCloud.removeAll()
    }

    // MARK: - Hit test

    @objc func handleTap(sender: UITapGestureRecognizer!) {

    }

    func redrawPointCloud() {

        guard let frame = sceneView.session.currentFrame else {
            return
        }

        guard let pointCloud = frame.rawFeaturePoints else {
            return
        }

        pointsInCloud.forEach({ $0.removeFromParentNode() })
        pointsInCloud.removeAll(keepingCapacity: true)

        for i in 0..<pointCloud.count {

            let node = SCNNode(geometry: pointGeom)
            let v = pointCloud.points[i]

            node.position = SCNVector3(x: v.x, y: v.y, z: v.z)

            sceneView.scene.rootNode.addChildNode(node)

            pointsInCloud.append(node)
        }
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // This visualization covers only detected planes.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        // Create a SceneKit plane to visualize the node using its position and extent.
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)

        // SCNPlanes are vertically oriented in their local coordinate space.
        // Rotate it to match the horizontal orientation of the ARPlaneAnchor.
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)

        // ARKit owns the node corresponding to the anchor, so make the plane a child node.
        node.addChildNode(planeNode)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
