//
//  DDMathStringToken.m
//  DDMathParser
//
//  Created by Dave DeLong on 11/16/10.
//  Copyright 2010 Home. All rights reserved.
//

#import "DDMathParser.h"
#import "DDMathStringToken.h"
#import "_DDOperatorInfo.h"

@implementation DDMathStringToken
@synthesize token, tokenType, operatorType, operatorPrecedence, operatorArity;

#if !DD_HAS_ARC
- (void) dealloc {
    [token release];
    [numberValue release];
	[super dealloc];
}
#endif

- (id) initWithToken:(NSString *)t type:(DDTokenType)type {
	self = [super init];
	if (self) {
        if ([t isEqual:@"="]) { t = @"=="; }
        
        token = [t copy];
		tokenType = type;
		operatorType = DDOperatorInvalid;
		
		if (tokenType == DDTokenTypeOperator) {
            NSArray *operators = [_DDOperatorInfo allOperators];
            NSArray *matching = [operators filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"token = %@", t]];
            if ([matching count] == 0) {
                DD_RELEASE(self);
                return nil;
            } else if ([matching count] == 1) {
                operatorInfo = DD_RETAIN([matching objectAtIndex:0]);
            } else {
                ambiguous = YES;
            }
		}
	}
	return self;
}

+ (id) mathStringTokenWithToken:(NSString *)t type:(DDTokenType)type {
	return DD_AUTORELEASE([[self alloc] initWithToken:t type:type]);
}

- (NSNumber *) numberValue {
	if ([self tokenType] != DDTokenTypeNumber) { return nil; }
	if (numberValue == nil) {
        numberValue = [[NSDecimalNumber alloc] initWithString:[self token]];
        if (numberValue == nil) {
            NSLog(@"supposedly invalid number: %@", [self token]);
            numberValue = [[NSNumber alloc] initWithInt:0];
        }
    }
	return numberValue;
}

- (NSString *) description {
	NSMutableString * d = [NSMutableString string];
	if (tokenType == DDTokenTypeVariable) {
		[d appendString:@"$"];
	}
	[d appendString:token];
	return d;
}

- (NSString *)token {
    return token;
}

- (DDOperator)operatorType {
    if (ambiguous) { return DDOperatorInvalid; }
    return [operatorInfo operator];
}

- (NSInteger)operatorPrecedence {
    if (ambiguous) { return -1; }
    return [operatorInfo precedence];
}

- (DDOperatorArity)operatorArity {
    if (ambiguous) { return DDOperatorArityUnknown; }
    return [operatorInfo arity];
}

- (NSString *)operatorFunction {
    if (ambiguous) { return @""; }
    return [operatorInfo function];
}

- (void)resolveToOperator:(DDOperator)operator {
    DD_RELEASE(operatorInfo);
    operatorInfo = nil;
    
    NSArray *matching = [[_DDOperatorInfo allOperators] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"operator = %d", operator]];
    if ([matching count] != 1) { return; }
    
    ambiguous = NO;
    operatorInfo = DD_RETAIN([matching objectAtIndex:0]);
}

@end
