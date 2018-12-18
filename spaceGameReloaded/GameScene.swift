//
//  GameScene.swift
//  spaceGameReloaded
//
//  Created by Nolan Turley on 12/15/18.
//  Copyright © 2018 Nolan Turley. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var activeGame = false
    
    var bounds = UIScreen.main.bounds
    
    var starfield:SKEmitterNode!
    var player:SKSpriteNode!
    
    var scoreLabel:SKLabelNode!
    var score:Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var height:CGFloat!
    var width:CGFloat!
   
    var gameTimer:Timer!
    
    var possibleAliens = ["alien", "alien2", "alien3"]
    
    let alienCategory:UInt32 = 0x1 << 1
    let photonTorpedoCategory:UInt32 = 0x1 << 0
    let spaceShipCategory: UInt32 = 0x1 << 2
    
    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0
    
    var torpedoTexture = SKTexture()
    
    override func didMove(to view: SKView) {
        activeGame = true
        
        height = self.bounds.size.height
        width = self.bounds.size.width
        
        //set torpedo image for future use
        let torpedoImage = UIImage(named: "torpedo")
        torpedoTexture = SKTexture(image: torpedoImage!)

        starfield = SKEmitterNode(fileNamed: "Starfield")
        starfield.position = CGPoint(x: 0, y: (self.view?.frame.maxY)!)
        starfield.advanceSimulationTime(12)
        self.addChild(starfield)
        
        starfield.zPosition = -1
        
        player = SKSpriteNode(imageNamed: "shuttle")
        player.size.height = player.size.height * 2
        player.size.width = player.size.width * 2
        player.position = CGPoint(x: 0, y: height / -1.25)
        
        
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true
        
        player.physicsBody?.categoryBitMask = spaceShipCategory
        player.physicsBody?.contactTestBitMask = alienCategory
        player.physicsBody?.collisionBitMask = 0
        
        
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: width / -1.25, y: height / 1.25)
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontColor = UIColor.white
        scoreLabel.fontSize = 36
        
        self.addChild(scoreLabel)
        
        
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data:CMAccelerometerData?, error:Error?) in
            if let acceleramitorData = data {
                let acceleration = acceleramitorData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
            }
        }
    }
    
    @objc func addAlien() {
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        alien.size.height = alien.size.height * 2
        alien.size.width = alien.size.width * 2
        
        let lowestPosition = -1 * self.width + alien.size.width
        let highestPosition = width - alien.size.width
        
        let randomAlienPosition = GKRandomDistribution(lowestValue: Int(lowestPosition), highestValue: Int(highestPosition))
        let position = CGFloat(randomAlienPosition.nextInt())
        alien.position = CGPoint(x: position, y: height + alien.size.height)
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        let animationDuration:TimeInterval = 6
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -(CGFloat(height)) ), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        alien.run(SKAction.sequence(actionArray))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (activeGame) {
            fireTorpedo()
        }
    }
    
    func fireTorpedo(){
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        let torpedoNode = SKSpriteNode(texture: torpedoTexture)
        torpedoNode.size.height = torpedoNode.size.height * 1.5
        torpedoNode.size.width = torpedoNode.size.width * 1.5
        torpedoNode.position = player.position
        torpedoNode.position.y += 5
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width/2)
        torpedoNode.physicsBody?.isDynamic = true
        
        torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = alienCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(torpedoNode)
        
        let animationDuration:TimeInterval = 0.5
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.size.height + 10 ), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        torpedoNode.run(SKAction.sequence(actionArray))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }
        else {
            secondBody = contact.bodyA
            firstBody = contact.bodyB
        }
        
        if ((firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0) {
            torpedoDidCollideWithAlien(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode )
        } else if ((secondBody.categoryBitMask & spaceShipCategory) != 0 && (firstBody.categoryBitMask & alienCategory) != 0) {
            alienDidEndGame(alienNode: secondBody.node as! SKSpriteNode)
        }
    }
    
    func torpedoDidCollideWithAlien(torpedoNode:SKSpriteNode, alienNode:SKSpriteNode) {
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = alienNode.position
        self.addChild(explosion)
        SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false)
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2)) {
            explosion.removeFromParent()
        }
        
        score += 5
    }
    
    func alienDidEndGame(alienNode:SKSpriteNode) {
        if (gameTimer != nil) {
            gameTimer.invalidate()
        }
        player.removeFromParent()
        alienNode.removeFromParent()
        motionManager.stopAccelerometerUpdates()
        activeGame = false
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = alienNode.position
        self.addChild(explosion)
        SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false)
        
        let gameOver = SKLabelNode(text: "Game Over\nScore = \(score)")
        gameOver.numberOfLines = 2
        gameOver.fontSize = 36
        gameOver.position = CGPoint(x: 0, y: 0)
        gameOver.fontName = "AmericanTypewriter-Bold"
        gameOver.fontColor = UIColor.white
        gameOver.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        self.addChild(gameOver)
    }
    
    override func didSimulatePhysics() {
        player.position.x += xAcceleration * 50
        
        if player.position.x < (-1 * self.width) {
            player.position = CGPoint(x: self.width ,y: player.position.y)
        } else if player.position.x > self.width {
            player.position = CGPoint(x: -1 * self.width, y: player.position.y)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
