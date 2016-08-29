//
//  NSData+MultipartResponses.m
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/22/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

#import "NSData+MultipartResponses.h"

@implementation NSData (MultipartResponses)

static NSMutableDictionary *parseHeaders(const char *headers)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    unsigned long max = strlen(headers);
    unsigned long start = 0;
    unsigned long cursor =0;

    while(cursor<max)
    {
        while((headers[cursor] != ':') && (headers[cursor] != '='))
        {
            cursor++;
        }
        NSString *key=[[NSString alloc] initWithBytes:(headers+start) length:(cursor-start) encoding:NSASCIIStringEncoding];
        cursor++;
        
        while(headers[cursor]==' ')
        {
            cursor++;
        }
        start=cursor;
        while(headers[cursor]&&(headers[cursor]!=';')&&((headers[cursor]!=13)||(headers[cursor+1]!=10)))
        {
            cursor++;
        }
        
        NSString *value;
        if((headers[start]=='"')&&(headers[cursor-1]=='"'))
        {
            value=[[NSString alloc] initWithBytes:(headers+start+1) length:(cursor-start-2) encoding:NSASCIIStringEncoding];
        }
        else
        {
            value=[[NSString alloc] initWithBytes:(headers+start) length:(cursor-start) encoding:NSASCIIStringEncoding];
        }
        [dict setObject:value forKey:key];
        
        if(headers[cursor]==';')
        {
            cursor++;
        }
        else
        {
            cursor+=2;
        }
        
        while(headers[cursor]==' ')
        {
            cursor++;
        }
        start=cursor;
    }
    return dict;
}

- (NSDictionary *)multipartDictionaryWithBoundary:(NSString *)boundary
{
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    
    const char *bytes=(const char *)[self bytes];
    const char *pattern=[boundary cStringUsingEncoding:NSUTF8StringEncoding];
    
    unsigned long cursor=0;
    unsigned long start=0;
    unsigned long max=[self length];
    int keyNo = 0;
    while(cursor<max)
    {
        if(bytes[cursor]==pattern[0])
        {
            int i;
            unsigned long patternLength = strlen(pattern);
            BOOL match=YES;
            for(i=0; i<patternLength; i++)
            {
                if(bytes[cursor+i]!=pattern[i])
                {
                    match=NO;
                    break;
                }
            }
            if(match)
            {
                if(start!=0)
                {
                    unsigned long startOfHeaders=start+2;
                    unsigned long cursor2=startOfHeaders;
                    while((bytes[cursor2]!=(char)0x0d)||(bytes[cursor2+1]!=(char)0x0a)||(bytes[cursor2+2]!=(char)0x0d)||(bytes[cursor2+3]!=(char)0x0a))
                    {
                        cursor2++;
                        if(cursor2+4==max)
                        {
                            break;
                        }
                    }
                    if(cursor2+4==max)
                    {
                        break;
                    }
                    else
                    {
                        unsigned long lengthOfHeaders=cursor2-startOfHeaders;
                        char *headers=(char *)malloc((lengthOfHeaders+1)*sizeof(char));
                        strncpy(headers, bytes+startOfHeaders, lengthOfHeaders);
                        headers[lengthOfHeaders]=0;
                        
                        NSMutableDictionary *item = parseHeaders(headers);
                        
                        unsigned long startOfData=cursor2+4;
                        unsigned long lengthOfData=cursor-startOfData-2;
                        
                        if(([item valueForKey:@"Content-Type"]==nil)&&([item valueForKey:@"filename"]==nil))
                        {
                            NSString *string=[[NSString alloc] initWithBytes:(bytes+startOfData) length:lengthOfData encoding:NSUTF8StringEncoding];
                            keyNo++;
                            [dict setObject:string forKey:[NSString stringWithFormat:@"%d", keyNo]];
                        }
                        else
                        {
                            NSData *data=[NSData dataWithBytes:(bytes+startOfData) length:lengthOfData];
                            [item setObject:data forKey:@"data"];
                            keyNo++;
                            [dict setObject:item forKey:[NSString stringWithFormat:@"%d", keyNo]];
                        }
                    }
                }
                cursor= cursor + patternLength - 1;
                start=cursor+1;
            }
        }
        cursor++;
    }
    
    return dict;
}

- (NSArray *)multipartArray
{
    NSDictionary *dict=[self multipartDictionary];
    NSArray *keys=[[dict allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    NSMutableArray *array=[NSMutableArray array];
    for(NSString *key in keys)
    {
        [array addObject:dict[key]];
    }
    return array;
}

- (NSDictionary *)multipartDictionary
{
    const char *bytes=(const char *)[self bytes];
    unsigned long cursor=0;
    unsigned long max=[self length];
    while(cursor<max)
    {
        if(bytes[cursor]==0x0d)
        {
            break;
        }
        else
        {
            cursor++;
        }
    }
    char *pattern=(char *)malloc((cursor+1)*sizeof(char));
    strncpy(pattern, bytes, cursor);
    pattern[cursor]=0x00;
    NSString *boundary=[[NSString alloc] initWithCString:pattern encoding:NSUTF8StringEncoding];
    free(pattern);
    return [self multipartDictionaryWithBoundary:boundary];
}

@end