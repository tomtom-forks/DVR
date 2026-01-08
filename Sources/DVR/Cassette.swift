import Foundation

struct Cassette {

    // MARK: - Properties

    let name: String
    let interactions: [Interaction]

    // MARK: - Initializers

    init(name: String, interactions: [Interaction]) {
        self.name = name
        self.interactions = interactions
    }

    // MARK: - Functions

    func interactionForRequest(
        _ request: URLRequest, headersToCheck: [String] = [], parametersToIgnore: [String] = []
    ) -> Interaction? {
        var match: Interaction?
        for interaction in interactions {
            let interactionRequest = interaction.request

            let hasEqualMethod = interactionRequest.httpMethod == request.httpMethod
            let hasEqualParameters = interactionRequest.hasEqualParameters(
                request, ignoreParameters: parametersToIgnore)
            let hasEqualBody = interactionRequest.hasHTTPBodyEqualToThatOfRequest(request)

            if hasEqualMethod && hasEqualParameters && hasEqualBody {
                // Overwrite the current match if the required headers are equal.
                if match == nil
                    || interactionRequest.hasHeadersEqualToThatOfRequest(
                        request, headersToCheck: headersToCheck)
                {
                    match = interaction
                }
            } else {
                // Printing only base URL and path to avoid exposing sensitive data
                let baseURL = request.url.map { "\($0.scheme ?? "")://\($0.host ?? "")\($0.path)" } ?? "unknown"
                print("[DVR] Request \(baseURL) did not match interaction:")
                print("[DVR] - Method equality: \(hasEqualMethod)")
                print("[DVR] - Parameters equality: \(hasEqualParameters)")
                if !hasEqualParameters {
                    let paramDiff = interactionRequest.parameterDifference(from: request, ignoreParameters: parametersToIgnore)
                    print("[DVR]   Parameter differences: \(paramDiff)")
                }
                print("[DVR] - Body equality: \(hasEqualBody)")
            }
        }
        return match
    }
}

extension Cassette {
    var dictionary: [String: Any] {
        return [
            "name": name as Any,
            "interactions": interactions.map { $0.dictionary },
        ]
    }

    init?(dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String else { return nil }

        self.name = name

        if let array = dictionary["interactions"] as? [[String: Any]] {
            interactions = array.compactMap { Interaction(dictionary: $0) }
        } else {
            interactions = []
        }
    }
}

extension URLRequest {
    func hasHTTPBodyEqualToThatOfRequest(_ request: URLRequest) -> Bool {
        guard let body1 = self.httpBody,
            let body2 = request.httpBody,
            let encoded1 = Interaction.encodeBody(body1, headers: self.allHTTPHeaderFields),
            let encoded2 = Interaction.encodeBody(body2, headers: request.allHTTPHeaderFields)
        else {
            return self.httpBody == request.httpBody
        }

        return encoded1.isEqual(encoded2)
    }

    func hasHeadersEqualToThatOfRequest(_ request: URLRequest, headersToCheck: [String]) -> Bool {
        let request1Headers = allHTTPHeaderFields ?? [:]
        let request2Headers = request.allHTTPHeaderFields ?? [:]
        for header in headersToCheck {
            if request1Headers[header] != request2Headers[header] {
                return false
            }
        }
        return true
    }

    func hasEqualParameters(_ request: URLRequest, ignoreParameters: [String] = []) -> Bool {
        if url == request.url { return true }

        let request1 = createRequest(withoutKeys: ignoreParameters)
        let request2 = request.createRequest(withoutKeys: ignoreParameters)

        return request1.url == request2.url
    }

    func createRequest(withoutKeys: [String]) -> URLRequest {
        var newRequest = self
        guard let oldURL = url, withoutKeys != [] else { return newRequest }

        if var urlComponents = URLComponents(url: oldURL, resolvingAgainstBaseURL: false) {
            urlComponents.queryItems = urlComponents.queryItems?.filter {
                !withoutKeys.contains($0.name)
            }
            newRequest.url = urlComponents.url
        }

        return newRequest
    }

    func parameterDifference(from request: URLRequest, ignoreParameters: [String] = []) -> String {
        guard let url1 = self.url, let url2 = request.url else {
            return "unable to compare (missing URLs)"
        }

        let components1 = URLComponents(url: url1, resolvingAgainstBaseURL: false)
        let components2 = URLComponents(url: url2, resolvingAgainstBaseURL: false)

        let params1 = components1?.queryItems?.filter { !ignoreParameters.contains($0.name) } ?? []
        let params2 = components2?.queryItems?.filter { !ignoreParameters.contains($0.name) } ?? []

        let keys1 = Set(params1.map { $0.name })
        let keys2 = Set(params2.map { $0.name })

        let onlyInRequest1 = keys1.subtracting(keys2)
        let onlyInRequest2 = keys2.subtracting(keys1)
        let commonKeys = keys1.intersection(keys2)

        var differentValues: Set<String> = []
        for key in commonKeys {
            let value1 = params1.first(where: { $0.name == key })?.value
            let value2 = params2.first(where: { $0.name == key })?.value
            if value1 != value2 {
                differentValues.insert(key)
            }
        }

        var parts: [String] = []
        if !onlyInRequest1.isEmpty {
            parts.append("only in interaction: \(onlyInRequest1.sorted().joined(separator: ", "))")
        }
        if !onlyInRequest2.isEmpty {
            parts.append("only in request: \(onlyInRequest2.sorted().joined(separator: ", "))")
        }
        if !differentValues.isEmpty {
            parts.append("different values: \(differentValues.sorted().joined(separator: ", "))")
        }

        return parts.isEmpty ? "none (other URL components differ)" : parts.joined(separator: "; ")
    }
}
