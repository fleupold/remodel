/**
 * Copyright (c) 2016-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import AlgebraicType = require('./algebraic-type');
import FunctionUtils = require('./function-utils');
import Maybe = require('./maybe');
import ObjC = require('./objc');
import StringUtils = require('./string-utils');

export function nameForInternalPropertyStoringSubtype():string {
  return 'subtype';
}

export function valueAccessorForInternalPropertyStoringSubtype():string {
  return '_' + nameForInternalPropertyStoringSubtype();
}

export function attributesFromSubtype(subtype:AlgebraicType.Subtype):AlgebraicType.SubtypeAttribute[] {
  return subtype.match(
    function(namedAttributeCollectionSubtype:AlgebraicType.NamedAttributeCollectionSubtype) {
      return namedAttributeCollectionSubtype.attributes;
    },
    function(attribute:AlgebraicType.SubtypeAttribute) {
      return [attribute];
    });
}

export function subtypeNameFromSubtype(subtype:AlgebraicType.Subtype):string {
  return subtype.match(
    function(namedAttributeCollectionSubtype:AlgebraicType.NamedAttributeCollectionSubtype) {
      return namedAttributeCollectionSubtype.name;
    },
    function(attribute:AlgebraicType.SubtypeAttribute) {
      return StringUtils.capitalize(attribute.name);
    });
}

function buildAttributesFromSubtype(soFar:AlgebraicType.SubtypeAttribute[], subtype:AlgebraicType.Subtype):AlgebraicType.SubtypeAttribute[] {
  return soFar.concat(attributesFromSubtype(subtype));
}

export function allAttributesFromSubtypes(subtypes:AlgebraicType.Subtype[]):AlgebraicType.SubtypeAttribute[] {
  return subtypes.reduce(buildAttributesFromSubtype, []);
}

export function mapAttributesWithSubtypeFromSubtypes<T>(subtypes:AlgebraicType.Subtype[], mapper:(subtype: AlgebraicType.Subtype, attribute: AlgebraicType.SubtypeAttribute) => T):T[] {
  return subtypes.reduce(function(soFar:T[], subtype:AlgebraicType.Subtype) {
    return soFar.concat(attributesFromSubtype(subtype).map(FunctionUtils.pApplyf2(subtype, mapper)));
  }, []);
}

function typeForUnderlyingType(underlyingType:string):ObjC.Type {
  return {
    name: underlyingType,
    reference: underlyingType === 'NSObject' ? 'NSObject*' : underlyingType
  };
}

export function computeTypeOfAttribute(attribute:AlgebraicType.SubtypeAttribute):ObjC.Type {
  return Maybe.match(typeForUnderlyingType, function():ObjC.Type {
    return {
      name: attribute.type.name,
      reference: attribute.type.reference
    };
  }, attribute.type.underlyingType);
}

export function nameOfInternalPropertyForAttribute(subtype:AlgebraicType.Subtype, attribute:AlgebraicType.SubtypeAttribute):string {
  return subtype.match(
    function(namedAttributeCollectionSubtype:AlgebraicType.NamedAttributeCollectionSubtype) {
      return StringUtils.lowercased(namedAttributeCollectionSubtype.name) + '_' + StringUtils.lowercased(attribute.name);
    },
    function(attribute:AlgebraicType.SubtypeAttribute) {
      return StringUtils.lowercased(attribute.name);
    });
}

export function valueAccessorForInternalPropertyForAttribute(subtype:AlgebraicType.Subtype, attribute:AlgebraicType.SubtypeAttribute):string {
  return '_' + nameOfInternalPropertyForAttribute(subtype, attribute);
}

export function ConstantNameForSubtype(subtype:AlgebraicType.Subtype):string {
  return 'kSubtype' + subtypeNameFromSubtype(subtype);
}

export function ConstantValueForSubtype(subtype:AlgebraicType.Subtype):string {
  return '@"SUBTYPE_' + subtypeNameFromSubtype(subtype) + '"';
}

export function codeForSubtypeBranchesWithSubtypeMapper(algebraicType:AlgebraicType.Type, subtypeValueAccessor:string, subtypeMapper:(algebraicType:AlgebraicType.Type, subtype:AlgebraicType.Subtype) => string[], soFar:string[], subtype:AlgebraicType.Subtype):string[] {
  const internalCode:string[] = subtypeMapper(algebraicType, subtype);
  const code:string[] = [(soFar.length ? 'else if([' : 'if([') + subtypeValueAccessor + ' isEqualToString:' + ConstantNameForSubtype(subtype) + ']) {'].concat(internalCode.map(StringUtils.indent(2))).concat(['}']);
  return soFar.concat(code);
}

function p3Applyf5<T,U,V,W,X,Y>(firstVal:T, secondVal:U, thirdValue:V, f:(a:T, b:U, c:V, d:W, e:X) => Y):(d:W, e:X) => Y {
  return function(d:W, e:X):Y {
    return f(firstVal, secondVal, thirdValue, d, e);
  };
}

export function codeForBranchesgOnSubtypeWithSubtypeMapper(algebraicType:AlgebraicType.Type, subtypeValueAccessor:string, subtypeMapper:(algebraicType:AlgebraicType.Type, subtype:AlgebraicType.Subtype) => string[]):string[] {
  const subtypeBranches:string[] = algebraicType.subtypes.reduce(p3Applyf5(algebraicType, subtypeValueAccessor, subtypeMapper, codeForSubtypeBranchesWithSubtypeMapper), []);
  const failureCase:string[] = ['else {', StringUtils.indent(2)('@throw([NSException exceptionWithName:@"InvalidSubtypeException" reason:@"nil or unknown subtype provided" userInfo:@{@"subtype": _subtype}]);'), '}'];
  return subtypeBranches.concat(failureCase);
}

function blockTypeNameForSubtype(algebraicType:AlgebraicType.Type, subtype:AlgebraicType.Subtype):string {
  return algebraicType.name + StringUtils.capitalize(subtypeNameFromSubtype(subtype)) + 'MatchHandler';
}

function blockTypeParameterForSubtypeAttribute(attribute:AlgebraicType.SubtypeAttribute):ObjC.BlockTypeParameter {
  return {
    name: attribute.name,
    type: {
      name: attribute.type.name,
      reference: attribute.type.reference
    }
  };
}

export function blockTypeForSubtype(algebraicType:AlgebraicType.Type, subtype:AlgebraicType.Subtype):ObjC.BlockType {
  return {
    comments: [],
    name: blockTypeNameForSubtype(algebraicType, subtype),
    parameters: attributesFromSubtype(subtype).map(blockTypeParameterForSubtypeAttribute),
    returnType: Maybe.Nothing<ObjC.Type>(),
    isPublic: true
  };
}

export function blockParameterNameForMatchMethodFromSubtype(subtype:AlgebraicType.Subtype):string {
  return StringUtils.lowercased(subtypeNameFromSubtype(subtype) + 'MatchHandler');
}

export function keywordForMatchMethodFromSubtype(algebraicType:AlgebraicType.Type, subtype:AlgebraicType.Subtype):ObjC.Keyword {
  const blockType:ObjC.BlockType = blockTypeForSubtype(algebraicType, subtype);
  return {
    name: StringUtils.lowercased(subtypeNameFromSubtype(subtype)),
    argument: Maybe.Just({
      name: blockParameterNameForMatchMethodFromSubtype(subtype),
      modifiers: [],
      type: {
        name: blockType.name,
        reference: blockType.name
      }
    })
  };
}

export function firstKeywordForMatchMethodFromSubtype(algebraicType:AlgebraicType.Type, subtype:AlgebraicType.Subtype):ObjC.Keyword {
  const normalKeyword:ObjC.Keyword = keywordForMatchMethodFromSubtype(algebraicType, subtype);
  return {
    argument: normalKeyword.argument,
    name: 'match' + StringUtils.capitalize(normalKeyword.name)
  };
}
