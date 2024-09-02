//
//  ConciergeCallback.swift
//  IoMT.SDK
//
//  Created by Никита on 02.09.2024.
//

import Foundation
public protocol ConciergeCallback: AnyObject {
    func onSuccessDiary(id: UUID, status:Int);
    func onErrorDiary(id: UUID, status: Int);
}
