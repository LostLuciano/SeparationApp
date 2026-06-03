import UIKit

protocol FloatingTabBarDelegate: AnyObject {
    func floatingTabBar(_ tabBar: FloatingTabBar, didSelectTab index: Int)
}

class FloatingTabBar: UIView {
    weak var delegate: FloatingTabBarDelegate?
    
    private var tabs: [String] = []
    private var selectedIndex: Int = 0
    private let stackView = UIStackView()
    private var tabButtons: [UIButton] = []
    
    init(tabs: [String]) {
        super.init(frame: .zero)
        self.tabs = tabs
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Container
        backgroundColor = StudioColors.glassMedium
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        layer.cornerRadius = StudioTheme.shared.cornerRadius24
        
        // Blur effect
        GlassEffect.applyGlassEffect(to: self)
        
        // Stack view
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = StudioTheme.shared.spacing8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: StudioTheme.shared.spacing8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: StudioTheme.shared.spacing12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -StudioTheme.shared.spacing12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -StudioTheme.shared.spacing8)
        ])
        
        // Create tab buttons
        for (index, tab) in tabs.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(tab, for: .normal)
            button.titleLabel?.font = Typography.labelMedium
            
            button.tag = index
            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            
            // Select first tab by default
            if index == 0 {
                button.setTitleColor(StudioColors.purpleAccent, for: .normal)
            } else {
                button.setTitleColor(StudioColors.textSecondary, for: .normal)
            }
            
            stackView.addArrangedSubview(button)
            tabButtons.append(button)
        }
    }
    
    @objc private func tabTapped(_ sender: UIButton) {
        selectTab(at: sender.tag)
    }
    
    private func selectTab(at index: Int) {
        selectedIndex = index
        
        for (i, button) in tabButtons.enumerated() {
            if i == index {
                button.setTitleColor(StudioColors.purpleAccent, for: .normal)
            } else {
                button.setTitleColor(StudioColors.textSecondary, for: .normal)
            }
        }
        
        delegate?.floatingTabBar(self, didSelectTab: index)
    }
}
