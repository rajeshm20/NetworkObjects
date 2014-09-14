//
//  CoreDataJSONCompatibility.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/14/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

internal extension NSManagedObject {
    
    // MARK: - Convenience Methods
    
    func JSONCompatibleValueForAttribute(attributeName: String) -> AnyObject? {
        
        let attributeValue: AnyObject? = self.valueForKey(attributeName)
        
        return self.JSONCompatibleValueForAttributeValue(attributeValue!, forAttribute: attributeName)
    }
    
    func setJSONCompatibleValue(JSONCompatibleValue: AnyObject?, forAttribute attributeName: String) {
        
        let attributeValue: AnyObject? = self.attributeValueForJSONCompatibleValue(JSONCompatibleValue!, forAttribute: attributeName)
        
        self.setValue(attributeValue, forKey: attributeName)
    }
    
    func attributeValueForJSONCompatibleValue(JSONCompatibleValue: AnyObject, forAttribute attributeName: String) -> AnyObject? {
        
        return self.entity.attributeValueForJSONCompatibleValue(JSONCompatibleValue, forAttribute: attributeName)
    }
    
    func JSONCompatibleValueForAttributeValue(attributeValue: AnyObject?, forAttribute attributeName: String) -> AnyObject? {
        
        return self.entity.JSONCompatibleValueForAttributeValue(attributeValue, forAttribute: attributeName)
    }
    
    // MARK: - Validate
    
    func isValidConvertedValue(convertedValue: AnyObject, forAttribute attributeName: String) -> Bool {
        
        let attributeDescription = self.entity.attributesByName[attributeName] as? NSAttributeDescription
        
        if attributeDescription == nil {
            
            return false
        }
        
        switch attributeDescription!.attributeType {
            
        case NSAttributeType.UndefinedAttributeType, NSAttributeType.ObjectIDAttributeType:
            return false
            
        case NSAttributeType.Integer16AttributeType, NSAttributeType.Integer32AttributeType, NSAttributeType.Integer64AttributeType, NSAttributeType.DecimalAttributeType, NSAttributeType.DoubleAttributeType, NSAttributeType.FloatAttributeType, NSAttributeType.BooleanAttributeType :
            
            // try to cast as number
            let number = convertedValue as? NSNumber
            return (number != nil)
            
        case NSAttributeType.StringAttributeType:
            
            let string = convertedValue as? String
            return (string != nil)
            
        case NSAttributeType.DateAttributeType:
            
            let date = convertedValue as? NSDate
            return (date != nil)
            
        case NSAttributeType.BinaryDataAttributeType:
            
            let data = convertedValue as? NSData
            return (data != nil)
            
        // transformable value type
        case NSAttributeType.TransformableAttributeType:
            
            // get transformer
            let valueTransformerName = attributeDescription?.valueTransformerName
            
            // default transformer: NSKeyedUnarchiveFromDataTransformerName in reverse
            if valueTransformerName == nil {
                
                let transformer = NSValueTransformer(forName: NSKeyedUnarchiveFromDataTransformerName)
                
                // anything that conforms to NSCoding
                return (convertedValue as? NSCoding != nil)
            }
            
            // custom transformer
            let transformer = NSValueTransformer(forName: valueTransformerName!)
            
            // must convert to NSData
            let data = transformer.transformedValue(convertedValue) as? NSData
            
            return (data != nil)
            
        }
        
        return false
    }
}

internal extension NSEntityDescription {
    
    // MARK: - Conversion Methods
    
    func JSONCompatibleValueForAttributeValue(attributeValue: AnyObject?, forAttribute attributeName: String) -> AnyObject? {
        
        let attributeDescription = self.attributesByName[attributeName] as? NSAttributeDescription
        
        if attributeDescription == nil {
            
            return nil
        }
        
        // give value based on attribute type...
        
        // if NSNull then just return NSNull     
        // nil attributes can be represented in JSON by NSNull
        if attributeValue as? NSNull != nil || attributeValue == nil {
            
            return NSNull()
        }
        
        let attributeClassName = attributeDescription!.attributeValueClassName
        
        switch attributeClassName {
            
            // strings and numbers are standard json data types
            case "NSString", "NSNumber":
                return attributeValue
            
            case "NSDate":
                let date = attributeValue as NSDate
                return date.ISO8601String()
            
            case "NSData":
                let data = attributeValue as NSData
                return data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
        }
        
        // transformable value type
        if attributeDescription?.attributeType == NSAttributeType.TransformableAttributeType {
            
            // get transformer
            let valueTransformerName = attributeDescription?.valueTransformerName
            
            // default transformer: NSKeyedUnarchiveFromDataTransformerName in reverse
            if valueTransformerName == nil {
                
                let transformer = NSValueTransformer(forName: NSKeyedUnarchiveFromDataTransformerName)
                
                // anything that conforms
                return (convertedValue as? )
            }
            
            // custom transformer
            let transformer = NSValueTransformer(forName: valueTransformerName!)
        }
        
        return nil
    }
    
    func attributeValueForJSONCompatibleValue(JSONCompatibleValue: AnyObject, forAttribute attributeName: String) -> AnyObject? {
        
        
        // transformable value type
        if attributeType == NSAttributeType.TransformableAttributeType {
            
            // get transformer
            let valueTransformerName = attributeDescription?.valueTransformerName
            
            // default transformer: NSKeyedUnarchiveFromDataTransformerName in reverse
            if valueTransformerName == nil {
                
                let transformer = NSValueTransformer(forName: NSKeyedUnarchiveFromDataTransformerName)
                
                // anything that conforms
                return (convertedValue as? )
            }
            
            // custom transformer
            let transformer = NSValueTransformer(forName: valueTransformerName!)
            
            
        }
    }
}

// MARK: - Extensions

private extension NSDate {
    
    class func ISO8601DateFormatter() -> NSDateFormatter {
        
        struct Static {
            static var onceToken : dispatch_once_t = 0
            static var instance : NSDateFormatter? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = NSDateFormatter()
            Static.instance?.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        }
        return Static.instance!
    }
    
    class func dateWithISO8601String(ISO8601String: String) -> NSDate? {
        
        return self.ISO8601DateFormatter().dateFromString(ISO8601String)
    }
    
    func ISO8601String() -> String {
        
        return NSDate.ISO8601DateFormatter().stringFromDate(self)
    }
}

