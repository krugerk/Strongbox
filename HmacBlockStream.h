//
//  HmacBlockStream.h
//  Strongbox
//
//  Created by Strongbox on 08/06/2020.
//  Copyright © 2020 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Keys.h"

NS_ASSUME_NONNULL_BEGIN

@interface HmacBlockStream : NSInputStream

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithData:(uint8_t *)data length:(size_t)length hmacKey:(NSData*)hmacKey;

NSData* getBlockHmac(NSData *data, NSData* hmacKey, uint64_t blockIndex);
NSData* getHmacKeyForBlock(NSData* key, uint64_t blockIndex);

@end

NS_ASSUME_NONNULL_END
