//
//  StrongboxTests.m
//  StrongboxTests
//
//  Created by Mark on 16/10/2018.
//  Copyright © 2018 Mark McGuill. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassDatabase.h"
#import "XmlStrongboxNodeModelAdaptor.h"
#import "KdbxSerialization.h"
#import "Kdbx4Serialization.h"
#import "CommonTesting.h"

@interface KeePassXmlSerializationTests : XCTestCase

@end

@implementation KeePassXmlSerializationTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDeserializeGzippedFile {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"generic" ofType:@"kdbx"];
    NSData* safeData = [NSData dataWithContentsOfFile:path];
    
    CompositeKeyFactors* cpf = [[CompositeKeyFactors alloc] initWithPassword:@"a"];
    [KdbxSerialization deserialize:safeData
               compositeKeyFactors:cpf
     useLegacyDeserialization:NO
                        completion:^(BOOL userCancelled, SerializationData * _Nullable data, NSError * _Nullable error) {
        if(!data) {
            NSLog(@"%@", error);
        }
        
        XCTAssert(data != nil);

        NSLog(@"%@", data);
        //NSLog(@"%@", data.xml);
        
        XCTAssertEqual(data.rootXmlObject.keePassFile.root.rootGroup.groups.count, 6);
        XCTAssertEqualObjects(data.rootXmlObject.keePassFile.meta.generator, @"MacPass");
    }];
}

- (void)testDeserializeNonGzippedFile {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"generic-non-gzipped" ofType:@"kdbx"];
    NSData* safeData = [NSData dataWithContentsOfFile:path];
    
    //KeePassDatabase *db = [[KeePassDatabase alloc] initExistingWithDataAndPassword:safeData password:@"a" error:&error];
    
    CompositeKeyFactors* cpf = [[CompositeKeyFactors alloc] initWithPassword:@"a"];
    [KdbxSerialization deserialize:safeData
               compositeKeyFactors:cpf useLegacyDeserialization:NO
                        completion:^(BOOL userCancelled, SerializationData * _Nullable data, NSError * _Nullable error) {
        if(!data) {
            NSLog(@"%@", error);
        }
        
        XCTAssert(data != nil);
        
        NSLog(@"%@", data);
        //NSLog(@"%@", data.xml);
        XCTAssertEqual(data.rootXmlObject.keePassFile.root.rootGroup.groups.count, 6);
    }];
}

- (void)testDeserializeGoogleDriveFileToXml {
    NSData *safeData = [[NSFileManager defaultManager] contentsAtPath:@"/Users/strongbox/strongbox-test-files/Database.kdbx"];
    
    CompositeKeyFactors* cpf = [[CompositeKeyFactors alloc] initWithPassword:@"a"];
    [Kdbx4Serialization deserialize:safeData
                compositeKeyFactors:cpf useLegacyDeserialization:NO
                         completion:^(BOOL userCancelled, Kdbx4SerializationData * _Nullable data, NSError * _Nullable error) {
        if(!data) {
            NSLog(@"%@", error);
        }
        
        XCTAssert(data != nil);
        
        NSLog(@"%@", data);
    }];
}

- (void)testDeserializeFileWithBinariesAndCustomFields {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"Database" ofType:@"kdbx"];
    NSData* safeData = [NSData dataWithContentsOfFile:path];
    
    CompositeKeyFactors* cpf = [[CompositeKeyFactors alloc] initWithPassword:@"a"];
    [KdbxSerialization deserialize:safeData
                                         compositeKeyFactors:cpf useLegacyDeserialization:NO
                                                  completion:^(BOOL userCancelled, SerializationData * _Nullable data, NSError * _Nullable error) {
        if(!data) {
            NSLog(@"%@", error);
        }
        
        XCTAssert(data != nil);
        
        NSLog(@"%@", data);
        //NSLog(@"%@", data.xml);
        XCTAssertEqual(data.rootXmlObject.keePassFile.root.rootGroup.groups.count, 6);
    }];
}

@end
