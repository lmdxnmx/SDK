//
//  DataHandler.swift
//  IoMT.SDK
//
//  Created by Никита on 27.08.2024.
//

import Foundation
public class DataHandler {
  public  var responseCode:Int = 0;
    init(code:Int) {
        responseCode = code;
    }
   public func isSuccess() -> Bool{
        if(responseCode == 0){
            return true;
        }else{
            return false;
        }
    }
}
