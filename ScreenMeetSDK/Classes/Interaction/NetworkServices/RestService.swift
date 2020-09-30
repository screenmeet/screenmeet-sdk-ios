//
//  RESTRequestService.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 13.07.2020.
//

import Foundation

enum NetworkServiceError: Error {
    case badUrl
    case clientError(message: String)
    case serverError(code: Int)
    case dataMissing
    case decodeError(message: String)
}

class RestService {
    
    private let session: URLSession
    
    init() {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = ScreenMeet.shared.config.httpTimeout
        sessionConfiguration.timeoutIntervalForResource = ScreenMeet.shared.config.httpTimeout * TimeInterval(ScreenMeet.shared.config.httpNumRetry)
        sessionConfiguration.waitsForConnectivity = true
        
        self.session = URLSession(configuration: sessionConfiguration)
    }
    
    enum Endpoint {
        case supportConnect(code: String)
        
        case supportStartStreem(url: URL, sessionId: String, authToken: String)
        
        fileprivate var path: String {
            switch self {
            case .supportConnect:
                return "support/connect"
            case .supportStartStreem:
                return "startSupportStream"
            }
        }
        
        fileprivate var url: URL? {
            switch self {
            case .supportConnect:
                return ScreenMeet.shared.config.endpoint.appendingPathComponent(path)
            case .supportStartStreem(let url, _, _):
                return url.appendingPathComponent(path)
            }
        }
        
        fileprivate var body: [String: Any] {
            switch self {
            case .supportConnect(let code):
                let bundle = Bundle(identifier: "org.cocoapods.ScreenMeetSDK")
                let sdkVersion = bundle?.infoDictionary?["CFBundleShortVersionString"] ?? ""
                let sdkBuild = bundle?.infoDictionary?["CFBundleVersion"] ?? ""
                let instalationUUID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? ""
                let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] ?? ""
                var dict: [String: Any] = [
                    "code": code,
                    
                    "sdkVersion": sdkVersion,
                    "sdkBuildNumber": sdkBuild,
                    
                    "clientAppOS": "iOS",
                    
                    "clientAppID": Bundle.main.bundleIdentifier ?? "unknown",
                    "clientAppVersion": "\(appVersion) (\(appBuild))",
                    "clientAppOSVersion": UIDevice.current.systemVersion,
                    "clientAppInstanceUID": instalationUUID
                ]
                
                if let organizationKey = ScreenMeet.shared.config.organizationKey {
                    dict["organisationKey"] = organizationKey
                }
                
                return dict
            case .supportStartStreem(_, let sessionId, let authToken):
                return ["session_code": sessionId, "host_auth_token": authToken]
            }
        }
    }
    
    func send<T: Decodable>(endpoint: Endpoint, completion: @escaping (Result<T, NetworkServiceError>) -> Void) {
        guard let url = endpoint.url else {
            completion(.failure(.badUrl))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let oKey = ScreenMeet.shared.config.organizationKey {
            request.setValue(oKey, forHTTPHeaderField: "mobile-api-key")
        } else {
            Logger.log.warning("Organization Key is not specified.")
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: endpoint.body, options: [])
            
            let task = session.uploadTask(with: request, from: jsonData) { data, response, error in
                if let error = error {
                    completion(.failure(.clientError(message: error.localizedDescription)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(.serverError(code: (response as? HTTPURLResponse)?.statusCode ?? -1)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.dataMissing))
                    return
                }
                
                do {
                    let decodedObject = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    completion(.failure(.decodeError(message: error.localizedDescription)))
                }
            }
            
            task.resume()
        } catch {
            completion(.failure(.decodeError(message: error.localizedDescription)))
        }
    }
}
