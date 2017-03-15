//
//  ViewController.swift
//  SwiftSceneKitVehicleDemo
//
//  Created by Matteo Cocon on 18/01/15.
//  Copyright (c) 2015 Matteo Cocon. All rights reserved.
//

import UIKit
import SceneKit
import SpriteKit
import GameController
import CoreMotion

class ViewController: UIViewController, SCNSceneRendererDelegate {
  
  lazy var cameraNode = SCNNode() //the node that owns the camera
  lazy var spotLightNode = SCNNode()
  lazy var vehicleNode = SCNNode()
  lazy var vehicle = SCNPhysicsVehicle()
  let motionManager = CMMotionManager()
  lazy var accelerometer = [UIAccelerationValue(0), UIAccelerationValue(0), UIAccelerationValue(0)]
  lazy var _orientation = CGFloat(0)
  lazy var _vehicleSteering = CGFloat(0) // steering factor
  
  
  // MARK: init
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        let scnView = view as! GameSCNView
        let scene = setupScene()
        scnView.scene = scene
        
        //tweak physics
        scnView.scene?.physicsWorld.speed = 4.0
        
        setupAccelerometer()
        
        scnView.pointOfView = cameraNode;
        
        scnView.delegate = self;
        
        // reset view on double tap with 2 fingers
        let doubleTap = UITapGestureRecognizer(target: self,
                                               action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 2
        scnView.gestureRecognizers = [doubleTap]
        
    }

    func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let scene: SCNScene = setupScene()
        let scnView = view as! GameSCNView
        scnView.scene = scene
        scnView.scene?.physicsWorld.speed = 4.0
        scnView.pointOfView = cameraNode
        scnView.touchCount = 0
    }
    
    func deviceName() -> String {
        return UIDevice.current.modelName
    }
  
  
    func isHighEndDevice()->Bool {
        if (deviceName().hasPrefix("iPad4")
            || deviceName().hasPrefix("iPhone6")
            || deviceName().hasPrefix("iPhone7")
            ) {
            return true
        }
        return false
    }
  
  
    func setupEnvironment(_ scene:SCNScene) {
        
        // add an ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = SCNLight.LightType.ambient
        ambientLight.light?.color = UIColor(white: 0.3, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        // add a key light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = SCNLight.LightType.spot
        if(isHighEndDevice()){
            lightNode.light?.castsShadow = true
        }
        lightNode.light?.color = UIColor(white: 0.8, alpha: 1.0)
        lightNode.position = SCNVector3Make(0, 80, 30)
        lightNode.rotation = SCNVector4Make(1,0,0, Float(-(M_PI/2.8)))
        lightNode.light?.spotInnerAngle = 0
        lightNode.light?.spotOuterAngle = 50
        lightNode.light?.shadowColor = UIColor(white: 0, alpha: 1)
        lightNode.light?.zFar = 500
        lightNode.light?.zNear = 50
        scene.rootNode.addChildNode(lightNode)
        spotLightNode = lightNode
        
        //floor
        let floor = SCNNode()
        let floorGeom = SCNFloor()
        floorGeom.firstMaterial?.diffuse.contents = "concrete.png"
        floorGeom.firstMaterial?.locksAmbientWithDiffuse = true
        if(isHighEndDevice()){
            floorGeom.reflectionFalloffEnd = 10
        }
        floor.geometry = floorGeom
        let staticBody = SCNPhysicsBody.static()
        floor.physicsBody = staticBody
        scene.rootNode.addChildNode(floor)
        
    }
    
    
    func setupSceneElements(_ scene:SCNScene) {
        
        // add scene elements
        
    }
    
    func getNode(_ nodeName:String, fromDaePath:String)->SCNNode {
        
        if let scene = SCNScene(named: fromDaePath){
            if let node = scene.rootNode
                .childNode(withName: nodeName, recursively: true){
                return node
            } else {
                fatalError("unable to get node by name: \(nodeName)")
            }
        } else {
            fatalError("unable to ger scene from path: \(fromDaePath)")
        }
        
    }
    
    func setupVehicle(_ scene:SCNScene)->SCNNode {
        
        // add chassisNode
        let chassisNode = getNode("rccarBody", fromDaePath: "rc_car.dae")
        chassisNode.position = SCNVector3Make(0, 10, 30)
        chassisNode.rotation = SCNVector4Make(0, 1, 0, Float(M_PI))
        let body = SCNPhysicsBody.dynamic()
        body.allowsResting = false
        body.mass = 80
        body.restitution = 0.1
        body.friction = 0.5
        body.rollingFriction = 0
        chassisNode.physicsBody = body
        scene.rootNode.addChildNode(chassisNode)
        
        // add wheels
        let wheelnode0 = chassisNode
            .childNode(withName: "wheelLocator_FL", recursively: true)
        let wheelnode1 = chassisNode
            .childNode(withName: "wheelLocator_FR", recursively: true)
        let wheelnode2 = chassisNode
            .childNode(withName: "wheelLocator_RL", recursively: true)
        let wheelnode3 = chassisNode
            .childNode(withName: "wheelLocator_RR", recursively: true)
        let wheel0 = SCNPhysicsVehicleWheel(node: wheelnode0!)
        let wheel1 = SCNPhysicsVehicleWheel(node: wheelnode1!)
        let wheel2 = SCNPhysicsVehicleWheel(node: wheelnode2!)
        let wheel3 = SCNPhysicsVehicleWheel(node: wheelnode3!)
        let min = SCNVector3(x: 0, y: 0, z: 0)
        let max = SCNVector3(x: 0, y: 0, z: 0)
        wheelnode0?.boundingBox.max = max
        wheelnode0?.boundingBox.min = min
        
        let wheelHalfWidth = Float(0.5 * (max.x - min.x))
        var w0 = wheelnode0?.convertPosition(SCNVector3Zero, to: chassisNode)
        w0 = w0! + SCNVector3Make(wheelHalfWidth, 0, 0)
        wheel0.connectionPosition = w0!
        var w1 = wheelnode1?.convertPosition(SCNVector3Zero, to: chassisNode)
        w1 = w1! - SCNVector3Make(wheelHalfWidth, 0, 0)
        wheel1.connectionPosition = w1!
        var w2 = wheelnode2?.convertPosition(SCNVector3Zero, to: chassisNode)
        w2 = w2! + SCNVector3Make(wheelHalfWidth, 0, 0)
        wheel2.connectionPosition = w2!
        var w3 = wheelnode3?.convertPosition(SCNVector3Zero, to: chassisNode)
        w3 = w3! - SCNVector3Make(wheelHalfWidth, 0, 0)
        wheel3.connectionPosition = w3!
        
        // set physics
        vehicle = SCNPhysicsVehicle(chassisBody: chassisNode.physicsBody!,
                                    wheels: [wheel0, wheel1, wheel2, wheel3])
        scene.physicsWorld.addBehavior(vehicle)
        
        return chassisNode
        
    }
    
    
    func setupScene()->SCNScene {
        
        let scene = SCNScene()
        setupEnvironment(scene)
        setupSceneElements(scene)
        vehicleNode = setupVehicle(scene)
        
        //create a main camera
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 500;
        cameraNode.position = SCNVector3Make(0, 60, 50)
        cameraNode.rotation  = SCNVector4Make(1, 0, 0, Float(-M_PI_4*0.75))
        scene.rootNode.addChildNode(cameraNode)
        
        //add a secondary camera to the car
        let frontCameraNode = SCNNode()
        frontCameraNode.position = SCNVector3Make(0, 3.5, 2.5)
        frontCameraNode.rotation = SCNVector4Make(0, 1, 0, Float(M_PI))
        frontCameraNode.camera = SCNCamera()
        frontCameraNode.camera?.xFov = 75
        frontCameraNode.camera?.zFar = 500
        vehicleNode.addChildNode(frontCameraNode)
        
        return scene
    }
    
    func setupAccelerometer() {
        
        let controllers = GCController.controllers()
        if(controllers.count == 0 && motionManager.isAccelerometerAvailable == true){
            motionManager.accelerometerUpdateInterval = 1/60.0
            motionManager.startAccelerometerUpdates(
                to: OperationQueue.main,
                withHandler: { (accelerometerData: CMAccelerometerData?, error: Error?) in
                    self.accelerometerDidChange(accelerometerData!.acceleration)
                }
            )
        }
    }
    
    // MARK: game logic
    func renderer(_ aRenderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        
        let defaultEngineForce = CGFloat(300.0)
        let defaultBrakingForce = CGFloat(3.0)
        let steeringClamp = CGFloat(0.6)
        let cameraDamping = Float(0.3)
        
        let scnView = view as! GameSCNView
        
        var engineForce = CGFloat(0)
        var brakingForce = CGFloat(0)
        
        var orientation = _orientation
        
        //drive: 1 touch = accelerate, 2 touches = backward, 3 touches = brake
        if (scnView.touchCount == 1) {
            engineForce = defaultEngineForce
        } else if (scnView.touchCount == 2) {
            engineForce = -defaultEngineForce
        } else if (scnView.touchCount == 3) {
            brakingForce = 100
        } else {
            brakingForce = defaultBrakingForce
        }
        
        //controller support
        let INCR_ORIENTATION = Float(0.03)
        let DECR_ORIENTATION = Float(0.80)
        
        if let _ = GCController.controllers().first {
            let controllers = GCController.controllers()
            if(controllers.count > 0) {
                
                var controller: AnyObject = controllers[0]
                if let pad = controller.gamepad {
                    if let dpad = pad?.dpad {
                        // directional gamepad profile analog control
                        
                        var orientationCum = Float(0)
                        
                        if (dpad.right.isPressed) {
                            if (orientationCum < 0) {
                                orientationCum *= DECR_ORIENTATION
                            }
                            orientationCum += INCR_ORIENTATION
                            if (orientationCum > 1) {
                                orientationCum = 1
                            }
                        } else if (dpad.left.isPressed) {
                            if (orientationCum > 0) {
                                orientationCum *= DECR_ORIENTATION
                            }
                            orientationCum -= INCR_ORIENTATION
                            if (orientationCum < -1) {
                                orientationCum = -1
                            }
                        } else {
                            orientationCum *= DECR_ORIENTATION
                        }
                        
                        orientation = CGFloat(orientationCum)
                    }
                    if (pad?.buttonX.isPressed)! {
                        engineForce = defaultEngineForce;
                        //_reactor.birthRate = _reactorDefaultBirthRate;
                    } else if (pad?.buttonA.isPressed)! {
                        engineForce = -defaultEngineForce;
                        //_reactor.birthRate = 0;
                    } else if (pad?.buttonB.isPressed)! {
                        brakingForce = 100;
                        //_reactor.birthRate = 0;
                    } else {
                        brakingForce = defaultBrakingForce;
                        //_reactor.birthRate = 0;
                    }
                }
            }
        }
        
        // steering
        _vehicleSteering = -orientation
        if (orientation==0) {
            _vehicleSteering *= 0.9
        }
        if (_vehicleSteering < -steeringClamp) {
            _vehicleSteering = -steeringClamp;
        }
        if (_vehicleSteering > steeringClamp) {
            _vehicleSteering = steeringClamp;
        }
        
        //update the vehicle steering and acceleration
        vehicle.setSteeringAngle(_vehicleSteering, forWheelAt: 0)
        vehicle.setSteeringAngle(_vehicleSteering, forWheelAt: 1)
        
        vehicle.applyEngineForce(engineForce, forWheelAt: 2)
        vehicle.applyEngineForce(engineForce, forWheelAt: 3)
        
        vehicle.applyBrakingForce(brakingForce, forWheelAt: 2)
        vehicle.applyBrakingForce(brakingForce, forWheelAt: 3)
        
        //check if the car is upside down
        reorientCarIfNeeded()
        
        // make camera follow the car node
        let car = vehicleNode.presentation
        let carPos = car.position
        let targetPos = SCNVector3Make(carPos.x, Float(30), Float(carPos.z + 25))
        var cameraPos = cameraNode.position
        cameraPos = vector_mix(cameraPos, targetPos: targetPos, cameraDamping: cameraDamping)
        cameraNode.position = cameraPos
        
        // move spot light
        if (scnView.inCarView) {
            //move spot light in front of the camera
            if let cameraNode = scnView.pointOfView{
                let frontPosition = cameraNode.presentation.convertPosition(SCNVector3Make(0, 0, -30), to:nil)
                spotLightNode.position = SCNVector3Make(frontPosition.x, Float(80), frontPosition.z)
                spotLightNode.rotation = SCNVector4Make(1,0,0,Float(-M_PI/2))
            }
        }
        else {
            //move spot light on top of the car
            spotLightNode.position = SCNVector3Make(carPos.x, Float(80), carPos.z + Float(30))
            spotLightNode.rotation = SCNVector4Make(1, 0, 0, Float(-M_PI/2.8))
        }
    }
    
    
    func reorientCarIfNeeded() {
        let car = vehicleNode.presentation
        let carPos = car.position
        
        var ticks = 0
        var check = 0
        ticks += 1
        if (ticks == 30 ) {
            let t = car.worldTransform
            if(t.m22 <= 0.1) {
                check += 1
                if(check == 3) {
                    var trial = 0
                    trial += 1
                    if(trial == 3) {
                        trial = 0
                        // hard reset
                        vehicleNode.rotation = SCNVector4Make(0, 0, 0, 0)
                        vehicleNode.position = SCNVector3Make(carPos.x, carPos.y, carPos.z)
                        vehicleNode.physicsBody?.resetTransform()
                    } else {
                        //try to upturn with an random impulse
                        let _x = Float( 10 * (Float(arc4random()) / Float(RAND_MAX) - 0.5 ))
                        let _z = Float( 10 * (Float(arc4random()) / Float(RAND_MAX) - 0.5 ))
                        _ = SCNVector3Make(_x, 0, _z)
                    }
                    check = 0
                }
            } else {
                check = 0
            }
            ticks = 0
        }
    }
    
    
    func accelerometerDidChange(_ acceleration: CMAcceleration) {
        
        let kFilteringFactor = 0.5
        accelerometer[0] = acceleration.x * kFilteringFactor +
            accelerometer[0] * (1.0 - kFilteringFactor)
        accelerometer[1] = acceleration.y * kFilteringFactor +
            accelerometer[1] * (1.0 - kFilteringFactor)
        accelerometer[2] = acceleration.z * kFilteringFactor +
            accelerometer[2] * (1.0 - kFilteringFactor)
        
        let orientationModule = CGFloat(accelerometer[1] * 1.3)
        
        if(accelerometer[0] > 0) {
            _orientation = orientationModule
        } else {
            _orientation = -orientationModule
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        motionManager.stopDeviceMotionUpdates()
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
