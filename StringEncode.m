//
//  StringEncode.m
//  GoogleGeocode
//
//  Created by Hosea H C Lee on 2019/12/8.
//  Copyright © 2019 HSBC Bank. All rights reserved.
//

#import "StringEncode.h"
#include <AvailabilityMacros.h>
#include <TargetConditionals.h>

#ifdef __OBJC__
#include <Foundation/NSObjCRuntime.h>
#endif  // __OBJC__

#if TARGET_OS_IPHONE
#include <Availability.h>
#endif  // TARGET_OS_IPHONE


#if !defined(StringEncode_INLINE)
  #if (defined (__GNUC__) && (__GNUC__ == 4)) || defined (__clang__)
    #define StringEncode_INLINE static __inline__ __attribute__((always_inline))
  #else
    #define StringEncode_INLINE static __inline__
  #endif
#endif

NSString *const StringEncodeErrorDomain = @"com.hsnc.StringEncodeErrorDomain";
NSString *const StringEncodeBadCharacterIndexKey = @"StringEncodeBadCharacterIndexKey";

enum {
  kUnknownChar = -1,
  kPaddingChar = -2,
  kIgnoreChar = -3
};

@interface StringEncode() {
 @private
  NSData *charMapData_;
  char *charMap_;
  int reverseCharMap_[128];
  int shift_;
  int mask_;
  BOOL doPad_;
  char paddingChar_;
  int padLen_;
}

@end

@implementation StringEncode


+ (id)stringEncodingWithString:(NSString *)string {
  return [[self alloc] initWithString:string];
}

- (id)initWithString:(NSString *)string {
  if ((self = [super init])) {
    charMapData_ = [string dataUsingEncoding:NSASCIIStringEncoding];
    if (!charMapData_) {
      return nil;
    }
    charMap_ = (char *)[charMapData_ bytes];
    NSUInteger length = [charMapData_ length];
    if (length < 2 || length > 128 || length & (length - 1)) {
      return nil;
    }

    memset(reverseCharMap_, kUnknownChar, sizeof(reverseCharMap_));
    for (unsigned int i = 0; i < length; i++) {
      if (reverseCharMap_[(int)charMap_[i]] != kUnknownChar) {
        return nil;
      }
      reverseCharMap_[(int)charMap_[i]] = i;
    }

    for (NSUInteger i = 1; i < length; i <<= 1)
      shift_++;
    mask_ = (1 << shift_) - 1;
    padLen_ = lcm(8, shift_) / shift_;
  }
  return self;
}

StringEncode_INLINE int lcm(int a, int b) {
  for (int aa = a, bb = b;;) {
    if (aa == bb)
      return aa;
    else if (aa < bb)
      aa += a;
    else
      bb += b;
  }
}

+ (id)base64WebsafeStringEncoding {
  StringEncode *ret = [self stringEncodingWithString:
      @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"];
  [ret setPaddingChar:'='];
  [ret setDoPad:YES];
  return ret;
}


- (NSData *)decode:(NSString *)inString error:(NSError **)error {
  char *inBuf = (char *)[inString cStringUsingEncoding:NSASCIIStringEncoding];
  if (!inBuf) {
    if (error) {
      *error = [NSError errorWithDomain:StringEncodeErrorDomain
                                   code:StringEncodeErrorUnableToConverToAscii
                               userInfo:nil];

    }
    return nil;
  }
  NSUInteger inLen = strlen(inBuf);

  NSUInteger outLen = inLen * shift_ / 8;
  NSMutableData *outData = [NSMutableData dataWithLength:outLen];
  unsigned char *outBuf = (unsigned char *)[outData mutableBytes];
  NSUInteger outPos = 0;

  unsigned int buffer = 0;
  int bitsLeft = 0;
  BOOL expectPad = NO;
  for (NSUInteger i = 0; i < inLen; i++) {
    int val = reverseCharMap_[(int)inBuf[i]];
    switch (val) {
      case kIgnoreChar:
        break;
      case kPaddingChar:
        expectPad = YES;
        break;
      case kUnknownChar: {
        if (error) {
          NSDictionary *userInfo =
              [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:i]
                                          forKey:StringEncodeBadCharacterIndexKey];
          *error = [NSError errorWithDomain:StringEncodeErrorDomain
                                       code:StringEncodeErrorUnknownCharacter
                                   userInfo:userInfo];
        }
        return nil;
      }
      default:
        if (expectPad) {
          if (error) {
            NSDictionary *userInfo =
                [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:i]
                                            forKey:StringEncodeBadCharacterIndexKey];
            *error = [NSError errorWithDomain:StringEncodeErrorDomain
                                         code:StringEncodeErrorExpectedPadding
                                     userInfo:userInfo];
          }
          return nil;
        }
        buffer <<= shift_;
        buffer |= val & mask_;
        bitsLeft += shift_;
        if (bitsLeft >= 8) {
          outBuf[outPos++] = (unsigned char)(buffer >> (bitsLeft - 8));
          bitsLeft -= 8;
        }
        break;
    }
  }

  if (bitsLeft && buffer & ((1 << bitsLeft) - 1)) {
    if (error) {
      *error = [NSError errorWithDomain:StringEncodeErrorDomain
                                   code:StringEncodeErrorIncompleteTrailingData
                               userInfo:nil];

    }
    return nil;
  }

  // Shorten buffer if needed due to padding chars
  [outData setLength:outPos];

  return outData;
}


- (NSString *)encode:(NSData *)inData error:(NSError **)error {
  NSUInteger inLen = [inData length];
  if (inLen <= 0) {
    return @"";
  }
  unsigned char *inBuf = (unsigned char *)[inData bytes];
  NSUInteger inPos = 0;

  NSUInteger outLen = (inLen * 8 + shift_ - 1) / shift_;
  if (doPad_) {
    outLen = ((outLen + padLen_ - 1) / padLen_) * padLen_;
  }
  NSMutableData *outData = [NSMutableData dataWithLength:outLen];
  unsigned char *outBuf = (unsigned char *)[outData mutableBytes];
  NSUInteger outPos = 0;

  unsigned int buffer = inBuf[inPos++];
  int bitsLeft = 8;
  while (bitsLeft > 0 || inPos < inLen) {
    if (bitsLeft < shift_) {
      if (inPos < inLen) {
        buffer <<= 8;
        buffer |= (inBuf[inPos++] & 0xff);
        bitsLeft += 8;
      } else {
        int pad = shift_ - bitsLeft;
        buffer <<= pad;
        bitsLeft += pad;
      }
    }
    int idx = (buffer >> (bitsLeft - shift_)) & mask_;
    bitsLeft -= shift_;
    outBuf[outPos++] = charMap_[idx];
  }

  if (doPad_) {
    while (outPos < outLen)
      outBuf[outPos++] = paddingChar_;
  }

  [outData setLength:outPos];

  NSString *value = [[NSString alloc] initWithData:outData
                                           encoding:NSASCIIStringEncoding];
  if (!value) {
    if (error) {
      *error = [NSError errorWithDomain:StringEncodeErrorDomain
                                   code:StringEncodeErrorUnableToConverToAscii
                               userInfo:nil];

    }
  }
  return value;
}





- (BOOL)doPad {
  return doPad_;
}

- (void)setDoPad:(BOOL)doPad {
  doPad_ = doPad;
}

- (void)setPaddingChar:(char)c {
  paddingChar_ = c;
  reverseCharMap_[(int)c] = kPaddingChar;
}
@end
