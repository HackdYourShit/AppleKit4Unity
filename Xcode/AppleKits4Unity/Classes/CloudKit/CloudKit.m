//
//  CloudKit.m
//  AppleKits4Unity
//
//  Created by Alex Griffin on 18/2/20.
//  Copyright © 2020 Forbidden Cactus. All rights reserved.
//

#import "CloudKit.h"
#import <CloudKit/CloudKit.h>
#import "AppleKitsConstants.h"
#import "Callback.h"
#import "BridgeHelpers.h"

@implementation CloudKit
{
    CKDatabase* privateDatabase;
    CKContainer* container;
    CKRecordZone* defaultZone;
    NSMutableDictionary* recordStore;
}

+ (CloudKit*)sharedInstance
{
    static CloudKit *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CloudKit alloc] init];
    });
    
    return sharedInstance;
}

-(id) init
{
    self = [super init];
    if (self)
    {
        container = [CKContainer defaultContainer];
        privateDatabase = [container privateCloudDatabase];
        defaultZone = [CKRecordZone defaultRecordZone];
        recordStore = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

-(CKRecord*)FindOrCreateRecordWithKey:(NSString*) key withType:(CKRecordType) type
{
    if ([recordStore objectForKey:key] != nil)
    {
        return [recordStore objectForKey:key];
    }
    
    CKRecordID* recordID= [[CKRecordID alloc] initWithRecordName:key];
    CKRecord *record = [[CKRecord alloc] initWithRecordType:type recordID:recordID];
    
    return record;
}

-(void) CheckAccountStatus:(CallbackKey) result
{
    [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {

        if (accountStatus == CKAccountStatusAvailable)
        {
            [[Callback sharedInstance] GetResultCallback](result, true, NULL);
        }
        else
        {
            [[Callback sharedInstance] GetResultCallback](result, false, cstr(@"iCloud does not seem to be available?"));
        }
    }];
}

-(void) SaveFileWithKey:(NSString*)key filePath:(NSString*) filePath resultHandler:(CallbackKey) result
{
    CKRecord* record = [self FindOrCreateRecordWithKey: key withType:CKRecordTypeUserRecord];
    NSURL* url = [NSURL fileURLWithPath:filePath];
    record[RECORDTYPEFILE] = [[CKAsset alloc]initWithFileURL:url];
    
    [privateDatabase saveRecord:record completionHandler:^(CKRecord *record, NSError *error)
    {
       if (error)
       {
           [[Callback sharedInstance]GetResultCallback](result, false, cstr(error.description));
           return;
       }

        [[Callback sharedInstance]GetResultCallback](result, true, NULL);

    }];
}


-(void) FetchFileWithKey:(NSString*) key fileResultHandler:(CallbackKey) fileResult
{
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:key];

    [privateDatabase fetchRecordWithID:recordID completionHandler:^(CKRecord *record, NSError *error) {

       if (error)
       {
           [[Callback sharedInstance]GetFileResultCallback](fileResult, false, NULL, cstr(error.description));
           return;

       }
       else
       {
           CKAsset* asset = record[RECORDTYPEFILE];
           [[Callback sharedInstance]GetFileResultCallback](fileResult, true, cstr([asset.fileURL absoluteString]), NULL);
       }
    }];
}

-(void) SaveStringWithKey:(NSString*) key string:(NSString*) string resultHandler:(CallbackKey) result
{
    CKRecord* record = [self FindOrCreateRecordWithKey: key withType:RECORDTYPESTRING];
    record[RECORDTYPESTRING] = string;
    
    [privateDatabase saveRecord:record completionHandler:^(CKRecord *record, NSError *error)
    {
       if (error)
       {
           [[Callback sharedInstance]GetResultCallback](result, false, cstr(error.description));
           return;
       }

        [[Callback sharedInstance]GetResultCallback](result, true, NULL);

    }];
}

-(void) FetchStringWithKey:(NSString*) key stringResultHandler:(CallbackKey) stringResult
{
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:key];

    [privateDatabase fetchRecordWithID:recordID completionHandler:^(CKRecord *record, NSError *error) {

       if (error)
       {
           [[Callback sharedInstance]GetStringResultCallback](stringResult, false, NULL, cstr(error.description));
           return;

       }
       else
       {
           NSString* string = record[RECORDTYPESTRING];
           [[Callback sharedInstance]GetStringResultCallback](stringResult, true, cstr(string), NULL);
       }
    }];
}

@end
