Feature: Outputting Objects With Generic Types

  @announce
  Scenario: Generating Value Objects with generics
    Given a file named "project/values/RMPage.value" with:
      """
      RMPage {
        NSDictionary<NSString *, NSNumber *> *namesToAges
      }
      """
    And a file named "project/.valueObjectConfig" with:
      """
      { }
      """
    When I run `../../bin/generate project`
    Then the file "project/values/RMPage.h" should contain:
      """
      #import <Foundation/Foundation.h>

      @interface RMPage : NSObject <NSCopying>

      @property (nonatomic, readonly, copy) NSDictionary<NSString *, NSNumber *> *namesToAges;

      - (instancetype)initWithNamesToAges:(NSDictionary<NSString *, NSNumber *> *)namesToAges;

      @end

      """
   And the file "project/values/RMPage.m" should contain:
      """
      #import "RMPage.h"

      @implementation RMPage

      - (instancetype)initWithNamesToAges:(NSDictionary<NSString *, NSNumber *> *)namesToAges
      {
        if ((self = [super init])) {
          _namesToAges = [namesToAges copy];
        }

        return self;
      }

      - (id)copyWithZone:(NSZone *)zone
      {
        return self;
      }

      - (NSString *)description
      {
        return [NSString stringWithFormat:@"%@ - \n\t namesToAges: %@; \n", [super description], _namesToAges];
      }

      - (NSUInteger)hash
      {
        NSUInteger subhashes[] = {[_namesToAges hash]};
        NSUInteger result = subhashes[0];
        for (int ii = 1; ii < 1; ++ii) {
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

      - (BOOL)isEqual:(RMPage *)object
      {
        if (self == object) {
          return YES;
        } else if (self == nil || object == nil || ![object isKindOfClass:[self class]]) {
          return NO;
        }
        return
          (_namesToAges == object->_namesToAges ? YES : [_namesToAges isEqual:object->_namesToAges]);
      }

      @end

      """
  @announce
  Scenario: Generating an algebraic type with generics
    Given a file named "project/values/SimpleADT.adtValue" with:
      """
      SimpleADT {
        FirstSubtype {
          NSDictionary<NSString *, NSNumber *> *namesToAges
        }
        %singleAttributeSubtype attributeType="NSDictionary<NSString *, NSString *> *"
        someAttributeSubtype
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

      typedef void (^SimpleADTFirstSubtypeMatchHandler)(NSDictionary<NSString *, NSNumber *> *namesToAges);
      typedef void (^SimpleADTSomeAttributeSubtypeMatchHandler)(NSDictionary<NSString *, NSString *> *someAttributeSubtype);

      @interface SimpleADT : NSObject <NSCopying>

      + (instancetype)firstSubtypeWithNamesToAges:(NSDictionary<NSString *, NSNumber *> *)namesToAges;

      + (instancetype)someAttributeSubtype:(NSDictionary<NSString *, NSString *> *)someAttributeSubtype;

      - (void)matchFirstSubtype:(SimpleADTFirstSubtypeMatchHandler)firstSubtypeMatchHandler someAttributeSubtype:(SimpleADTSomeAttributeSubtypeMatchHandler)someAttributeSubtypeMatchHandler;

      @end

      """
   And the file "project/values/SimpleADT.m" should contain:
      """
      #import "SimpleADT.h"

      @implementation SimpleADT
      {
        NSString *_subtype;
        NSDictionary<NSString *, NSNumber *> *_firstSubtype_namesToAges;
        NSDictionary<NSString *, NSString *> *_someAttributeSubtype;
      }

      + (instancetype)firstSubtypeWithNamesToAges:(NSDictionary<NSString *, NSNumber *> *)namesToAges
      {
        SimpleADT *object = [[SimpleADT alloc] init];
        object->_subtype = kSubtypeFirstSubtype;
        object->_firstSubtype_namesToAges = namesToAges;
        return object;
      }

      + (instancetype)someAttributeSubtype:(NSDictionary<NSString *, NSString *> *)someAttributeSubtype
      {
        SimpleADT *object = [[SimpleADT alloc] init];
        object->_subtype = kSubtypeSomeAttributeSubtype;
        object->_someAttributeSubtype = someAttributeSubtype;
        return object;
      }

      - (id)copyWithZone:(NSZone *)zone
      {
        return self;
      }

      - (NSString *)description
      {
        if([_subtype isEqualToString:kSubtypeFirstSubtype]) {
          return [NSString stringWithFormat:@"%@ - FirstSubtype \n\t namesToAges: %@; \n", [super description], _firstSubtype_namesToAges];
        }
        else if([_subtype isEqualToString:kSubtypeSomeAttributeSubtype]) {
          return [NSString stringWithFormat:@"%@ - \n\t someAttributeSubtype: %@; \n", [super description], _someAttributeSubtype];
        }
        else {
          @throw([NSException exceptionWithName:@"InvalidSubtypeException" reason:@"nil or unknown subtype provided" userInfo:@{@"subtype": _subtype}]);
        }
      }

      - (NSUInteger)hash
      {
        NSUInteger subhashes[] = {[_subtype hash], [_firstSubtype_namesToAges hash], [_someAttributeSubtype hash]};
        NSUInteger result = subhashes[0];
        for (int ii = 1; ii < 3; ++ii) {
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
          (_subtype == object->_subtype ? YES : [_subtype isEqual:object->_subtype]) &&
          (_firstSubtype_namesToAges == object->_firstSubtype_namesToAges ? YES : [_firstSubtype_namesToAges isEqual:object->_firstSubtype_namesToAges]) &&
          (_someAttributeSubtype == object->_someAttributeSubtype ? YES : [_someAttributeSubtype isEqual:object->_someAttributeSubtype]);
      }

      - (void)matchFirstSubtype:(SimpleADTFirstSubtypeMatchHandler)firstSubtypeMatchHandler someAttributeSubtype:(SimpleADTSomeAttributeSubtypeMatchHandler)someAttributeSubtypeMatchHandler
      {
        if([_subtype isEqualToString:kSubtypeFirstSubtype]) {
          firstSubtypeMatchHandler(_firstSubtype_namesToAges);
        }
        else if([_subtype isEqualToString:kSubtypeSomeAttributeSubtype]) {
          someAttributeSubtypeMatchHandler(_someAttributeSubtype);
        }
        else {
          @throw([NSException exceptionWithName:@"InvalidSubtypeException" reason:@"nil or unknown subtype provided" userInfo:@{@"subtype": _subtype}]);
        }
      }

      @end

      """
