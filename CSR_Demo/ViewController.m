//
//  ViewController.m
//  CSR_Demo
//
//  Created by Sunil on 11/11/17.
//  Copyright © 2017 Sunil. All rights reserved.
//

#import "ViewController.h"
#import "SCCSR.h"
static const UInt8 publicKeyIdentifier[] = "com.apple.sample.publickey\0";
static const UInt8 privateKeyIdentifier[] = "com.apple.sample.privatekey\0";
@interface ViewController ()
{
    SecKeyRef publicKey;
    SecKeyRef privateKey;
}
@property (weak, nonatomic) IBOutlet UIButton *btnGenerateKeyPair;
@property (weak, nonatomic) IBOutlet UIButton *btnGenerateCSR;
@property (weak, nonatomic) IBOutlet UITextView *txtCSR;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //Navigation title and background color
    self.title = @"CSR Demo";
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    //UIDesign changes
    self.txtCSR.text= @"";
    self.btnGenerateCSR.enabled = false;
    _btnGenerateCSR.backgroundColor = [UIColor grayColor];
    self.btnGenerateKeyPair.enabled = true;
    
    //border color
    _txtCSR.layer.borderWidth = 1.0;
    _txtCSR.layer.borderColor = [UIColor grayColor].CGColor;
    
    //corner radius
    _btnGenerateCSR.layer.cornerRadius = 5.0;
    _btnGenerateKeyPair.layer.cornerRadius = 5.0;
    _btnGenerateKeyPair.clipsToBounds = true;
    _btnGenerateCSR.clipsToBounds = true;
}

//Converting public key into raw bits
- (NSData *)getPublicKeyBitsFromKey:(SecKeyRef)givenKey {
    NSData *publicTag = [[NSData alloc] initWithBytes:publicKeyIdentifier length:sizeof(publicKeyIdentifier)];
    
    OSStatus sanityCheck = noErr;
    NSData * publicKeyBits = nil;
    
    NSMutableDictionary * queryPublicKey = [[NSMutableDictionary alloc] init];
    [queryPublicKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [queryPublicKey setObject:publicTag forKey:(__bridge id)kSecAttrApplicationTag];
    [queryPublicKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Temporarily add key to the Keychain, return as data:
    NSMutableDictionary * attributes = [queryPublicKey mutableCopy];
    [attributes setObject:(__bridge id)givenKey forKey:(__bridge id)kSecValueRef];
    [attributes setObject:@YES forKey:(__bridge id)kSecReturnData];
    CFTypeRef result;
    sanityCheck = SecItemAdd((__bridge CFDictionaryRef) attributes, &result);
    if (sanityCheck == errSecSuccess) {
        publicKeyBits = CFBridgingRelease(result);
        
        // Remove from Keychain again:
        (void)SecItemDelete((__bridge CFDictionaryRef) queryPublicKey);
    }
    
    return publicKeyBits;
}

//Generating keypair
- (IBAction)btnGenerateKeypairClicked:(id)sender {
    self.btnGenerateCSR.enabled = true;
    self.btnGenerateKeyPair.enabled = false;
    _btnGenerateKeyPair.backgroundColor = [UIColor grayColor];
    _btnGenerateCSR.backgroundColor = [UIColor colorWithRed:0 green:96.0/255.0 blue:172.0/255.0 alpha:1.0];

    OSStatus status = noErr;
    NSMutableDictionary *privateKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *publicKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *keyPairAttr = [[NSMutableDictionary alloc] init];
    // 2
    
    NSData * publicTag = [NSData dataWithBytes:publicKeyIdentifier
                                        length:strlen((const char *)publicKeyIdentifier)];
    NSData * privateTag = [NSData dataWithBytes:privateKeyIdentifier
                                         length:strlen((const char *)privateKeyIdentifier)];
    // 3
    publicKey = NULL;
    privateKey = NULL;
    // 4
    
    [keyPairAttr setObject:(id)kSecAttrKeyTypeRSA
                    forKey:(id)kSecAttrKeyType]; // 5
    [keyPairAttr setObject:[NSNumber numberWithInt:2048]
                    forKey:(id)kSecAttrKeySizeInBits]; // 6
    
    [privateKeyAttr setObject:[NSNumber numberWithBool:YES]
                       forKey:(id)kSecAttrIsPermanent]; // 7
    [privateKeyAttr setObject:privateTag
                       forKey:(id)kSecAttrApplicationTag]; // 8
    
    [publicKeyAttr setObject:[NSNumber numberWithBool:YES]
                      forKey:(id)kSecAttrIsPermanent]; // 9
    [publicKeyAttr setObject:publicTag
                      forKey:(id)kSecAttrApplicationTag]; // 10
    
    [keyPairAttr setObject:privateKeyAttr
                    forKey:(id)kSecPrivateKeyAttrs]; // 11
    [keyPairAttr setObject:publicKeyAttr
                    forKey:(id)kSecPublicKeyAttrs]; // 12
    
    status = SecKeyGeneratePair((CFDictionaryRef)keyPairAttr,
                                &publicKey, &privateKey); // 13
    
}
//Generating CSR
- (IBAction)btnGenerateCSRClicked:(id)sender {
    self.btnGenerateCSR.enabled = false;
    self.btnGenerateKeyPair.enabled = true;
    _btnGenerateKeyPair.backgroundColor =[UIColor colorWithRed:0 green:96.0/255.0 blue:172.0/255.0 alpha:1.0] ;
    _btnGenerateCSR.backgroundColor = [UIColor grayColor];
    // Do any additional setup after loading the view, typically from a nib.
    SCCSR *sccsr = [[SCCSR alloc] init];
    sccsr.commonName = @"Sunil";
    sccsr.organizationName = @"eMudhra Ltd";
    // aditional data you can set
    sccsr.countryName = @"IN";
    sccsr.organizationalUnitName = @"eMTest";
    sccsr.subjectDER = nil;
  
    NSData *publicBits = [self getPublicKeyBitsFromKey:publicKey];
    NSData *certificateRequest = [sccsr build:publicBits privateKey:privateKey];
    
    NSString *str = [certificateRequest base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSString *strCertificateRequest = @"-----BEGIN CERTIFICATE REQUEST-----\n";
    strCertificateRequest = [strCertificateRequest stringByAppendingString:str];
    strCertificateRequest = [strCertificateRequest stringByAppendingString:@"\n-----END CERTIFICATE REQUEST-----\n"];
    
    self.txtCSR.text = strCertificateRequest;
    
    //    error handling...
    if(publicKey) CFRelease(publicKey);
    if(privateKey) CFRelease(privateKey);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
