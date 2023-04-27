//
//  ViewController.swift
//  testARkit
//
//  Created by Антон Шарин on 25.04.2023.
//

import UIKit
import SceneKit
import ARKit
import AudioToolbox

enum BodyType : Int {
    case cube = 1
    case coin = 2
}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate{
    
    private let counterCoinsView : UIView = {
        let view = UIView()
        
        return view
    }()
    
    private let labelCounter : UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.text = "0"
        return label
    }()
    
    private var images : Set<ARReferenceImage> = [] {didSet{
        self.configAr()
    }}
    
    private var countCollectedCoins : Int = 0
    
    private var countCoinsOnScreen : Int = 0
    
    private var planeResult : ARRaycastResult?
    
    private var timer : Timer?
    
    private var timerForCoins : Timer?
    
    private var speedScale : CGFloat = 1
    
    private var counterBox : Int = 0
    
    private var coinCounter : Int = 0
    
    private var cubesArray : [SCNNode] = []
    
    private var coinsArray : [SCNNode] = []
    
    private let buttons = ControlButton()
    
    private let viewModel = ViewModel()
    
    private var detectedPlanes: [String : SCNNode] = [:]
    
    private let pathForSound = Bundle.main.path(forResource: "coinSound", ofType: "wav")
    
    private var soundID : SystemSoundID = 0

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createCounterView()
        viewModel.delegate = self
        viewModel.loadImage()
        sceneView.addSubview(buttons)
        buttons.setup()
        buttons.delegate = self
        buttons.isHidden = true

        sceneView.delegate = self
        sceneView.showsStatistics = true
        self.sceneView.scene.physicsWorld.contactDelegate = self
        
        
        sceneView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressCube(touch:))))
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(shortPressCube(touch:))))
        
        
        
    }
    
    private func configAr() {
        let configurationPlane = ARWorldTrackingConfiguration()
        configurationPlane.planeDetection = .horizontal
        
        if !images.isEmpty {
            configurationPlane.detectionImages = images
        }

        // Run the view's session
        configurationPlane.maximumNumberOfTrackedImages = 1
        
        sceneView.session.run(configurationPlane,options: [.resetTracking,.removeExistingAnchors])
        sceneView.debugOptions = []
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
           
        configAr()
            
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        buttons.translatesAutoresizingMaskIntoConstraints = false
        counterCoinsView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            buttons.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor,constant: -50),
            buttons.leadingAnchor.constraint(equalTo: sceneView.leadingAnchor,constant: 15),
            buttons.widthAnchor.constraint(equalToConstant: 210),
            buttons.heightAnchor.constraint(equalToConstant: 210),
            
            counterCoinsView.widthAnchor.constraint(equalToConstant: 50),
            counterCoinsView.heightAnchor.constraint(equalToConstant: 30),
            counterCoinsView.trailingAnchor.constraint(equalTo: sceneView.trailingAnchor,constant: -10),
            counterCoinsView.topAnchor.constraint(equalTo: sceneView.topAnchor,constant: 50)
        ])
        
        labelCounter.frame = counterCoinsView.bounds
    }
    

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    private func createCounterView() {
        counterCoinsView.addSubview(labelCounter)
        labelCounter.frame = counterCoinsView.bounds
        
        sceneView.addSubview(counterCoinsView)
        counterCoinsView.isHidden = true
    }

    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        if contact.nodeA.categoryBitMask == BodyType.coin.rawValue {
            contact.nodeA.removeFromParentNode()
            
        }
        
        if contact.nodeB.categoryBitMask == BodyType.coin.rawValue {
            contact.nodeB.removeFromParentNode()
        }
        
        if (contact.nodeA.categoryBitMask == BodyType.coin.rawValue &&  contact.nodeB.categoryBitMask == BodyType.cube.rawValue) || (contact.nodeA.categoryBitMask == BodyType.cube.rawValue &&  contact.nodeB.categoryBitMask == BodyType.coin.rawValue)  {
            
            let soundUrl = NSURL(fileURLWithPath: pathForSound!)
       
           
           DispatchQueue.main.async {
               self.countCollectedCoins += 1
               self.labelCounter.text = String(self.countCollectedCoins)
               AudioServicesCreateSystemSoundID(soundUrl , &self.soundID)
               AudioServicesPlaySystemSound(self.soundID)
           }
        }
        
        
    }
    
    @objc private func shortPressCube(touch : UITapGestureRecognizer) {
        
        let location = touch.location(in: sceneView)

        let hits = sceneView.hitTest(location)
                if let tappedNode = hits.first?.node {
                    tappedNode.geometry?.firstMaterial?.diffuse.contents = viewModel.giveColor()
                } else {
                    guard let query = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal) else {return}
        
                    guard let result = sceneView.session.raycast(query).first else {return}
                    let cube = createCubeNode()
                    planeResult = result
                    cube.transform = SCNMatrix4(result.worldTransform)
                    sceneView.scene.rootNode.addChildNode(cube)
                                        
                    cubesArray.append(cube)
                    counter(with: 1)
                    
                }
    }
    
    
    
    @objc private func longPressCube(touch : UITapGestureRecognizer) {
        if touch.state == .began {

            let location = touch.location(in: sceneView)
            let hits = sceneView.hitTest(location)
                    if let tappedNode = hits.first?.node {
                        if tappedNode.categoryBitMask == BodyType.cube.rawValue {
                            tappedNode.removeFromParentNode()
                            counter(with: 0)
                        }
                    } else {

                    }
        }
        
    }
    
    private func createCubeNode() ->SCNNode {
        let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue
        material.specular.contents = UIColor(white: 0.6, alpha: 1.0)
        
        let boxNode = SCNNode(geometry: boxGeometry)
        boxNode.geometry?.materials = [material]
        
        let body = SCNPhysicsBody(type: .static, shape: nil)
        boxNode.physicsBody = body
        
        boxNode.categoryBitMask = BodyType.cube.rawValue
        
        boxNode.physicsBody?.categoryBitMask = BodyType.cube.rawValue
        boxNode.physicsBody?.collisionBitMask = 2
        boxNode.physicsBody?.contactTestBitMask = BodyType.coin.rawValue
        
        
        boxNode.physicsBody?.restitution = 1
        
        return boxNode
    }
    
    private func createCoin() -> SCNNode {
        
        guard let newScene = SCNScene(named: "coin.usdz") else {return SCNNode()}
        guard let coinNode = newScene.rootNode.childNode(withName: "Coin", recursively: true) else {return SCNNode()}
        
        coinNode.transform = SCNMatrix4(planeResult!.worldTransform)
        let position = SCNVector3(x: Float.random(in: -5...5), y: cubesArray[0].position.y, z: Float.random(in: -5...5))
        
        
        coinNode.position = position
       
        
        let body = SCNPhysicsBody(type: .static, shape: nil)
        coinNode.physicsBody = body
        
        coinNode.categoryBitMask = BodyType.coin.rawValue
        coinNode.physicsBody?.categoryBitMask = BodyType.coin.rawValue
        coinNode.physicsBody?.collisionBitMask = 1
        coinNode.physicsBody?.contactTestBitMask = BodyType.cube.rawValue
        
        
        coinNode.physicsBody?.restitution = 1
        
        coinsArray.append(coinNode)
        
        return coinNode
    }
    
    private func createCrystal() -> SCNNode {
        
        guard let newScene = SCNScene(named: "crystal.scn") else {return SCNNode()}
        guard let crystal = newScene.rootNode.childNode(withName: "crystal17_2", recursively: true) else {return SCNNode()}
       // crystal.scale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
        crystal.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "crystal_17_2")
        return crystal
    }
    
    private func counter(with: Int) {
        switch with {
        case 1:
            counterBox += 1
        case 0:
            counterBox -= 1
        default:
            break
        }
        
        if counterBox <= 0 {
            buttons.isHidden = true
            counterCoinsView.isHidden = true
            stopGame()
        } else {
            buttons.isHidden = false
            counterCoinsView.isHidden = false
            startGame()
        }
        
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
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
          guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
          
          let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
          let planeNode = SCNNode(geometry: plane)
          planeNode.position = SCNVector3Make(planeAnchor.center.x,
                                              planeAnchor.center.y,
                                              planeAnchor.center.z)
          
          planeNode.opacity = 0.0
          
          planeNode.rotation = SCNVector4Make(1, 0, 0, -Float.pi / 2.0)
          node.addChildNode(planeNode)
          
          detectedPlanes[planeAnchor.identifier.uuidString] = planeNode
        
        
        
        
        
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        guard let planeNode = detectedPlanes[planeAnchor.identifier.uuidString] else { return }
        
        let planeGeometry = planeNode.geometry as! SCNPlane
        planeGeometry.width = CGFloat(planeAnchor.extent.x)
        planeGeometry.height = CGFloat(planeAnchor.extent.z)
        planeNode.position = SCNVector3Make(planeAnchor.center.x,
                                            planeAnchor.center.y,
                                            planeAnchor.center.z)
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // make sure this is an image anchor, otherwise bail out
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }

        // create a plane at the exact physical width and height of our reference image
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)

        // make the plane have a transparent blue color
        plane.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.5)

        // wrap the plane in a node and rotate it so it's facing us
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2

        // now wrap that in another node and send it back
        let node = SCNNode()
        
        let crystal = createCrystal()
        
        
        node.addChildNode(crystal)
        increaseSpeed()
        
        crystal.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)


        return node
    }
    
    @objc private func playGame() {
        if countCoinsOnScreen < 20 {
            
            DispatchQueue.global(qos: .userInitiated).async {
                let coin = self.createCoin()
                self.sceneView.scene.rootNode.addChildNode(coin)

            }

            
            countCoinsOnScreen+=1
        }
    }
    
    private func startGame() {
        countCollectedCoins = 0
        countCoinsOnScreen = 0
        labelCounter.text = String(countCollectedCoins)

       timerForCoins = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(playGame), userInfo: nil, repeats: true)
    }
    
    private func stopGame() {
        timerForCoins?.invalidate()
        countCollectedCoins = 0
        countCoinsOnScreen = 0
        coinsArray.forEach { coin in
            coin.removeFromParentNode()
        }
        labelCounter.text = String(countCollectedCoins)
    }
    
    private func increaseSpeed() {
        speedScale = 2
    }
    
    private func decreaseSpeed() {
        speedScale = 1
    }
    
    
    @objc private func allMoveLeft() {
        
        guard let front = sceneView.pointOfView?.simdWorldFront else {return}
        let vector = cross(front, simd_float3(0,-0.1 * Float(speedScale) ,0))
        let direction = SCNVector3(x: vector.x,
                                   y: vector.y
                                   , z: vector.z)
        
        let move = SCNAction.move(by: (direction ), duration: 0.1)
        
        cubesArray.forEach { cube in
            cube.runAction(move)
        }
    }
    
    @objc private func allMoveRight() {
        
        guard let front = sceneView.pointOfView?.simdWorldFront else {return}
        
        let vector = cross(front, simd_float3(0,0.1 * Float(speedScale),0))
        let direction = SCNVector3(x: vector.x ,
                                   y: vector.y
                                   , z: vector.z)
        
        let move = SCNAction.move(by: (direction ), duration: 0.1)
        
        cubesArray.forEach { cube in
            cube.runAction(move)
        }
    }
    
    @objc private func allMoveUp() {
               
        let move = SCNAction.moveBy(x: 0, y: 0, z: -0.1 * speedScale, duration: 0.1)
        
        cubesArray.forEach { cube in
            cube.runAction(move)
        }
    }
    
    @objc private func allMoveDown() {
        
        let move = SCNAction.moveBy(x: 0, y: 0, z: 0.1 * speedScale, duration: 0.1)
        
        
        cubesArray.forEach { cube in
            cube.runAction(move)
        }
    }
    
}




extension ViewController : ControlToScene {
    
    func pressedLeft(gesture: UIGestureRecognizer) {
        if gesture.state == .ended {
            timer?.invalidate()
        } else if gesture.state == .began {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(allMoveLeft), userInfo: nil, repeats: true)
        }
    }
    
   
    
    func pressedUp(gesture: UIGestureRecognizer) {
        
        if gesture.state == .ended {
            timer?.invalidate()
        } else if gesture.state == .began {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(allMoveUp), userInfo: nil, repeats: true)
        }

    }
    
    func pressedRight(gesture: UIGestureRecognizer) {
        if gesture.state == .ended {
            timer?.invalidate()
        } else if gesture.state == .began {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(allMoveRight), userInfo: nil, repeats: true)
        }

    }
    
    func pressedDown(gesture: UIGestureRecognizer) {
        if gesture.state == .ended {
            timer?.invalidate()
        } else if gesture.state == .began {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(allMoveDown), userInfo: nil, repeats: true)
        }
    }
    
    
}


extension ViewController : viewModelToView {
    func addImage(image: UIImage) {
        let arImage = ARReferenceImage(image.cgImage!,orientation: .up,physicalWidth: 0.2)
        
        arImage.name = "marker"
        self.images.insert(arImage)
    }
    
    
}
