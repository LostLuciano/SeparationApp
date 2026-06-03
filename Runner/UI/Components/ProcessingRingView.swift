import UIKit

class ProcessingRingView: UIView {
    private let shapeLayer = CAShapeLayer()
    private let backgroundLayer = CAShapeLayer()
    
    var progress: CGFloat = 0 {
        didSet {
            updateProgress()
        }
    }
    
    var progressText: String = "" {
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
        backgroundColor = .clear
        
        // Background circle
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
            radius: min(bounds.width, bounds.height) / 2 - 10,
            startAngle: -CGFloat.pi / 2,
            endAngle: 3 * CGFloat.pi / 2,
            clockwise: true
        )
        
        backgroundLayer.path = circlePath.cgPath
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.strokeColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        backgroundLayer.lineWidth = 8
        layer.addSublayer(backgroundLayer)
        
        // Progress circle
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = StudioColors.purpleAccent.cgColor
        shapeLayer.lineWidth = 8
        shapeLayer.lineCap = .round
        shapeLayer.strokeEnd = 0
        layer.addSublayer(shapeLayer)
    }
    
    private func updateProgress() {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.toValue = progress
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        shapeLayer.add(animation, forKey: "progress")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Draw percentage text
        let textRect = CGRect(x: 0, y: rect.midY - 30, width: rect.width, height: 60)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Typography.displaySmall,
            .foregroundColor: StudioColors.purpleAccent,
            .paragraphStyle: paragraphStyle
        ]
        
        progressText.draw(in: textRect, withAttributes: attributes)
    }
}
