import Vapor

enum ResponseOrRedirect<T: AsyncResponseEncodable>: AsyncResponseEncodable {
    func encodeResponse(for request: Request) async throws -> Response {
        switch self {
        case .response(let response, let status, let headers):
            if let status {
                if let headers {
                    return try await response.encodeResponse(status: status, headers: headers, for: request)
                } else {
                    return try await response.encodeResponse(status: status, for: request)
                }
            } else {
                assert(headers == nil)
                return try await response.encodeResponse(for: request)
            }
        case .redirect(let redirectionPath): return redirectionPath.encodeResponse(for: request)
        }
    }
    
    case response(T, status: HTTPStatus? = nil, headers: HTTPHeaders? = nil)
    case redirect(RedirectionPaths)
}
