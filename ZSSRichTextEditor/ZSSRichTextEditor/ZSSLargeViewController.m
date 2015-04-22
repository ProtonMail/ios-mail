//
//  ZSSLargeViewController.m
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 8/13/14.
//  Copyright (c) 2014 Zed Said Studio. All rights reserved.
//

#import "ZSSLargeViewController.h"

@interface ZSSLargeViewController ()

@end

@implementation ZSSLargeViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Large";
    
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Export" style:UIBarButtonItemStylePlain target:self action:@selector(exportHTML)];
    
    // HTML Content to set in the editor
    NSString *html = @"&nbsp;<br>&nbsp;<br>&nbsp;<div>On Sat, Feb 28, 2015 at 4:35 PM, <eavesdalycity@eavesbyavalon.com> wrote:</div><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\"><tbody><tr><td align=\"center\" valign=\"top\"> <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" style=\"background-color:transparent;border-bottom:0;border-bottom:solid 1px #00929f\" width=\"600\">    <tbody><tr><td style=\"padding:0;text-align:left;vertical-align:middle;background-color:#00929f;width:600px!important;height:90px!important\"><img alt=\"AvalonBay Communities\" height=\"91\" src=\"https://ci3.googleusercontent.com/proxy/J-oP4x-impauuXCVBP7wgYkMBY4tJWaqcIr275AwzNOcokicCSOSrAstFLFnv8w0Rv1gY51kkUkJrlmBjZv7RZ24mMRng94IbUiqFaVYenoSJXbqZlgv0rXfF6G6UTYoQAnHuIAszIDM5iMqFWQlmw=s0-d-e1-ft#http://static.avalonbay.com/resources/projectx_images/content/images/deliveries-header.gif\" style=\"max-width:600px;max-height:91px\" width=\"600\" class=\"CToWUd\"></td></tr></tbody></table></td></tr><tr><td align=\"center\" valign=\"top\"><table border=\"0\" cellpadding=\"20\" cellspacing=\"0\" width=\"600\"><tbody><tr><td valign=\"top\" style=\"background-color:#ffffff\"><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\"><tbody><tr><td valign=\"bottom\" style=\"color:#202020;font-family:Calibri,Arial,sans-serif;font-size:15px;line-height:normal;text-align:left\">Dear <strong>anfeng Zhang</strong>,<br><br>We have a delivery for you:<br> <br><strong>Package Type:</strong>USPS<br><br></td></tr><tr>        <td valign=\"top\" colspan=\"2\" style=\"color:#202020;font-family:Calibri,Arial,sans-serif;font-size:15px;line-height:normal;text-align:left;padding-bottom:25px\">If you need to make special arrangements to pick up your delivery, please don't hesitate to contact us. We'd be glad to help!<br><br>Sincerely,<br>eaves Daly City</td></tr> <tr><td colspan=\"2\" style=\"color:#666666;font-size:13px;border-top:solid 1px #cccccc;padding-top:25px;padding-bottom:12px;font-family:Calibri,Arial,sans-serif;line-height:normal;text-align:left\"><span style=\"color:#336699;font-weight:bold\"> eaves Daly City</span><br>500 King Drive&nbsp;&nbsp;|&nbsp;&nbsp;Daly City,CA 94015<br>P:<a href=\"tel:%28650%29%20878-4100\" value=\"+16508784100\" target=\"_blank\">(650) 878-4100</a>&nbsp;&nbsp;|&nbsp;&nbsp;F:<a href=\"tel:%28650%29%20878-4101\" value=\"+16508784101\" target=\"_blank\">(650) 878-4101</a><br><a href=\"mailto:eavesdalycity@eavesbyavalon.com\" style=\"color:#336699;font-weight:normal;text-decoration:underline\" target=\"_blank\">eavesdalycity@eavesbyavalon.<wbr>com</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a style=\"color:#336699;font-weight:normal;text-decoration:underline\"></a><br><br><strong>Hours of Operation:</strong><br>Monday Closed<br>Tuesday 9:30 am to 6:30 pm<br>    Wednesday 9:30 am to 6:30 pm<br>    Thursday 9:30 am to 6:30 pm<br>    Friday 8:30 am to 5:30 pm<br>    Saturday 8:30 am to 5:30 pm<br>    Sunday Closed<br>  </td>    </tr> </tbody></table>  </td>  </tr>  </tbody></table> </td> </tr> </tbody></blockquote>";    
    // Set the HTML contents of the editor
    [self setHTML:html];
    
}

- (void)exportHTML {
    
    NSLog(@"%@", [self getHTML]);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
