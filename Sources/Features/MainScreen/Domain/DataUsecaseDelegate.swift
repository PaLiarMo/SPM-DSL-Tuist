public protocol DataUsecaseDelegate {
    func onDataReceived(data: [DomainModel])
    func onDataFailed(error: Error)
}
