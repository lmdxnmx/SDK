//
//  PmBundle.swift
//  IoMT.SDK
//
//  Created by Никита on 28.08.2024.
//

import Foundation
public class PmBundle:DataHandler{
    var bundle:[PmObj]? = nil;
    init(bundle: [PmObj]? = nil, code:Int) {
        super.init(code: code)
        self.bundle = bundle
    }
    override init(code: Int) {
        super.init(code: code)
        bundle = nil;
    }
}
