package com.trembit.util {

import com.trembit.vo.PropertyDescriptorVO;

import flash.system.System;
import flash.utils.Dictionary;
import flash.utils.getQualifiedClassName;
import flash.utils.getQualifiedSuperclassName;

import mx.utils.DescribeTypeCache;

public class ReflectionUtil {

	private static var classDescriptionDictionary:Dictionary = new Dictionary();

	public static function getProperties(classOfInterest:Class):Vector.<PropertyDescriptorVO> {
		var properties:Vector.<PropertyDescriptorVO> = new Vector.<PropertyDescriptorVO>();
		if (classOfInterest in classDescriptionDictionary) {
			properties = classDescriptionDictionary[classOfInterest];
		} else {
			var xmlDescriptionOfClass:XML = DescribeTypeCache.describeType(classOfInterest).typeDescription;
			var nonstaticPropertiesXML:XMLList = xmlDescriptionOfClass.factory.accessor;
			properties = new Vector.<PropertyDescriptorVO>();

			for each (var propertyXML:XML in nonstaticPropertiesXML) {
				var propertyName:String = propertyXML.@name;
				var remotePropertyName:String = propertyName;
				var propertyFullType:String = propertyXML.@type;
				var accessType:String = propertyXML.@access;
				var propertyType:String;

				if (propertyXML.metadata.(@name == "RemoteProperty").length()) {
					remotePropertyName = String(propertyXML.metadata.(@name == "RemoteProperty").arg.(@key == "").@value);
				}


				propertyType = getPropertyType(propertyFullType);

				if (accessType != "readonly") {
					properties.push(new PropertyDescriptorVO(propertyName, remotePropertyName,
							propertyType, propertyFullType, accessType));
				}
			}
			classDescriptionDictionary[classOfInterest] = properties;
			System.disposeXML(xmlDescriptionOfClass);
		}
		return properties;
	}

//    static protected var describeTypeDic:Dictionary = new Dictionary();
//
//    static public function describeType(o:*):XML {
//        var cacheKey:String;
//
//        if (o is String) {
//            cacheKey = o;
//        } else {
//            cacheKey = getQualifiedClassName(o);
//            //Need separate entries for describeType(Foo) and describeType(myFoo)
//            if (o is Class) {
//                cacheKey += "$";
//            }
//        }
//
//        if (cacheKey in describeTypeDic){
//            return describeTypeDic[cacheKey];
//        }
//
//        var xml:XML = flash.utils.describeType(o);
//        describeTypeDic[cacheKey] = xml
//        return xml;
//    }

	static protected var definitionByNameDict:Dictionary = new Dictionary();

	static public function getDefinitionByName(name:String):Object {
		var o:Object;
		if (name in definitionByNameDict)
			o = definitionByNameDict[name];
		else {
			o = flash.utils.getDefinitionByName(name);
			definitionByNameDict[name] = o;
		}
		return o;
	}

	public static function getPropertyType(propertyFullType:String):String {
		var parts:Array = propertyFullType.split("::");
		if (parts.length > 1) {
			parts.splice(0, 1);
			return parts.join("::");
		} else {
			return propertyFullType;
		}
	}

	public static function getClassByInstance(instance:Object):Class {
		if (!instance) {
			return null;
		}
		return Class(getDefinitionByName(getQualifiedClassName(instance).replace("::", ".")));
	}

	public static function getPublicBooleanProperties(type:*):Array {
		var description:XML = DescribeTypeCache.describeType(type).typeDescription;
		var accessor:XMLList = description..accessor.(@access == "readwrite" && @type == "Boolean").@name;
		var result:Array = [];
		for each (var node:XML in accessor) {
			result.push(node.toString());
		}
		return result;
	}

    public static function isPrimitiveType(type:String):Boolean {
        return ["String", "Number", "int", "Boolean", "uint", "Date"].indexOf(type) > -1;
    }

    public static function isVector(propertyType:String):Boolean {
        return propertyType.indexOf("Vector.<") == 0 || propertyType.indexOf("__AS3__.vec::Vector") == 0;
    }

    public static function isCustomVO(propertyType:String):Boolean {
        return propertyType.indexOf("VO") != -1
    }

    static public function isOverridden(source:*, methodName:String):Boolean {
        var parentTypeName:String = getQualifiedSuperclassName(source);
        if (parentTypeName == null) {
            return false;
        }

        var typeName:String = getQualifiedClassName(source);
        var typeDesc:XML = DescribeTypeCache.describeType(getDefinitionByName(typeName)).typeDescription;
        var methodList:XMLList = typeDesc.factory.method.(@name == methodName);

        if (methodList.length() > 0) {
            //Method exists
            var methodData:XML = methodList[0];
            if (methodData.@declaredBy == typeName) {
                //Method is declared in self
                var parentTypeDesc:XML = DescribeTypeCache.describeType(getDefinitionByName(parentTypeName)).typeDescription;
                var parentMethodList:XMLList = parentTypeDesc.factory.method.(@name == methodName);
                return parentMethodList.length() > 0;
            }
        }

        return false;
    }
}
}