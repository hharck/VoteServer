import Foundation
extension String{
    func asURLSafeB64()-> String?{
        self.data(using: .utf8)?
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
    
    init?(urlsafeBase64: String){
        let b64str = urlsafeBase64.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        if let data = Data(base64Encoded: b64str){
            self.init(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
}
