//
//  GameScene.swift
//  BeamOfLights
//
//  Fixed: "Snake-like" movement logic.
//  The beam now flows along the grid lines instead of sliding as a rigid block.
//

import SpriteKit
import SwiftUI
import Combine

class GameScene: SKScene {
    
    // MARK: - Properties
    weak var gameViewModel: GameViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    private var beamNodes: [UUID: SKNode] = [:]
    private var gridCellSize: CGFloat = 0
    private var gridOrigin: CGPoint = .zero
    private var cachedGlowTexture: SKTexture?
    
    private var currentLevelData: Level?
    private var currentBeamsData: [Beam] = []
    
    // Z-Positions
    private let kZPosGrid: CGFloat = 0
    private let kZPosBeamGlow: CGFloat = 10
    private let kZPosBeamCore: CGFloat = 11
    private let kZPosBeamTip: CGFloat = 12

    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        view.allowsTransparency = true
        physicsWorld.gravity = .zero
        cachedGlowTexture = generateGlowTexture()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if let level = currentLevelData {
            redraw()
        }
    }
    
    // MARK: - Setup
    
    func setupLevel(level: Level, beams: [Beam]) {
        self.currentLevelData = level
        self.currentBeamsData = deduplicateBeams(beams)
        
        cancellables.removeAll()
        gameViewModel?.gameActions
            .sink { [weak self] action in
                self?.handleGameAction(action)
            }
            .store(in: &cancellables)
            
        redraw()
    }
    
    private func redraw() {
        guard let level = currentLevelData else { return }
        guard size.width > 100 && size.height > 100 else { return }

        removeAllChildren()
        beamNodes.removeAll()
        
        calculateGridMetrics(rows: level.gridSize.rows, columns: level.gridSize.columns)
        drawGrid(rows: level.gridSize.rows, columns: level.gridSize.columns)
        
        for beam in currentBeamsData {
            createBeamNode(for: beam)
        }
    }
    
    // MARK: - Snake Animation Logic (The Fix)
    
    func animateBeamSlide(beamID: UUID, direction: Direction) {
        guard let container = beamNodes[beamID] else { return }
        
        // 1. Get the original points of the beam
        guard let beam = currentBeamsData.first(where: { $0.id == beamID }) else { return }
        let originalPoints = beam.cells.map { gridPositionToPoint(row: $0.row, col: $0.column) }
        guard !originalPoints.isEmpty else { return }
        
        // 2. Build the "Trajectory"
        // This is the path the snake will follow: existing body + extension off-screen
        var trajectory = originalPoints
        let tipPoint = originalPoints.last!
        
        // Extend the path far off-screen in the slide direction
        let exitDistance: CGFloat = 1000.0
        var exitPoint = tipPoint
        switch direction {
        case .right: exitPoint.x += exitDistance
        case .left: exitPoint.x -= exitDistance
        case .up: exitPoint.y += exitDistance
        case .down: exitPoint.y -= exitDistance
        default: break
        }
        trajectory.append(exitPoint)
        
        // 3. Calculate lengths
        let beamLength = calculatePathLength(points: originalPoints)
        let totalTrajectoryLength = calculatePathLength(points: trajectory)
        
        // 4. Animate!
        // We will move a "window" of length `beamLength` along the `trajectory`
        let duration: TimeInterval = 0.6
        
        let slideAction = SKAction.customAction(withDuration: duration) { [weak self] node, elapsedTime in
            guard let self = self else { return }
            
            // Calculate progress (0.0 to 1.0)
            // Use easeIn to make it accelerate out
            let t = CGFloat(elapsedTime / duration)
            let easedT = t * t // Quadratic ease in
            
            // How far has the tail moved?
            // We want the tail to go from 0 to (totalTrajectoryLength + beamLength) ideally,
            // but practically just moving enough to clear the screen is fine.
            let moveDistance = (totalTrajectoryLength) * easedT
            
            // Current Window
            let startDist = moveDistance
            let endDist = startDist + beamLength
            
            // Extract the new shape for this frame
            let newPoints = self.extractSubPath(from: trajectory, startDistance: startDist, endDistance: endDist)
            
            // Update the shapes inside the container
            if !newPoints.isEmpty {
                self.updateBeamPath(container: node, points: newPoints)
            } else {
                // If empty (gone off screen), hide it
                node.isHidden = true
            }
        }
        
        let remove = SKAction.run { [weak self] in
            container.removeFromParent()
            self?.beamNodes.removeValue(forKey: beamID)
        }
        
        container.run(SKAction.sequence([slideAction, remove]))
    }
    
    // Updates the CGPaths of the existing shape nodes
    private func updateBeamPath(container: SKNode, points: [CGPoint]) {
        guard points.count >= 2 else { return }
        
        let path = CGMutablePath()
        path.move(to: points.first!)
        for p in points.dropFirst() {
            path.addLine(to: p)
        }
        
        // Update all SKShapeNodes inside the container
        container.children.forEach { child in
            if let shape = child as? SKShapeNode, shape.name != "tipDot" {
                // Don't update the dot shape path, only the lines
                shape.path = path
            }
        }
        
        // Update the Tip (Sprite & Dot) position
        if let lastPoint = points.last {
            container.children.forEach { child in
                if child.name == "tipSprite" || child.name == "tipDot" {
                    child.position = lastPoint
                    child.isHidden = false
                }
            }
        } else {
             // If beam is disappearing, hide tip
             container.children.forEach { child in
                if child.name == "tipSprite" || child.name == "tipDot" {
                    child.isHidden = true
                }
            }
        }
    }
    
    // MARK: - Path Math Helpers
    
    // Extracts a sub-segment of a polyline. This handles corners correctly.
    private func extractSubPath(from points: [CGPoint], startDistance: CGFloat, endDistance: CGFloat) -> [CGPoint] {
        var result: [CGPoint] = []
        var currentDist: CGFloat = 0
        
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i+1]
            let segmentDist = hypot(p2.x - p1.x, p2.y - p1.y)
            let nextDist = currentDist + segmentDist
            
            // Check if this segment overlaps with our window [startDistance, endDistance]
            if nextDist > startDistance && currentDist < endDistance {
                
                // Calculate entry point
                let entryRatio = max(0, (startDistance - currentDist) / segmentDist)
                let pEntry = CGPoint(
                    x: p1.x + (p2.x - p1.x) * entryRatio,
                    y: p1.y + (p2.y - p1.y) * entryRatio
                )
                
                // Calculate exit point
                let exitRatio = min(1, (endDistance - currentDist) / segmentDist)
                let pExit = CGPoint(
                    x: p1.x + (p2.x - p1.x) * exitRatio,
                    y: p1.y + (p2.y - p1.y) * exitRatio
                )
                
                if result.isEmpty {
                    result.append(pEntry)
                }
                
                // If we include the full end of this segment, add it (preserves corner)
                // Unless pExit is the end
                if exitRatio >= 1.0 {
                     result.append(p2)
                } else {
                     result.append(pExit)
                }
            }
            
            currentDist = nextDist
            if currentDist >= endDistance { break }
        }
        
        return result
    }
    
    private func calculatePathLength(points: [CGPoint]) -> CGFloat {
        var dist: CGFloat = 0
        for i in 0..<(points.count - 1) {
            dist += hypot(points[i+1].x - points[i].x, points[i+1].y - points[i].y)
        }
        return dist
    }
    
    // MARK: - Standard Rendering (Setup)
    
    private func createBeamNode(for beam: Beam) {
        let containerNode = SKNode()
        containerNode.name = beam.id.uuidString
        
        let path = CGMutablePath()
        guard let firstCell = beam.cells.first else { return }
        
        path.move(to: gridPositionToPoint(row: firstCell.row, col: firstCell.column))
        for cell in beam.cells.dropFirst() {
            path.addLine(to: gridPositionToPoint(row: cell.row, col: cell.column))
        }
        
        let beamColor = uiColor(from: beam.color)
        
        // 1. Glow
        let glow = SKShapeNode(path: path)
        glow.lineWidth = gridCellSize * 0.7
        glow.strokeColor = beamColor.withAlphaComponent(0.5)
        glow.lineCap = .round
        glow.lineJoin = .round
        glow.blendMode = .alpha
        glow.zPosition = kZPosBeamGlow
        containerNode.addChild(glow)
        
        // 2. Body
        let body = SKShapeNode(path: path)
        body.lineWidth = gridCellSize * 0.35
        body.strokeColor = beamColor
        body.lineCap = .round
        body.lineJoin = .round
        body.zPosition = kZPosBeamCore
        containerNode.addChild(body)
        
        // 3. Core
        let core = SKShapeNode(path: path)
        core.lineWidth = gridCellSize * 0.12
        core.strokeColor = UIColor.white.withAlphaComponent(0.8)
        core.lineCap = .round
        core.lineJoin = .round
        core.zPosition = kZPosBeamCore + 1
        containerNode.addChild(core)
        
        // 4. Tip
        if let lastCell = beam.cells.last {
            let tipPos = gridPositionToPoint(row: lastCell.row, col: lastCell.column)
            
            let tipSprite = SKSpriteNode(texture: cachedGlowTexture)
            tipSprite.name = "tipSprite" // Identify for animation
            tipSprite.color = beamColor
            tipSprite.colorBlendFactor = 1.0
            tipSprite.size = CGSize(width: gridCellSize * 1.0, height: gridCellSize * 1.0)
            tipSprite.position = tipPos
            tipSprite.zPosition = kZPosBeamTip
            containerNode.addChild(tipSprite)
            
            let tipDot = SKShapeNode(circleOfRadius: gridCellSize * 0.15)
            tipDot.name = "tipDot" // Identify for animation
            tipDot.fillColor = .white
            tipDot.strokeColor = .clear
            tipDot.position = tipPos
            tipDot.zPosition = kZPosBeamTip + 1
            containerNode.addChild(tipDot)
        }

        beamNodes[beam.id] = containerNode
        addChild(containerNode)
    }

    // MARK: - Helpers (Keep Deduplication & Utils)
    
    private func deduplicateBeams(_ beams: [Beam]) -> [Beam] {
        var uniqueBeams: [Beam] = []
        var seenPaths: Set<String> = []
        
        for beam in beams {
            let pathSignature = beam.cells.map { "\($0.row):\($0.column)" }.joined(separator: "-")
            let fullSignature = "\(beam.color)-\(pathSignature)"
            
            if !seenPaths.contains(fullSignature) {
                seenPaths.insert(fullSignature)
                uniqueBeams.append(beam)
            }
        }
        return uniqueBeams
    }
    
    private func handleGameAction(_ action: GameAction) {
        switch action {
        case .slideOut(let beamID, let direction):
            animateBeamSlide(beamID: beamID, direction: direction)
        case .bounce(let beamID, let direction):
            animateBounce(beamID: beamID, direction: direction)
        case .reset:
            redraw()
        }
    }
    
    private func calculateGridMetrics(rows: Int, columns: Int) {
        let performantWidth = size.width * 0.85
        let performantHeight = size.height * 0.85
        
        let widthPerCell = performantWidth / CGFloat(columns)
        let heightPerCell = performantHeight / CGFloat(rows)
        gridCellSize = min(widthPerCell, heightPerCell)
        
        let totalGridWidth = gridCellSize * CGFloat(columns)
        let totalGridHeight = gridCellSize * CGFloat(rows)
        
        gridOrigin = CGPoint(
            x: (size.width - totalGridWidth) / 2 + gridCellSize / 2,
            y: (size.height - totalGridHeight) / 2 + gridCellSize / 2
        )
    }
    
    private func drawGrid(rows: Int, columns: Int) {
        for r in 0..<rows {
            for c in 0..<columns {
                let dot = SKShapeNode(circleOfRadius: 2)
                dot.fillColor = UIColor.gray.withAlphaComponent(0.3)
                dot.strokeColor = .clear
                dot.position = gridPositionToPoint(row: r, col: c)
                dot.zPosition = kZPosGrid
                addChild(dot)
            }
        }
    }
    
    private func gridPositionToPoint(row: Int, col: Int) -> CGPoint {
        let x = gridOrigin.x + CGFloat(col) * gridCellSize
        let y = size.height - (gridOrigin.y + CGFloat(row) * gridCellSize)
        return CGPoint(x: x, y: y)
    }
    
    private func pointToGridPosition(_ point: CGPoint) -> (row: Int, col: Int)? {
        let rowFloat = (size.height - point.y - gridOrigin.y) / gridCellSize
        let colFloat = (point.x - gridOrigin.x) / gridCellSize
        let row = Int(round(rowFloat))
        let col = Int(round(colFloat))
        return (row, col)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if let (row, col) = pointToGridPosition(location) {
            gameViewModel?.tapBeam(atRow: row, column: col)
        }
    }
    
    func animateBounce(beamID: UUID, direction: Direction) {
        // Simple bounce doesn't need path morphing, can stay as is
        guard let container = beamNodes[beamID] else { return }
        var dx: CGFloat = 0; var dy: CGFloat = 0
        let bounceDist: CGFloat = 15
        switch direction {
        case .right: dx = bounceDist
        case .left: dx = -bounceDist
        case .up: dy = bounceDist
        case .down: dy = -bounceDist
        default: break
        }
        let moveOut = SKAction.moveBy(x: dx, y: dy, duration: 0.08)
        moveOut.timingMode = .easeOut
        let moveBack = moveOut.reversed()
        container.run(SKAction.sequence([moveOut, moveBack]))
    }
    
    private func generateGlowTexture() -> SKTexture {
        let size = CGSize(width: 64, height: 64)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
        let center = CGPoint(x: 32, y: 32)
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 30, options: [])
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return SKTexture(image: image)
    }

    private func uiColor(from colorString: String) -> UIColor {
        if colorString.hasPrefix("#"), let color = UIColor(hex: colorString) {
            return color
        }
        switch colorString.lowercased() {
        case "blue": return .cyan
        case "pink": return .systemPink
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "yellow": return .yellow
        default: return .white
        }
    }
}

// Ensure Hex Extension is present
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        let length = hexSanitized.count
        let r, g, b, a: CGFloat
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
