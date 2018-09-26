//
// Copyright (C) 2018-present Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

public typealias PersistenceBlockHandler = (Persistence) throws -> Void

public protocol Persistence {
    func insert<T>() -> T
    func fetch<T>(predicate: NSPredicate?, sortDescriptors: [SortDescriptor]?) -> [T]
    func delete<T>(_ entity: T) throws
    func fetchedResultsController<T>(predicate: NSPredicate, sortDescriptors: [SortDescriptor]?, sectionNameKeyPath: String?) -> FetchedResultsController<T>
    func addOrUpdate<T>(_ entity: T) throws
    func addOrUpdate<T>(_ entities: [T]) throws
    func perform(block: @escaping PersistenceBlockHandler) throws
    static func performBackgroundTask(block: @escaping PersistenceBlockHandler, completionHandler: EmptyHandler)

    func clearAllRecords() throws
    func refresh()
}

extension Persistence {
    public func fetch<T>() -> [T] {
        return self.fetch(predicate: nil, sortDescriptors: nil)
    }

    func fetch<T>(_ predicate: NSPredicate?) -> [T] {
        return self.fetch(predicate: predicate, sortDescriptors: nil)
    }

}

public struct SortDescriptor: Equatable {
    let key: String
    let ascending: Bool

    public init(key: String, ascending: Bool = true) {
        self.key = key
        self.ascending = ascending
    }
}

public enum PersistenceError: Error, CustomStringConvertible {
    case wrongEntityType
    case uninitializedPersistence
    case failureToInit
    case invalidSectionNameKeyPath

    public var description: String {
        switch self {
        case .wrongEntityType:
            return "Wrong entity type"
        case .uninitializedPersistence:
            return "Persistence uninitialized"
        case .failureToInit:
            return "Failed to init Persistence"
        case .invalidSectionNameKeyPath:
            return "Invalid section name key path"
        }
    }
}
