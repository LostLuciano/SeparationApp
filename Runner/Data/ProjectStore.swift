import Foundation

/// JSON-based project persistence using FileManager.
public class ProjectStore {
    
    public static let shared = ProjectStore()
    
    private let projectDirectory: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    public init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        projectDirectory = paths[0].appendingPathComponent("MusicXNA_Projects")
        try? FileManager.default.createDirectory(at: projectDirectory, withIntermediateDirectories: true)
    }
    
    /// Save a project to JSON file
    public func save(_ project: StemProject) throws {
        let projectDir = projectDirectory.appendingPathComponent(project.id.uuidString)
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        
        let jsonURL = projectDir.appendingPathComponent("project.json")
        let data = try encoder.encode(project)
        try data.write(to: jsonURL)
        
        print("ProjectStore: Saved project \(project.name) to \(jsonURL.path)")
    }
    
    /// Load a project by ID
    public func load(_ id: UUID) throws -> StemProject {
        let projectDir = projectDirectory.appendingPathComponent(id.uuidString)
        let jsonURL = projectDir.appendingPathComponent("project.json")
        
        guard FileManager.default.fileExists(atPath: jsonURL.path) else {
            throw NSError(domain: "ProjectStore", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Project not found"])
        }
        
        let data = try Data(contentsOf: jsonURL)
        let project = try decoder.decode(StemProject.self, from: data)
        return project
    }
    
    /// List all projects
    public func listProjects() -> [StemProject] {
        var projects: [StemProject] = []
        
        if let contents = try? FileManager.default.contentsOfDirectory(
            at: projectDirectory, includingPropertiesForKeys: nil) {
            
            for projectDir in contents {
                let jsonURL = projectDir.appendingPathComponent("project.json")
                if FileManager.default.fileExists(atPath: jsonURL.path),
                   let data = try? Data(contentsOf: jsonURL),
                   let project = try? decoder.decode(StemProject.self, from: data) {
                    projects.append(project)
                }
            }
        }
        
        // Sort by creation date (newest first)
        projects.sort { $0.createdDate > $1.createdDate }
        return projects
    }
    
    /// Delete a project
    public func delete(_ id: UUID) throws {
        let projectDir = projectDirectory.appendingPathComponent(id.uuidString)
        try FileManager.default.removeItem(at: projectDir)
        print("ProjectStore: Deleted project \(id.uuidString)")
    }
    
    /// Get project count
    public func getProjectCount() -> Int {
        return listProjects().count
    }
}
