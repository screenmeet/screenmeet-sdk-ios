//
//  AppStreamWebView.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 26.11.2020.
//

import Foundation
import WebKit

class ConfidentialRectModel {
    
    var id: UUID = UUID()
    
    private var rects: [CGRect] = []
    
    var rect: CGRect? {
        guard rects.count > 0 else { return nil }
        
        let minX = rects.map { $0.origin.x }.min()!
        let minY = rects.map { $0.origin.y }.min()!
        let maxX = rects.map { $0.origin.x + $0.width }.max()!
        let maxY = rects.map { $0.origin.y + $0.height }.max()!
        
        let width = (maxX - minX)
        let height = (maxY - minY)
        let x = minX
        let y = minY
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    init(id: UUID) {
        self.id = id
    }
    
    func append(_ rect: CGRect) {
        if rects.count > 3 {
            rects.removeFirst()
        }
        
        rects.append(rect)
    }
}

class AppStreamWebView: NSObject {
    
    var id = UUID()
    
    weak var value: WKWebView?
    
    var confidentialRects = [ConfidentialRectModel]()

    init(_ value: WKWebView?) {
        self.value = value
    }
    
    func getRects(_ rects: @escaping ([CGRect]) -> Void) {
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.main.async { [unowned self] in
            self.getRects(completion: { confidentialRects in
                rects(confidentialRects.compactMap { $0.rect })

                group.leave()
            })
        }

        group.wait()
    }
    
    func getRects(completion: @escaping ([ConfidentialRectModel]) -> Void) {
        guard let webView = value else {
            completion([])
            return
        }
        
        webView.evaluateJavaScript(AppStreamWebView.js) { [weak self] (data, error) in
            if let error = error {
                Logger.log.error("ScreenMeetSDK: Evaluate Java Script Error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let data = data as? [Any],
                  let serializedData = try? JSONSerialization.data(withJSONObject: data),
                  let nodes = try? JSONDecoder().decode([ConfidentialWebNodeModel].self, from: serializedData) else {
                completion([])
                return
            }
            
            
            let contentView = webView.scrollView.subviews.first(where: { $0.frame != .zero })
            let webViewRect = webView.globalRect ?? .zero
            let contentRect = contentView?.globalRect ?? .zero
            let contentTransformScale = contentView?.globalTransform?.m11
            let zoomScale = contentTransformScale ?? webView.scrollView.zoomScale
            
            var confidentialRects = [ConfidentialRectModel]()
            
            nodes.forEach { (node) in
                guard node.width > 0, node.height > 0 else { return }
                
                let x = (node.left * zoomScale) + contentRect.origin.x
                let y = (node.top * zoomScale) + contentRect.origin.y
                let width = node.width * zoomScale
                let height = node.height * zoomScale
                
                let rect = CGRect(x: x, y: y, width: width, height: height).intersection(webViewRect)
                
                if let confidentialRect = self?.confidentialRects.first(where: { $0.id == node.id }) {
                    confidentialRect.append(rect)
                    confidentialRects.append(confidentialRect)
                } else {
                    let confidentialRect = ConfidentialRectModel(id: node.id)
                    confidentialRect.append(rect)
                    confidentialRects.append(confidentialRect)
                }
            }
            
            self?.confidentialRects = confidentialRects
            completion(self?.confidentialRects ?? [])
        }
    }
    
    static let selectors: [String] = ["input[type='password']", "[data-cb-mask]"]
    
    static let js: String = """
    function uuidv4() {
      return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
        (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
      );
    }

    function queryNodes() {
        const nodes = [];

        const passwordNodes = Array.from(document.querySelectorAll("\(selectors.joined(separator: ","))"));
        passwordNodes.forEach(function(node) {
            if (node.dataset.smuuid == null) {
                node.dataset.smuuid = uuidv4()
            }

            var bodyRect = document.body.getBoundingClientRect(),
                elemRect = node.getBoundingClientRect(),
                offsetTop = elemRect.top - bodyRect.top,
                offsetLeft = elemRect.left - bodyRect.left;
            nodes.push({
                "left": offsetLeft,
                "top": offsetTop,
                "width": elemRect.width,
                "height": elemRect.height,
                "id": node.dataset.smuuid
            });
        });

        return nodes;
    } queryNodes();
    """
}
