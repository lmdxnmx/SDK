//
//  Entity+CoreDataProperties.swift
//  IoMT.SDK
//
//  Created by Никита on 08.02.2024.
//
//

import Foundation
import CoreData


extension Entity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entity> {
        return NSFetchRequest<Entity>(entityName: "Entity")
    }

    @NSManaged public var title: UUID?
    @NSManaged public var body: String?

}
