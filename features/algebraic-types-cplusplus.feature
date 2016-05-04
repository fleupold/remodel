Feature: Outputting ObjC++ Algebraic Types

  @announce
  Scenario: Generating an algebraic type outputs a .mm implementation
    Given a file named "project/values/SimpleADT.adtValue" with:
      """
      SimpleADT includes(RenderCPlusPlusFile) {
        FirstSubtype {
          NSString *firstValue
          NSUInteger secondValue
        }
        SomeRandomSubtype
        SecondSubtype {
          BOOL something
        }
      }
      """
    And a file named "project/.algebraicTypeConfig" with:
      """
      {
        "defaultExcludes": [
          "RMCoding"
         ]
      }
      """
    When I run `../../bin/generate project`
    Then the file "project/values/SimpleADT.h" should contain:
      """
      #import <Foundation/Foundation.h>

      typedef void (^SimpleADTFirstSubtypeMatchHandler)(NSString *firstValue, NSUInteger secondValue);
      typedef void (^SimpleADTSomeRandomSubtypeMatchHandler)();
      typedef void (^SimpleADTSecondSubtypeMatchHandler)(BOOL something);

      @interface SimpleADT : NSObject <NSCopying>

      + (instancetype)firstSubtypeWithFirstValue:(NSString *)firstValue secondValue:(NSUInteger)secondValue;

      + (instancetype)secondSubtypeWithSomething:(BOOL)something;

      + (instancetype)someRandomSubtype;

      - (void)matchFirstSubtype:(SimpleADTFirstSubtypeMatchHandler)firstSubtypeMatchHandler someRandomSubtype:(SimpleADTSomeRandomSubtypeMatchHandler)someRandomSubtypeMatchHandler secondSubtype:(SimpleADTSecondSubtypeMatchHandler)secondSubtypeMatchHandler;

      @end

      """
   And the file "project/values/SimpleADT.mm" should contain:
      """
      #import "SimpleADT.h"

      @implementation SimpleADT
      {
        NSString *_subtype;
        NSString *_firstSubtype_firstValue;
        NSUInteger _firstSubtype_secondValue;
        BOOL _secondSubtype_something;
      }

      + (instancetype)firstSubtypeWithFirstValue:(NSString *)firstValue secondValue:(NSUInteger)secondValue
      {
        SimpleADT *object = [[SimpleADT alloc] init];
        object->_subtype = kSubtypeFirstSubtype;
        object->_firstSubtype_firstValue = firstValue;
        object->_firstSubtype_secondValue = secondValue;
        return object;
      }

      + (instancetype)secondSubtypeWithSomething:(BOOL)something
      {
        SimpleADT *object = [[SimpleADT alloc] init];
        object->_subtype = kSubtypeSecondSubtype;
        object->_secondSubtype_something = something;
        return object;
      }

      + (instancetype)someRandomSubtype
      {
        SimpleADT *object = [[SimpleADT alloc] init];
        object->_subtype = kSubtypeSomeRandomSubtype;
        return object;
      }

      - (id)copyWithZone:(NSZone *)zone
      {
        return self;
      }

      - (NSString *)description
      {
        if([_subtype isEqualToString:kSubtypeFirstSubtype]) {
          return [NSString stringWithFormat:@"%@ - FirstSubtype \n\t firstValue: %@; \n\t secondValue: %tu; \n", [super description], _firstSubtype_firstValue, _firstSubtype_secondValue];
        }
        else if([_subtype isEqualToString:kSubtypeSomeRandomSubtype]) {
          return [NSString stringWithFormat:@"%@ - SomeRandomSubtype \n", [super description]];
        }
        else if([_subtype isEqualToString:kSubtypeSecondSubtype]) {
          return [NSString stringWithFormat:@"%@ - SecondSubtype \n\t something: %@; \n", [super description], _secondSubtype_something ? @"YES" : @"NO"];
        }
        else {
          @throw([NSException exceptionWithName:@"InvalidSubtypeException" reason:@"nil or unknown subtype provided" userInfo:@{@"subtype": _subtype}]);
        }
      }

      - (NSUInteger)hash
      {
        NSUInteger subhashes[] = {[_subtype hash], [_firstSubtype_firstValue hash], _firstSubtype_secondValue, (NSUInteger)_secondSubtype_something};
        NSUInteger result = subhashes[0];
        for (int ii = 1; ii < 4; ++ii) {
          unsigned long long base = (((unsigned long long)result) << 32 | subhashes[ii]);
          base = (~base) + (base << 18);
          base ^= (base >> 31);
          base *=  21;
          base ^= (base >> 11);
          base += (base << 6);
          base ^= (base >> 22);
          result = base;
        }
        return result;
      }

      - (BOOL)isEqual:(SimpleADT *)object
      {
        if (self == object) {
          return YES;
        } else if (self == nil || object == nil || ![object isKindOfClass:[self class]]) {
          return NO;
        }
        return
          _firstSubtype_secondValue == object->_firstSubtype_secondValue &&
          _secondSubtype_something == object->_secondSubtype_something &&
          (_subtype == object->_subtype ? YES : [_subtype isEqual:object->_subtype]) &&
          (_firstSubtype_firstValue == object->_firstSubtype_firstValue ? YES : [_firstSubtype_firstValue isEqual:object->_firstSubtype_firstValue]);
      }

      - (void)matchFirstSubtype:(SimpleADTFirstSubtypeMatchHandler)firstSubtypeMatchHandler someRandomSubtype:(SimpleADTSomeRandomSubtypeMatchHandler)someRandomSubtypeMatchHandler secondSubtype:(SimpleADTSecondSubtypeMatchHandler)secondSubtypeMatchHandler
      {
        if([_subtype isEqualToString:kSubtypeFirstSubtype]) {
          firstSubtypeMatchHandler(_firstSubtype_firstValue, _firstSubtype_secondValue);
        }
        else if([_subtype isEqualToString:kSubtypeSomeRandomSubtype]) {
          someRandomSubtypeMatchHandler();
        }
        else if([_subtype isEqualToString:kSubtypeSecondSubtype]) {
          secondSubtypeMatchHandler(_secondSubtype_something);
        }
        else {
          @throw([NSException exceptionWithName:@"InvalidSubtypeException" reason:@"nil or unknown subtype provided" userInfo:@{@"subtype": _subtype}]);
        }
      }

      @end

      """
