//
//  KYUnlockCodeManager.m
//  KYUnlockCodeManager
//
//  Created by Kjuly on 3/3/13.
//  Copyright (c) 2013 Kjuly. All rights reserved.
//

#import "KYUnlockCodeManager.h"

#define kKYUnlockCodeManagerDefaultCodeOrder_  @"12345"
#define kKYUnlockCodeManagerDefaultCodeFormat_ @"%@%@%@%@%@"

@interface KYUnlockCodeManager () {
 @private
}

// Default methods for delegate
// Default for delegate: |-encryptedCodeFromCode:|
- (NSString *)_encryptedCodeFromCode:(NSString *)code;
// Default for delegate: |-resizedCodeFromCode:|
- (NSString *)_resizedCodeFromCode:(NSString *)code;

// Return the code format
- (NSString *)_codeFormat;
// Return appropriately factor's encrypted code for the type offered
- (NSString *)_factorForType:(KYUnlockCodeManagerFactorType)type;

// Return the unlock code
- (NSString *)_unlockCode;

@end


@implementation KYUnlockCodeManager

@synthesize dataSource, delegate;

- (void)dealloc {
  self.dataSource = nil;
  self.delegate   = nil;
  [super dealloc];
}

#pragma mark - Default Methods for Delegate

// Default for delegate method: |-encryptedCodeFromCode:|
- (NSString *)_encryptedCodeFromCode:(NSString *)code {
  return code;
}

// Default for delegate method: |-resizedCodeFromCode:|
- (NSString *)_resizedCodeFromCode:(NSString *)code {
  return code;
}

#pragma mark - Private Methods

// Default for delegate: |-codeFormat|
- (NSString *)_codeFormat {
  NSString * codeOrder =
    ([self.dataSource respondsToSelector:@selector(codeOrder)]
      ? [self.dataSource codeOrder] : kKYUnlockCodeManagerDefaultCodeOrder_);
  
  // Return default code format if the code order is equal to default
  if ([codeOrder isEqualToString:kKYUnlockCodeManagerDefaultCodeOrder_])
    return kKYUnlockCodeManagerDefaultCodeFormat_;
  
  // Returned format e.g.: @"%5$@%4$@%3$@%2$@%1$@"
  NSMutableString * codeFormat = [NSMutableString stringWithString:@""];
  for (int i = 0; i < codeOrder.length; ++i)
    [codeFormat appendString:[NSMutableString stringWithFormat:@"%%%c$@",
                              [codeOrder characterAtIndex:i]]];
  return codeFormat;
}

// Return appropriately factor's encrypted code for the type offered.
- (NSString *)_factorForType:(KYUnlockCodeManagerFactorType)type {
  // Get the appropriately selector for the |type| that offered
  SEL selector = nil;
  switch (type) {
    case kKYUnlockCodeManagerFactorTypeOfDeviceUID:
      selector = @selector(deviceUID);
      break;
      
    case kKYUnlockCodeManagerFactorTypeOfUserAccount:
      selector = @selector(userAccount);
      break;
      
    case kKYUnlockCodeManagerFactorTypeOfUserAccountCreatedDate:
      selector = @selector(userAccountCreatedDate);
      break;
      
    case kKYUnlockCodeManagerFactorTypeOfAppVersionSha:
      selector = @selector(appVersionSha);
      break;
      
    case kKYUnlockCodeManagerFactorTypeOfAppBuiltDate:
      selector = @selector(appBuiltDate);
      break;
      
    // Return empty code when no type or other type offered
    case kKYUnlockCodeManagerFactorTypeNone:
    default:
      return @"";
      break;
  }
  
  // If the |selector| is not implemented for data source, return empty code.
  if (! [self.dataSource respondsToSelector:selector])
    return @"";
  
  // Return the encrypted code for the factor.
  // If |-encryptedCodeFromCode:| delegate is implemented,
  //   use it to do encryption job;
  // Otherwise, use default encrypt method: |_encryptedCodeFromCode:|.
  if ([self.delegate respondsToSelector:@selector(encryptedCodeFromCode:)])
    return [self.delegate encryptedCodeFromCode:[self.dataSource performSelector:selector]];
  else return [self _encryptedCodeFromCode:[self.dataSource performSelector:selector]];
}

// Return the unlock code
- (NSString *)_unlockCode {
//  NSString * appBuildDate =
//    ([self.dataSource respondsToSelector:@selector(appBuildDate)]
//     ? [self.dataSource appBuildDate] : nil);
  
//  UIDevice * device = [UIDevice currentDevice];
//  [[NSUserDefaults standardUserDefaults] stringForKey:kUDKeyAboutVersion],
//  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBuildDate"],
//  [[NSLocale currentLocale] localeIdentifier];
//  device.model;
//  device.systemName; device.systemVersion;
  
  NSString * code = [NSString stringWithFormat:[self _codeFormat],
                     [self _factorForType:kKYUnlockCodeManagerFactorTypeOfDeviceUID],
                     [self _factorForType:kKYUnlockCodeManagerFactorTypeOfUserAccount],
                     [self _factorForType:kKYUnlockCodeManagerFactorTypeOfUserAccountCreatedDate],
                     [self _factorForType:kKYUnlockCodeManagerFactorTypeOfAppVersionSha],
                     [self _factorForType:kKYUnlockCodeManagerFactorTypeOfAppBuiltDate]];
  NSLog(@"- ORIGINAL CODE: %@", code);
  
  // Fix code's length if the actual length is not matched
  if (code.length == [self.dataSource codeLength])
    return code;
  return ([self.delegate respondsToSelector:@selector(resizedCodeFromCode:)]
          ? [self.delegate resizedCodeFromCode:code]
          : [self _resizedCodeFromCode:code]);
}

#pragma mark - Public Methods

// Unlock with the code
//
// If code is valid, return YES,
// otherwise, return NO
//
- (BOOL)unlockWithCode:(NSString *)code {
  return (code == [self _unlockCode]);
}

@end