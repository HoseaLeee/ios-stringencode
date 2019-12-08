//
//  StringEncode.h
//  GoogleGeocode
//
//  Created by Hosea H C Lee on 2019/12/8.
//  Copyright © 2019 HSBC Bank. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
 
@interface StringEncode : NSObject

- (id)initWithString:(NSString *)string;

+ (id)base64WebsafeStringEncoding;

- (NSData *)decode:(NSString *)inString error:(NSError **)error;

- (NSString *)encode:(NSData *)inData error:(NSError **)error;

@end

FOUNDATION_EXPORT NSString *const StringEncodeErrorDomain;
FOUNDATION_EXPORT NSString *const StringEncodeBadCharacterIndexKey;  // NSNumber

typedef NS_ENUM(NSInteger, StringEncodeError) {
  // Unable to convert a buffer to NSASCIIStringEncoding.
  StringEncodeErrorUnableToConverToAscii = 1024,
  // Unable to convert a buffer to NSUTF8StringEncoding.
  StringEncodeErrorUnableToConverToUTF8,
  // Encountered a bad character.
  // StringEncodeBadCharacterIndexKey will have the index of the character.
  StringEncodeErrorUnknownCharacter,
  // The data had a padding character in the middle of the data. Padding characters
  // can only be at the end.
  StringEncodeErrorExpectedPadding,
  // There is unexpected data at the end of the data that could not be decoded.
  StringEncodeErrorIncompleteTrailingData,
};

NS_ASSUME_NONNULL_END
