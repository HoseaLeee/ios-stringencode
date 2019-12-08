- (void)test{
    
    NSString *key = @"vNIXE0xscrmjlyV-12Nj_BvUPaw=";
    NSString *url =
      @"/maps/api/geocode/json?address=New+York&sensor=false&client=clientID";

//    NSData *urlData = [url dataUsingEncoding:NSASCIIStringEncoding];
//
//
//    NSData *binaryKey = [self safeURLRBase64Decode:key];
//
//
//    unsigned char result[CC_SHA1_DIGEST_LENGTH];
//    CCHmac(kCCHmacAlgSHA1,
//      [binaryKey bytes], [binaryKey length],
//      [urlData bytes], [urlData length],
//      &result);
//    NSData *binarySignature =
//      [NSData dataWithBytes:&result length:CC_SHA1_DIGEST_LENGTH];
//
//    // Encodes the signature to URL-safe Base64.
//    NSString *signature = [self safeURLBase64Encode:binarySignature];
//
    
    // Stores the url in a NSData.
     NSData *urlData = [url dataUsingEncoding: NSASCIIStringEncoding];

     // URL-safe Base64 coder/decoder.
     StringEncode *encoding =
       [StringEncode base64WebsafeStringEncoding];

     // Decodes the URL-safe Base64 key to binary.
    NSError *decodeError;
    NSData *binaryKey = [encoding decode:key error:&decodeError];

     // Signs the URL.
     unsigned char result[CC_SHA1_DIGEST_LENGTH];
     CCHmac(kCCHmacAlgSHA1,
       [binaryKey bytes], [binaryKey length],
       [urlData bytes], [urlData length],
       &result);
     NSData *binarySignature =
       [NSData dataWithBytes:&result length:CC_SHA1_DIGEST_LENGTH];

     // Encodes the signature to URL-safe Base64.
    NSError *signatureError;
     NSString *signature = [encoding encode:binarySignature error:&signatureError];

    
    // _wgLnWTxDO564zTFhlTO3zZ5Rek=
    NSLog(@"--- %@",signature);

}
