//
//  KYUnlockCodeManager.h
//  KYUnlockCodeManager
//
//  Created by Kjuly on 3/3/13.
//  Copyright (c) 2013 Kjuly. All rights reserved.
//

#import <Foundation/Foundation.h>


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


@interface KYUnlockCodeManager : NSObject

@property (nonatomic, assign) id <KYUnlockCodeManagerDataSource> dataSource;
@property (nonatomic, assign) id <KYUnlockCodeManagerDelegate>   delegate;

// Unlock with the code
//
// If code is valid, return YES,
// otherwise, return NO
//
- (BOOL)unlockWithCode:(NSString *)code;

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
