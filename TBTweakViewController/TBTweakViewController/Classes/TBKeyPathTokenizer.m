//
//  TBKeyPathTokenizer.m
//  TBTweakViewController
//
//  Created by Tanner on 3/22/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "TBKeyPathTokenizer.h"

#define TBCountOfStringOccurence(target, str) ([target componentsSeparatedByString:str].count - 1)


@implementation TBKeyPathTokenizer

static NSCharacterSet *firstAllowed = nil;
static NSCharacterSet *allowed = nil;
static NSCharacterSet *methodAllowed = nil;
+ (void)initialize {
    if (self == [self class]) {
        NSString *_firstAllowed  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$";
        NSString *_bothAllowed   = [_firstAllowed stringByAppendingString:@"1234567890"];
        NSString *_methodAllowed = [_bothAllowed stringByAppendingString:@":"];
        firstAllowed  = [NSCharacterSet characterSetWithCharactersInString:_firstAllowed];
        allowed       = [NSCharacterSet characterSetWithCharactersInString:_bothAllowed];
        methodAllowed = [NSCharacterSet characterSetWithCharactersInString:_methodAllowed];
    }
}

+ (NSUInteger)tokenCountOfString:(NSString *)userInput {
    NSUInteger escapedCount = TBCountOfStringOccurence(userInput, @"\\.");
    NSUInteger tokenCount  = TBCountOfStringOccurence(userInput, @".") - escapedCount + 1;

    // Case where string ends in . but no token follows
    if ([userInput hasSuffix:@"."] && ![userInput hasSuffix:@"\\."]) {
        tokenCount--;
    }

    return tokenCount;
}

+ (TBKeyPath *)tokenizeString:(NSString *)userInput {
    if (!userInput.length) {
        return nil;
    }

    NSUInteger tokens = [self tokenCountOfString:userInput];
    if (tokens == 0) {
        return nil;
    }

    if ([userInput containsString:@"**"]) {
        @throw NSInternalInconsistencyException;
    }

    NSNumber *instance = nil;
    NSScanner *scanner = [NSScanner scannerWithString:userInput];
    TBToken *bundle = [self scanToken:scanner allowed:allowed];
    TBToken *cls = [self scanToken:scanner allowed:allowed];

    return [TBKeyPath bundle:bundle
                       class:cls
                      method:[self scanMethodToken:scanner instance:&instance]
                  isInstance:instance];
}

+ (TBToken *)scanToken:(NSScanner *)scanner allowed:(NSCharacterSet *)allowedChars {
    if (scanner.isAtEnd) {
        return nil;
    }

    TBWildcardOptions options = TBWildcardOptionsNone;
    NSMutableString *token = [NSMutableString string];

    // Token cannot start with '.'
    if ([scanner scanString:@"." intoString:nil]) {
        @throw NSInternalInconsistencyException;
    }

    if ([scanner scanString:@"*." intoString:nil]) {
        options = TBWildcardOptionsAny;
        return [TBToken string:nil options:TBWildcardOptionsAny];
    } else if ([scanner scanString:@"*" intoString:nil]) {
        if (scanner.isAtEnd) {
            options = TBWildcardOptionsAny;
            return [TBToken string:nil options:TBWildcardOptionsAny];
        }
        
        options |= TBWildcardOptionsPrefix;
    }

    NSString *tmp = nil;
    BOOL stop = NO, didScanDelimiter = NO, didScanFirstAllowed = NO;
    NSCharacterSet *disallowed = allowedChars.invertedSet;
    while (!stop && ![scanner scanString:@"." intoString:&tmp] && !scanner.isAtEnd) {
        // Scan word chars
        if (!didScanFirstAllowed) {
            if ([scanner scanCharactersFromSet:firstAllowed intoString:&tmp]) {
                [token appendString:tmp];
                didScanFirstAllowed = YES;
            } else {
                // Token starts with a number or something else not allowed
                @throw NSInternalInconsistencyException;
            }
        } else if ([scanner scanCharactersFromSet:allowedChars intoString:&tmp]) {
            [token appendString:tmp];
        }
        // Scan '\.'
        else if ([scanner scanString:@"\\" intoString:nil]) {
            if ([scanner scanString:@"." intoString:nil]) {
                [token appendString:@"."];
            } else {
                // Invalid token, forward slash not followed by period
                @throw NSInternalInconsistencyException;
            }
        }
        // Scan '*.'
        else if ([scanner scanString:@"*." intoString:nil]) {
            options |= TBWildcardOptionsSuffix;
            stop = YES;
            didScanDelimiter = YES;
        }
        // Scan '*' not followed by .
        else if ([scanner scanString:@"*" intoString:nil]) {
            if (!scanner.isAtEnd) {
                // Invalid token, wildcard in middle of token
                @throw NSInternalInconsistencyException;
            }
        } else if ([scanner scanCharactersFromSet:disallowed intoString:nil]) {
            // Invalid token, invalid characters
            @throw NSInternalInconsistencyException;
        }
    }

    if ([tmp isEqualToString:@"."]) {
        didScanDelimiter = YES;
    }

    if (!didScanDelimiter) {
        options |= TBWildcardOptionsSuffix;
    }

    return [TBToken string:token options:options];
}

+ (TBToken *)scanMethodToken:(NSScanner *)scanner instance:(NSNumber **)instance {
    if (scanner.isAtEnd) {
        return nil;
    }
    
    if ([scanner scanString:@"-" intoString:nil]) {
        *instance = @YES;
    } else if ([scanner scanString:@"+" intoString:nil]) {
        *instance = @NO;
    } else {
        if ([scanner scanString:@"*" intoString:nil]) {
            // Just checking... It has to start with one of these three!
            scanner.scanLocation--;
        } else {
            @throw NSInternalInconsistencyException;
        }
    }

    // -*foo not allowed
    if (*instance && [scanner scanString:@"*" intoString:nil]) {
        @throw NSInternalInconsistencyException;
    }
    
    return [self scanToken:scanner allowed:methodAllowed];
}

@end