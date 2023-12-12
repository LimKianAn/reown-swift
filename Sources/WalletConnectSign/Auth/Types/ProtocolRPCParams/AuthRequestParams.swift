import Foundation

/// wc_sessionAuthenticate RPC method request param
struct AuthRequestParams: Codable, Equatable {
    let requester: Requester
    let payloadParams: Caip222Request
}

extension AuthRequestParams {
    struct Requester: Codable, Equatable {
        let publicKey: String
        let metadata: AppMetadata
    }
}
