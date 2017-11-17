//
//  ColorUtils.swift
//  CatLike iOS
//
//  Created by Arthur  on 11/16/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation

#if os(OSX)
    import Cocoa
    typealias OurColor = NSColor
    typealias OurImage = NSImage
    
    
#else
    import UIKit
    typealias OurColor = UIColor
    typealias OurImage = UIImage
#endif

class ColorUtils {
    static let shared = ColorUtils()
    
    
    func blend(_ c1:OurColor, _ c2: OurColor, ratio:CGFloat)->OurColor{
        
        #if os(OSX)
            return c1.blended(withFraction: ratio, of: c2) ?? c2
        #else
            
            let l1 = ratio
            let l2 = 1 - ratio
            
            var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            
            c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            
            return UIColor(red: l1*r1 + l2*r2, green: l1*g1 + l2*g2, blue: l1*b1 + l2*b2, alpha: l1*a1 + l2*a2)
            
        #endif
    }
    
    func r(_ r:CGFloat, g:CGFloat, b:CGFloat) -> OurColor{
        
        #if os(OSX)
         return NSColor(calibratedRed: r, green: g, blue: b, alpha: 1)
        
        #else
        
            return UIColor(displayP3Red: r, green: g, blue: b, alpha: 1)
        #endif
        
    }
    
    func seaColor()->OurColor{
        return r(0.64, g:0.8, b:1)
    }
    
    func alpha(_ c:OurColor, rate:CGFloat) -> OurColor {
        
       
        
        #if os(OSX)
            
            let ciColor:CIColor = CIColor(color: c)!
            
            return NSColor(calibratedRed:ciColor.red, green: ciColor.green, blue: ciColor.blue, alpha: rate)
        #else

    
            var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            c.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            
            return UIColor(displayP3Red: r1, green: g1, blue: b1, alpha: rate)
        #endif
        
    }
    
    
}


