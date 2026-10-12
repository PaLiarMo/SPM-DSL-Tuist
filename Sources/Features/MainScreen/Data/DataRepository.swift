import Foundation
import Networking

public protocol DataRepository {
    func fetchData(completion: @escaping ([DataModel]?, Error?) -> Void)
}

class DataRepositoryImpl: DataRepository {
    func fetchData(completion: @escaping ([DataModel]?, Error?) -> Void) {
        Networking.fetchDataList<DataModel> { data, error in
            completion(data, error)
        }
    }
}

public func makeDataRepository() -> DataRepository {
    return DataRepositoryImpl()
}
