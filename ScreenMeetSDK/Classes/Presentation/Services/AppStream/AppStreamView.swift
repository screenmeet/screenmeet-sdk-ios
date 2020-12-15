//
//  AppStreamView.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 26.11.2020.
//

import Foundation

class AppStreamView {
    
    var id = UUID()
    
    weak var value: UIView?
    
    private var rects = [CGRect]()

    init(_ value: UIView?) {
        self.value = value
    }
    
    func getRect() -> CGRect? {
        guard let rect = value?.globalRect else { return nil }
        
        if rects.count > 3 {
            rects.removeFirst()
        }
        
        rects.append(rect)

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
}
