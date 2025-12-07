//
//  GameScene.swift
//  BeamOfLights
//
//  Fixed: Removed hardcoded 300px offset causing visual shift
//  Fixed: "Magnified" bug caused by aggressive zoom reset in didChangeSize
//

import SpriteKit
import SwiftUI
import Combine

class GameScene: SKScene {
    
    // MARK: - Properties
    weak var gameViewModel: GameViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    private var beamNodes: [UUID: SKNode] = [:]
    
    // FIXED Cell Size: Ensures neon glow always looks sharp
    private let gridCellSize: CGFloat = 50.0
    
    // The total size of the grid in scene coordinates
    private var gridContentSize: CGSize = .zero
    private var gridOrigin: CGPoint = .zero
    
    private var cachedGlowTexture: SKTexture?
    
    private var currentLevelData: Level?
    private var currentBeamsData: [Beam] = []
    
    // Camera
    let gameCamera = SKCameraNode()
    
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
        
        // Setup Camera
        if camera == nil {
            addChild(gameCamera)
            camera = gameCamera
        }
        
        cachedGlowTexture = generateGlowTexture()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        // FIX: Only reset camera if we haven't drawn yet or if the scene was empty
        // Prevents the "Magnified" glitch where a resize resets your zoom unexpectedly
        if size.width > 10 && size.height > 10 {
            if let _ = currentLevelData, beamNodes.isEmpty {
                redraw()
            }
            // Removed the else { setCameraZoom(1.0) } block
            // We do NOT want to force reset zoom on every minor layout pass
        }
    }
    
    // MARK: - Interaction (Zoom & Pan)
    
    func setCameraZoom(_ zoom: CGFloat) {
        guard let level = currentLevelData else { return }
        if size.width < 10 { return }
        
        // 1. Calculate Base Fit Scale (Show entire grid + padding)
        let totalGridWidth = CGFloat(level.gridSize.columns) * gridCellSize + 100
        let fitScale = totalGridWidth / size.width
        
        // 2. Calculate Max Zoom (User can zoom in until 5 cells fill screen)
        // Adjusted from 15.0 to 5.0 to allow closer inspection without "magnified" blur
        let maxZoomInScale = (5.0 * gridCellSize) / size.width
        
        // 3. Apply Zoom
        var targetScale = fitScale / zoom
        
        // Clamp scale so user can't zoom out to infinity or in to a single pixel
        if targetScale > fitScale * 1.5 { targetScale = fitScale * 1.5 } // Allow slight over-zoom-out
        if targetScale < maxZoomInScale { targetScale = maxZoomInScale }
        
        gameCamera.setScale(targetScale)
    }
    
    func panCamera(delta: CGSize) {
        let sensitivity = gameCamera.xScale
        
        // Standardize Pan Direction:
        // If I drag LEFT (negative delta), I want camera to move RIGHT (positive x) so world moves LEFT.
        // Wait, standard mapping: Drag LEFT -> World moves LEFT. Camera moves RIGHT.
        // delta.width is negative. -(-delta) = +Pos. Correct.
        
        gameCamera.position.x -= delta.width * sensitivity
        gameCamera.position.y += delta.height * sensitivity
        
        clampCameraPosition()
    }
    
    private func clampCameraPosition() {
        // FIX: Removed the hardcoded "+ 300" which was creating the offset bug.
        // We now use dynamic padding based on the actual view size.
        let viewPadX = (size.width * gameCamera.xScale) / 2
        let viewPadY = (size.height * gameCamera.yScale) / 2
        
        let hLimit = max(0, gridContentSize.width / 2 - viewPadX + 100)
        let vLimit = max(0, gridContentSize.height / 2 - viewPadY + 100)
        
        // If grid is smaller than screen, center it (limit 0).
        // If grid is larger, allow panning to edge + 100px padding.
        
        let x = max(-hLimit, min(gameCamera.position.x, hLimit))
        let y = max(-vLimit, min(gameCamera.position.y, vLimit))
        
        gameCamera.position = CGPoint(x: x, y: y)
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
        
        if size.width < 10 { return }

        removeAllChildren()
        beamNodes.removeAll()
        
        addChild(gameCamera)
        camera = gameCamera
        
        // 1. Calculate Grid Dimensions
        let columns = CGFloat(level.gridSize.columns)
        let rows = CGFloat(level.gridSize.rows)
        
        let totalWidth = columns * gridCellSize
        let totalHeight = rows * gridCellSize
        gridContentSize = CGSize(width: totalWidth, height: totalHeight)
        
        // 2. Center the grid
        gridOrigin = CGPoint(x: -totalWidth / 2 + gridCellSize / 2, y: totalHeight / 2 - gridCellSize / 2)
        
        // 3. Draw
        drawGrid(rows: level.gridSize.rows, columns: level.gridSize.columns)
        
        for beam in currentBeamsData {
            createBeamNode(for: beam)
        }
        
        // 4. Reset Camera safely
        setCameraZoom(1.0)
        gameCamera.position = .zero
    }
    
    // MARK: - Logic & Animation
    
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
    
    // MARK: - Animation: Slide (Snake Move)
    
    func animateBeamSlide(beamID: UUID, direction: Direction) {
        guard let container = beamNodes[beamID] else { return }
        guard let beam = currentBeamsData.first(where: { $0.id == beamID }) else { return }
        let originalPoints = beam.cells.map { gridPositionToPoint(row: $0.row, col: $0.column) }
        guard !originalPoints.isEmpty else { return }
        
        var trajectory = originalPoints
        let tipPoint = originalPoints.last!
        let exitDistance: CGFloat = 2000.0
        var exitPoint = tipPoint
        switch direction {
        case .right: exitPoint.x += exitDistance
        case .left: exitPoint.x -= exitDistance
        case .up: exitPoint.y += exitDistance
        case .down: exitPoint.y -= exitDistance
        default: break
        }
        trajectory.append(exitPoint)
        
        let beamLength = calculatePathLength(points: originalPoints)
        let totalTrajectoryLength = calculatePathLength(points: trajectory)
        let duration: TimeInterval = 0.6
        
        let slideAction = SKAction.customAction(withDuration: duration) { [weak self] node, elapsedTime in
            guard let self = self else { return }
            let t = CGFloat(elapsedTime / duration)
            let easedT = t * t
            let moveDistance = (totalTrajectoryLength) * easedT
            let startDist = moveDistance
            let endDist = startDist + beamLength
            
            let newPoints = self.extractSubPath(from: trajectory, startDistance: startDist, endDistance: endDist)
            
            if !newPoints.isEmpty {
                self.updateBeamPath(container: node, points: newPoints)
            } else {
                node.isHidden = true
            }
        }
        
        let remove = SKAction.run { [weak self] in
            container.removeFromParent()
            self?.beamNodes.removeValue(forKey: beamID)
        }
        container.run(SKAction.sequence([slideAction, remove]))
    }
    
    // MARK: - Animation: Bounce
    
    func animateBounce(beamID: UUID, direction: Direction) {
        guard let container = beamNodes[beamID] else { return }
        var dx: CGFloat = 0; var dy: CGFloat = 0
        let bounceDist: CGFloat = 20
        
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
        
        let flash = SKAction.run {
            container.children.forEach { node in
                if let shape = node as? SKShapeNode {
                    shape.run(SKAction.sequence([
                        SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0),
                        SKAction.wait(forDuration: 0.05),
                        SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.2)
                    ]))
                }
            }
        }
        
        container.run(SKAction.group([
            SKAction.sequence([moveOut, moveBack]),
            flash
        ]))
    }
    
    // MARK: - Helpers (Math & Rendering)
    
    private func updateBeamPath(container: SKNode, points: [CGPoint]) {
        guard points.count >= 2 else { return }
        let path = CGMutablePath()
        path.move(to: points.first!)
        for p in points.dropFirst() { path.addLine(to: p) }
        
        container.children.forEach { child in
            // FIX: Ensure we only update the Beam lines, not the tip shapes blindly
            if let shape = child as? SKShapeNode, shape.name != "tipDot" && shape.name != "tipSprite" {
                shape.path = path
            }
        }
        
        if let lastPoint = points.last {
            container.children.forEach { child in
                if child.name == "tipSprite" || child.name == "tipDot" {
                    child.position = lastPoint
                    child.isHidden = false
                }
            }
        }
    }
    
    private func gridPositionToPoint(row: Int, col: Int) -> CGPoint {
        let x = gridOrigin.x + CGFloat(col) * gridCellSize
        let y = gridOrigin.y - CGFloat(row) * gridCellSize
        return CGPoint(x: x, y: y)
    }
    
    private func pointToGridPosition(_ point: CGPoint) -> (row: Int, col: Int)? {
        let colFloat = (point.x - gridOrigin.x) / gridCellSize
        let rowFloat = (gridOrigin.y - point.y) / gridCellSize
        
        let col = Int(round(colFloat))
        let row = Int(round(rowFloat))
        
        guard let level = currentLevelData else { return nil }
        if row >= 0 && row < level.gridSize.rows && col >= 0 && col < level.gridSize.columns {
            return (row, col)
        }
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        // FIX: Ensure we use the scene-relative location which respects Camera transform
        let location = touch.location(in: self)
        
        if let (row, col) = pointToGridPosition(location) {
            gameViewModel?.tapBeam(atRow: row, column: col)
        }
    }
    
    private func drawGrid(rows: Int, columns: Int) {
        for r in 0..<rows {
            for c in 0..<columns {
                let dot = SKShapeNode(circleOfRadius: 2)
                dot.fillColor = UIColor.white.withAlphaComponent(0.15)
                dot.strokeColor = .clear
                dot.position = gridPositionToPoint(row: r, col: c)
                dot.zPosition = kZPosGrid
                addChild(dot)
            }
        }
    }
    
    // MARK: - Rendering (The "Laser" Look)

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
        
        // --- 1. The Outer Haze ---
        let outerHaze = SKShapeNode(path: path)
        outerHaze.lineWidth = gridCellSize * 0.4
        outerHaze.strokeColor = beamColor.withAlphaComponent(0.15)
        outerHaze.lineCap = .round
        outerHaze.lineJoin = .round
        outerHaze.blendMode = .add
        outerHaze.zPosition = kZPosBeamGlow
        containerNode.addChild(outerHaze)
        
        // --- 2. The Inner Glow ---
        let innerGlow = SKShapeNode(path: path)
        innerGlow.lineWidth = gridCellSize * 0.2
        innerGlow.strokeColor = beamColor.withAlphaComponent(0.6)
        innerGlow.lineCap = .round
        innerGlow.lineJoin = .round
        innerGlow.blendMode = .add
        innerGlow.zPosition = kZPosBeamGlow + 1
        containerNode.addChild(innerGlow)
        
        // --- 3. The Core ---
        let core = SKShapeNode(path: path)
        core.lineWidth = gridCellSize * 0.05
        core.strokeColor = .white
        core.lineCap = .round
        core.lineJoin = .round
        core.blendMode = .add
        core.zPosition = kZPosBeamCore
        containerNode.addChild(core)
        
        // --- 4. The Tip ---
        if let lastCell = beam.cells.last {
            let tipPos = gridPositionToPoint(row: lastCell.row, col: lastCell.column)
            
            let tipDot = SKShapeNode(circleOfRadius: gridCellSize * 0.1)
            tipDot.name = "tipDot"
            tipDot.fillColor = .white
            tipDot.strokeColor = .white
            tipDot.glowWidth = 2.0
            tipDot.position = tipPos
            tipDot.zPosition = kZPosBeamTip
            tipDot.blendMode = .add
            containerNode.addChild(tipDot)
            
            let tipAura = SKShapeNode(circleOfRadius: gridCellSize * 0.15)
            tipAura.name = "tipSprite"
            tipAura.fillColor = beamColor.withAlphaComponent(0.4)
            tipAura.strokeColor = .clear
            tipAura.position = tipPos
            tipAura.zPosition = kZPosBeamTip - 1
            tipAura.blendMode = .add
            containerNode.addChild(tipAura)
        }
        
        beamNodes[beam.id] = containerNode
        addChild(containerNode)
    }
    
    // MARK: - Utilities
    
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
    
    private func extractSubPath(from points: [CGPoint], startDistance: CGFloat, endDistance: CGFloat) -> [CGPoint] {
        var result: [CGPoint] = []
        var currentDist: CGFloat = 0
        for i in 0..<(points.count - 1) {
            let p1 = points[i]; let p2 = points[i+1]
            let segmentDist = hypot(p2.x - p1.x, p2.y - p1.y)
            let nextDist = currentDist + segmentDist
            if nextDist > startDistance && currentDist < endDistance {
                let entryRatio = max(0, (startDistance - currentDist) / segmentDist)
                let pEntry = CGPoint(x: p1.x + (p2.x - p1.x) * entryRatio, y: p1.y + (p2.y - p1.y) * entryRatio)
                let exitRatio = min(1, (endDistance - currentDist) / segmentDist)
                let pExit = CGPoint(x: p1.x + (p2.x - p1.x) * exitRatio, y: p1.y + (p2.y - p1.y) * exitRatio)
                if result.isEmpty { result.append(pEntry) }
                if exitRatio >= 1.0 { result.append(p2) } else { result.append(pExit) }
            }
            currentDist = nextDist
            if currentDist >= endDistance { break }
        }
        return result
    }
    
    private func calculatePathLength(points: [CGPoint]) -> CGFloat {
        var dist: CGFloat = 0
        for i in 0..<(points.count - 1) { dist += hypot(points[i+1].x - points[i].x, points[i+1].y - points[i].y) }
        return dist
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
        if colorString.hasPrefix("#"), let color = UIColor(hex: colorString) { return color }
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
// MARK: - Extensions

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

