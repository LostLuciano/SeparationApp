import UIKit

class BeatGridView: UIView {
    private let gridLayer = CAShapeLayer()
    private var beatPositions: [CGFloat] = []
    
    var beats: Int = 4 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var currentBeat: Int = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = UIColor(white: 1.0, alpha: 0.03)
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        layer.cornerRadius = StudioTheme.shared.cornerRadius12
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let padding: CGFloat = 16
        let availableWidth = rect.width - padding * 2
        let beatWidth = availableWidth / CGFloat(beats)
        let centerY = rect.height / 2
        let beatRadius: CGFloat = 8
        
        beatPositions = []
        
        for i in 0..<beats {
            let x = padding + beatWidth * CGFloat(i) + beatWidth / 2
            let color: UIColor = (i == currentBeat) ? StudioColors.purpleAccent : StudioColors.textSecondary
            
            // Draw beat circle
            let circlePath = UIBezierPath(
                arcCenter: CGPoint(x: x, y: centerY),
                radius: beatRadius,
                startAngle: 0,
                endAngle: CGFloat.pi * 2,
                clockwise: true
            )
            
            color.setFill()
            circlePath.fill()
            
            // Draw connecting line
            if i < beats - 1 {
                let nextX = padding + beatWidth * CGFloat(i + 1) + beatWidth / 2
                let linePath = UIBezierPath()
                linePath.move(to: CGPoint(x: x + beatRadius, y: centerY))
                linePath.addLine(to: CGPoint(x: nextX - beatRadius, y: centerY))
                
                UIColor(white: 1.0, alpha: 0.15).setStroke()
                linePath.lineWidth = 1
                linePath.stroke()
            }
            
            beatPositions.append(x)
        }
    }
}
