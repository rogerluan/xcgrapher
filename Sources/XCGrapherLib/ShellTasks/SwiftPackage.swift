
import Foundation

struct SwiftPackage {

    let clone: FileManager.Path

    func targets() throws -> [PackageDescription.Target] {
        let json = try execute()
        let jsonData = json.data(using: .utf8)!
        let description = try JSONDecoder().decode(PackageDescription.self, from: jsonData)
        return description.targets
    }

}

extension SwiftPackage: ShellTask {

    var stringRepresentation: String {
        "swift package --package-path \"\(clone)\" describe --type json"
    }

    var commandNotFoundInstructions: String {
        "Missing command 'swift'"
    }

}

struct PackageDescription: Decodable {

    enum CodingKeys: String, CodingKey {
        case name, path, targets
    }

    struct Target: Decodable {
        let name: String
        let path: String
        let sources: [String]
        let type: String
    }

    let name: String
    let path: String
    let targets: [Target]

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        path = try values.decode(String.self, forKey: .path)

        // Map all target-related paths to be absolute.
        // We can't use Array.map here because Swift freaks out about self being used in a closure...
        var _targets: [Target] = []
        for _target in try values.decode([Target].self, forKey: .targets) {
            var _sources: [String] = []

            for _source in _target.sources {
                _sources.append(path.appendingPathComponent(_target.path).appendingPathComponent(_source))
            }

            let mappedTarget = Target(
                name: _target.name,
                path: path.appendingPathComponent(_target.path),
                sources: _sources,
                type: _target.type
            )

            _targets.append(mappedTarget)
        }

        targets = _targets
    }

}
