//
//  KYUnlockCodeManager.m
//  KYUnlockCodeManager
//
//  Created by Kjuly on 3/3/13.
//  Copyright (c) 2013 Kjuly. All rights reserved.
//

#import "KYUnlockCodeManager.h"

#import <CommonCrypto/CommonDigest.h>

#define kKYUnlockCodeManagerDefaultCode_       @"unlockCode"
#define kKYUnlockCodeManagerDefaultCodeOrder_  @"12345"
#define kKYUnlockCodeManagerDefaultCodeFormat_ @"%@%@%@%@%@"


@interface KYUnlockCodeManager ()

// Lock status in keychain
// Return the lock statue with code
- (NSString *)_lockStatusForFeature:(NSString *)feature;
// Return the key of keychain for lock status
- (NSString *)_keyOfLockStatusForFeature:(NSString *)feature;
// Return reset lock status with code
// It'll be occured only in two cases:
//   - Lock status is empty
//   - User enter the right code to unlock the feature
- (NSString *)_resetLockStatusForFeature:(NSString *)feature
                                withCode:(NSString *)code;

// To MD5
- (NSString *)_toMD5FromString:(NSString *)string;
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

// Code input view
- (void)_showCodeInputView:(NSNotification *)note;

@end


@implementation KYUnlockCodeManager

@synthesize dataSource, delegate;

- (void)dealloc {
  self.dataSource = nil;
  self.delegate   = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (id)init {
  if (self = [super init]) {
    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
    // Notifi to show code input view
    [notificationCenter addObserver:self
                           selector:@selector(_showCodeInputView:)
                               name:kKYUnlockCodeManagerNShowCodeInputView
                             object:nil];
  }
  return self;
}

#pragma mark - Default Methods for Delegate

// To MD5
- (NSString *)_toMD5FromString:(NSString *)string {
  // Create pointer to the string as UTF8
  const char * ptr = [string UTF8String];
  
  // Create byte array of unsigned chars
  unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
  
  // Create 16 byte MD5 hash value, store in buffer
  CC_MD5(ptr, strlen(ptr), md5Buffer);
  
  // Convert MD5 value in the buffer to NSString of hex values
  NSMutableString * output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
  for(int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i)
    [output appendFormat:@"%02x",md5Buffer[i]];
  return output;
}

// Default for delegate method: |-encryptedCodeFromCode:|
- (NSString *)_encryptedCodeFromCode:(NSString *)code {
  // To MD5
  NSString * encryptedCode = [self _toMD5FromString:code];
  // Return filtered code
  return [encryptedCode substringToIndex:2];
}

// Default for delegate method: |-resizedCodeFromCode:|
- (NSString *)_resizedCodeFromCode:(NSString *)code {
  NSInteger codeLength = [self.dataSource codeLength];
  return (code.length <= codeLength ? code : [code substringToIndex:codeLength]);
}

#pragma mark - Private Methods

// Lock status in keychain
// Return the lock statue with code
- (NSString *)_lockStatusForFeature:(NSString *)feature {
  NSString * key  = [self _keyOfLockStatusForFeature:feature];
  NSString * code = nil;
  
  // UID must be persistent even if the application is removed from devices
  // Use keychain as a storage
  NSDictionary * query = [NSDictionary dictionaryWithObjectsAndKeys:
                          (id)kSecClassGenericPassword,            (id)kSecClass,
                          key,                                     (id)kSecAttrGeneric,
                          key,                                     (id)kSecAttrAccount,
                          [[NSBundle mainBundle] bundleIdentifier],(id)kSecAttrService,
                          (id)kSecMatchLimitOne,                   (id)kSecMatchLimit,
                          (id)kCFBooleanTrue,                      (id)kSecReturnAttributes,
                          nil];
  CFTypeRef attributesRef = NULL;
  OSStatus result = SecItemCopyMatching((CFDictionaryRef)query, &attributesRef);
  if (result == noErr) {
    NSDictionary * attributes = (NSDictionary *)attributesRef;
    NSMutableDictionary * valueQuery = [NSMutableDictionary dictionaryWithDictionary:attributes];
    
    [valueQuery setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    [valueQuery setObject:(id)kCFBooleanTrue           forKey:(id)kSecReturnData];
    
    CFTypeRef passwordDataRef = NULL;
    OSStatus result = SecItemCopyMatching((CFDictionaryRef)valueQuery, &passwordDataRef);
    if (result == noErr) {
      NSData * passwordData = (NSData *)passwordDataRef;
      // Assume the stored data is a UTF-8 string.
      code = [[NSString alloc] initWithBytes:[passwordData bytes]
                                      length:[passwordData length]
                                    encoding:NSUTF8StringEncoding];
    }
  }
  
  // Generate a new UID for device if it does not exist
  if (code == nil)
    code = [self _resetLockStatusForFeature:feature
                                   withCode:kKYUnlockCodeManagerDefaultCode_];
  return code;
}

// Return the key of keychain for lock status
- (NSString *)_keyOfLockStatusForFeature:(NSString *)feature {
  NSString * keyBasic = @"Master:LockStatus";
  if (feature == nil) return keyBasic;
  return [NSString stringWithFormat:@"%@:Feature:%@", keyBasic, feature];
}

// Return reset lock status with code
// It'll be occured only in two cases:
//   - Lock status is empty
//   - User enter the right code to unlock the feature
- (NSString *)_resetLockStatusForFeature:(NSString *)feature
                                withCode:(NSString *)code {
  NSLog(@"- RESET Lock Status with CODE: %@", code);
  // Key for lock status
  NSString * key  = [self _keyOfLockStatusForFeature:feature];
  // It must be persistent even if the application is removed from devices
  // Use keychain as a storage
  NSMutableDictionary * query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 (id)kSecClassGenericPassword,             (id)kSecClass,
                                 key,                                      (id)kSecAttrGeneric,
                                 key,                                      (id)kSecAttrAccount,
                                 [[NSBundle mainBundle] bundleIdentifier], (id)kSecAttrService,
                                 @"",                                      (id)kSecAttrLabel,
                                 @"",                                      (id)kSecAttrDescription,
                                 nil];
  // Set |kSecAttrAccessibleAfterFirstUnlock|
  //   so that background applications are able to access this key.
  // Keys defined as |kSecAttrAccessibleAfterFirstUnlock|
  //   will be migrated to the new devices/installations via encrypted backups.
  // If you want different UID per device,
  //   use |kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly| instead.
  // Keep in mind that keys defined
  //   as |kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly|
  //   will be removed after restoring from a backup.
  [query setObject:(id)kSecAttrAccessibleAfterFirstUnlock
            forKey:(id)kSecAttrAccessible];
  // Set UID
  [query setObject:[code dataUsingEncoding:NSUTF8StringEncoding]
            forKey:(id)kSecValueData];
  
  // Delete old one first
  OSStatus result = SecItemDelete((CFDictionaryRef)query);
  if (result == noErr)
    NSLog(@"[INFO}  Unlock Code is successfully reset.");
  else if (result == errSecItemNotFound)
    NSLog(@"[INFO}  Unlock Code is successfully reset.");
  else
    NSLog(@"[ERROR] Coudn't delete the Keychain Item. result = %ld query = %@", result, query);
  
  // Add new
  result = SecItemAdd((CFDictionaryRef)query, NULL);
  if (result != noErr) {
    NSLog(@"!!!ERROR: Couldn't add the Keychain Item. result = %ld, query = %@", result, query);
    return nil;
  }
  return code;
}

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
  
  // Generate code
  NSString * code = [NSString stringWithFormat:[self _codeFormat],
                     [self _factorForType:kKYUnlockCodeManagerFactorTypeOfDeviceUID],
                     [self _factorForType:kKYUnlockCodeManagerFactorTypeOfUserAccount],
                     [self _factorForType:kKYUnlockCodeManagerFactorTypeOfUserAccountCreatedDate],
                     [self _factorForType:kKYUnlockCodeManagerFactorTypeOfAppVersionSha],
                     [self _factorForType:kKYUnlockCodeManagerFactorTypeOfAppBuiltDate]];
  
  // Fix code's length if the actual length is not matched
  if (code.length == [self.dataSource codeLength])
    return code;
  return ([self.delegate respondsToSelector:@selector(resizedCodeFromCode:)]
          ? [self.delegate resizedCodeFromCode:code]
          : [self _resizedCodeFromCode:code]);
}

// Code input view
// Show code input view
- (void)_showCodeInputView:(NSNotification *)note {
  NSString * feature = note.object;
  // If not locked, do nothing
  if (! [self isLockedOnFeature:feature])
    return;
  
  // Show code input view
  UIAlertView * codeInputView = [UIAlertView alloc];
  [codeInputView initWithTitle:NSLocalizedString(@"KYUnlockCodeManager:CodeInputViewTitle", nil)
                       message:nil
                      delegate:self
             cancelButtonTitle:NSLocalizedString(@"KYUnlockCodeManager:Cancel", nil)
             otherButtonTitles:NSLocalizedString(@"KYUnlockCodeManager:Confirm", nil), nil];
  [codeInputView setAlertViewStyle:UIAlertViewStylePlainTextInput];
  [codeInputView show];
  [codeInputView release];
}

#pragma mark - Public Methods

// Check whether the feature is locked or not, return a boolean value.
//
// |feature| is feature's identifier to distinguish different features,
//   use |nil| if only one feature needs to be managed.
//
- (BOOL)isLockedOnFeature:(NSString *)feature {
  NSString * code = [self _lockStatusForFeature:feature];
  if (
#ifdef kKYUnlockCodeManagerUniqueCodeDefined
      [code isEqualToString:kKYUnlockCodeManagerUniqueCode] ||
#endif
      [code isEqualToString:[self _unlockCode]])
    return NO;
  return YES;
}

// Unlock with the code
//
// If code is valid, return YES,
// otherwise, return NO
//
- (BOOL)unlockFeature:(NSString *)feature
             withCode:(NSString *)code {
  BOOL isLocked = YES;
  if (
#ifdef kKYUnlockCodeManagerUniqueCodeDefined
      [code isEqualToString:kKYUnlockCodeManagerUniqueCode] ||
#endif
      [code isEqualToString:[self _unlockCode]])
  {
    isLocked = NO;
    [self _resetLockStatusForFeature:feature withCode:code];
  }
  return isLocked;
}

// Reset code to default for feature
- (void)resetCodeForFeature:(NSString *)feature {
  [self _resetLockStatusForFeature:feature
                          withCode:kKYUnlockCodeManagerDefaultCode_];
}

#pragma mark - UIAlertView Delegate

- (void)   alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex != 1) return;
  
  // Check the code
  NSString * code = [alertView textFieldAtIndex:0].text;
  if ([self unlockFeature:nil withCode:code])
    return;
  // Code is valid, post notifi to observer to unlock the feature
  [[NSNotificationCenter defaultCenter] postNotificationName:kKYUnlockCodeManagerNUnlocked
                                                      object:nil];
}

@end
