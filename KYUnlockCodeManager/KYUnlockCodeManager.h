//
//  KYUnlockCodeManager.h
//  KYUnlockCodeManager
//
//  Created by Kjuly on 3/3/13.
//  Copyright (c) 2013 Kjuly. All rights reserved.
//

#import <Foundation/Foundation.h>


#define kKYUnlockCodeManagerNShowCodeInputView @"KYUnlockCodeManagerNShowCodeInputView"
#define kKYUnlockCodeManagerNUnlocked          @"KYUnlockCodeManagerNUnlocked"

typedef enum {
  kKYUnlockCodeManagerFactorTypeNone = 0,
  kKYUnlockCodeManagerFactorTypeOfDeviceUID,
  kKYUnlockCodeManagerFactorTypeOfUserAccount,
  kKYUnlockCodeManagerFactorTypeOfUserAccountCreatedDate,
  kKYUnlockCodeManagerFactorTypeOfAppVersionSha,
  kKYUnlockCodeManagerFactorTypeOfAppBuiltDate
}KYUnlockCodeManagerFactorType;


@protocol KYUnlockCodeManagerDataSource;
@protocol KYUnlockCodeManagerDelegate;


@interface KYUnlockCodeManager : NSObject <UIAlertViewDelegate>

@property (nonatomic, assign) id <KYUnlockCodeManagerDataSource> dataSource;
@property (nonatomic, assign) id <KYUnlockCodeManagerDelegate>   delegate;

// Check whether the feature is locked or not, return a boolean value.
//
// |feature| is feature's identifier to distinguish different features,
//   use |nil| if only one feature needs to be managed or all features are
//   managed together as a package
//
- (BOOL)isLockedOnFeature:(NSString *)feature;
// Unlock the feature with the code
//
// If code is valid, return YES,
// otherwise, return NO
//
- (BOOL)unlockFeature:(NSString *)feature
             withCode:(NSString *)code;

@end


// Data Source
@protocol KYUnlockCodeManagerDataSource <NSObject>

@required

// Tells the data source to return the code length
- (NSInteger)codeLength;

@optional

// Tells the data source to return the code order
- (NSString *)codeOrder;

// Tells the data source to return the factors
- (NSString *)deviceUID;
- (NSString *)userAccount;
- (NSString *)userAccountCreatedDate;
- (NSString *)appVersionSha;
- (NSString *)appBuiltDate;

@end


// Delegate
@protocol KYUnlockCodeManagerDelegate <NSObject>

@optional

// Informs the delegate that encrypt the code that offered
- (NSString *)encryptedCodeFromCode:(NSString *)code;
// Informs the delegate that resize the code that offered
- (NSString *)resizedCodeFromCode:(NSString *)code;

@end
