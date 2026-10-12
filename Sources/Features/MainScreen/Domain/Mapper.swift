import MainScreen_Data

extension DataModel {
    func toDomain() -> DomainModel {
        .init(id: id, title: title, body: body)
    }
}
