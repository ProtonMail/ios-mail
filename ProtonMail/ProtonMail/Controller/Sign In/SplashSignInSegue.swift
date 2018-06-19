//
//  SplashSignInSegue.swift
//
//
//  Created by Yanfeng Zhang on 12/14/15.
//
//

class SplashSignInSegue: UIStoryboardSegue {
    
    override func perform() {
        let src = self.source
        let dst = self.destination
        src.navigationController?.pushViewController(dst, animated:false)
    }
}
