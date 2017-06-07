//: Playground - noun: a place where people can play

import UIKit

enum Attribute {
    case readonly
    case copy
    case retain
    case nonatomic
    case dynamic
    case weak
    case garbage
    case old
    case customGetter
    case customSetter
    case type(Reference)

    init?(string: String) {
        guard let first = string.characters.first else { return nil }
        switch first {
        case Attribute.readonly.value: self = .readonly
        case Attribute.copy.value: self = .copy
        case Attribute.retain.value: self = .retain
        case Attribute.nonatomic.value: self = .nonatomic
        case Attribute.dynamic.value: self = .dynamic
        case Attribute.weak.value: self = .weak
        case Attribute.garbage.value: self = .garbage
        case Attribute.old.value: self = .old
        case Attribute.customGetter.value: self = .customGetter
        case Attribute.customSetter.value: self = .customSetter
        case Attribute.type(.standard(.int)).value:
        guard let split = string.components(separatedBy: "\"").first, let type = Reference(string: split) else { return nil }
            self = .type(type)
        default: return nil
        }
    }
    
    var value: Character {
        switch self {
        case .readonly: return "R"
        case .copy: return "C"
        case .retain: return "&"
        case .nonatomic: return "N"
        case .dynamic: return "D"
        case .weak: return "W"
        case .garbage: return "P"
        case .old: return "t"
        case .customGetter: return "G"
        case .customSetter: return "S"
        case .type: return "T"
        }
    }
    
    var canSet: Bool {
        switch self {
        case .readonly: return false
        case .type(let item): return item.isObject
        default: return true
        }
    }
}

enum Reference {
    
    case standard(Classification)
    case pointer(Classification)
    
    init?(string: String) {
        guard let type = Classification(string: string) else { return nil }
        if string.characters.contains(Reference.pointer(.int).value) {
            self = .pointer(type)
        }else {
            self = .standard(type)
        }
    }
    
    var isObject: Bool {
        var val: Classification
        switch self {
        case .pointer(let item): val = item
        case .standard(let item): val = item
        }
        
        switch val {
        case .function, .void, .selector: return false
        default: return true
        }
    }
    
    var value: Character {
        switch self {
        case .pointer: return "^"
        case .standard: return Character("")
        }
    }
}

enum Classification: Character {
    case char = "c"
    case double = "d"
    case float = "f"
    case int = "q"
    case unsignedint = "Q"
    case long = "l"
    case short = "s"
    case id = "@"
    case function = "?"
    case structor = "}"
    case void = "v"
    case selector = ":"
    
    init?(string: String) {
        guard let last = string.characters.last else { return nil }
       self.init(rawValue: last)
    }
}

protocol Updateable { }

protocol Clonable: Updateable {
    init()
}

extension NSObject: Clonable { }

extension Updateable where Self: NSObject {
    @discardableResult
    func update(completion: (Self) -> Void) -> Self {
        completion(self)
        return self
    }
}

extension Clonable where Self: NSObject {
    var clone: Self {
        let clone = Self.init()
        for property in properties.updatable {
            guard case let name = property.name, let v = value(forKey: name) else { continue }
            clone.setValue(v, forKey: name)
        }
        return clone
    }
}

extension objc_property_t {
    var array: [String] {
        guard let att = property_getAttributes(self), let array = String(utf8String: att)?.components(separatedBy: ",") else { return [] }
        return array
    }
    var attributes: [Attribute] {
        guard let att = property_getAttributes(self), let array = String(utf8String: att)?.components(separatedBy: ",") else { return [] }
        return array.flatMap{Attribute(string: $0)}
    }
    
    var name: String {
        guard let name = property_getName(self), let string = String(utf8String: name) else { return "" }
        return string
    }
}

extension UnsafeMutablePointer {
    func properties(length: Int) -> [OpaquePointer] {
        return UnsafeBufferPointer(start: self, count: length).flatMap { $0 as? OpaquePointer}
    }
}

extension NSObject {
    
    static var properties: [objc_property_t] {
        guard let classForKeyedArchiver = classForKeyedArchiver() else { return [] }
        var count: UInt32 = 0
        var properties = class_copyPropertyList(classForKeyedArchiver, &count).properties(length: Int(count))
        if let parent = class_getSuperclass(classForKeyedArchiver) as? NSObject.Type {
            properties.append(contentsOf: parent.properties)
        }
        return properties
    }
    
    var properties: [objc_property_t] {
        return type(of: self).properties
    }
    
}

extension Array where Element == objc_property_t {
    var updatable: [objc_property_t] {
        return filter{$0.attributes.filter({!$0.canSet}).count == 0}
    }
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class Person: NSObject {
    var firstName: String = ""
    var lastName: String = ""
    var age: Int = 0
}

let person =  Person()
person.update {
    $0.firstName = "Paul"
    $0.lastName = "Napier"
    $0.age = 21 // Again...
}

let person2 = person.clone.update {
    $0.age = 100
}

print(person.firstName)
print(person.lastName)
print(person.age)

print(person2.firstName)
print(person2.lastName)
print(person2.age)



