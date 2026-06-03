import UIKit

class LibraryViewController: UIViewController {
    private let tableView = UITableView()
    private let filterSegment = StudioSegmentedControl(items: ["Semua", "Lagu", "Sesi", "Impor"])
    private let projects: [StemProject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadProjects()
    }
    
    private func setupUI() {
        // Background
        let bgView = LiquidBackgroundView()
        view.insertSubview(bgView, at: 0)
        bgView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: view.topAnchor),
            bgView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let safeArea = view.safeAreaLayoutGuide
        let padding = StudioTheme.shared.spacing16
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Studio Library"
        titleLabel.font = Typography.headingLarge
        titleLabel.textColor = StudioColors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Filter
        filterSegment.selectedSegmentIndex = 0
        filterSegment.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterSegment)
        
        // Table view
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(LibraryProjectCell.self, forCellReuseIdentifier: "ProjectCell")
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: padding),
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: padding),
            
            filterSegment.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: padding),
            filterSegment.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -padding),
            filterSegment.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: padding),
            filterSegment.heightAnchor.constraint(equalToConstant: 32),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: filterSegment.bottomAnchor, constant: padding),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadProjects() {
        // TODO: Load from ProjectStore
        Logger.shared.info("Loading projects from store")
    }
}

// MARK: - UITableViewDataSource
extension LibraryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count > 0 ? projects.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if projects.isEmpty {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            let emptyView = EmptyStateView(title: "Tidak ada proyek", message: "Buat proyek baru untuk memulai", icon: "🎵")
            cell.contentView.addSubview(emptyView)
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                emptyView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                emptyView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                emptyView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                emptyView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                emptyView.heightAnchor.constraint(equalToConstant: 300)
            ])
            
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath) as! LibraryProjectCell
        cell.configure(with: projects[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension LibraryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return projects.isEmpty ? 300 : 100
    }
}

// MARK: - Library Project Cell
class LibraryProjectCell: UITableViewCell {
    private let cardView = GlassCardView()
    private let titleLabel = UILabel()
    private let infoLabel = UILabel()
    private let playButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        titleLabel.font = Typography.labelMedium
        titleLabel.textColor = StudioColors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
        
        infoLabel.font = Typography.labelSmall
        infoLabel.textColor = StudioColors.textSecondary
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(infoLabel)
        
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = StudioColors.purpleAccent
        playButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(playButton)
        
        let padding = StudioTheme.shared.spacing12
        
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: padding),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: padding),
            
            infoLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: padding),
            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            playButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -padding),
            playButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    func configure(with project: StemProject) {
        titleLabel.text = project.title
        infoLabel.text = "\(project.duration.formatted())  · \(project.format)  · \(project.bpm ?? 0) BPM"
    }
}

// Helper extension
extension Double {
    func formatted() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
