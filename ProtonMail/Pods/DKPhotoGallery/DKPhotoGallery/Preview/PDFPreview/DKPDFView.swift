import UIKit
import PDFKit

@available(iOS 11.0, *)
open class DKPDFView: UIView {
    
    public var url: URL? {
        
        willSet {
            if self.url == newValue {
                return
            }
            
            if let newValue = newValue {
                self.bufferingIndicator.startAnimating()
                DispatchQueue.global().async {
                    if newValue == self.url {
                        let document = PDFDocument(url: newValue)

                        DispatchQueue.main.async {
                            if newValue == self.url {
                                self.document = document
                                self.pdfView.scaleFactor = self.pdfView.scaleFactorForSizeToFit
                            }
                            self.bufferingIndicator.stopAnimating()
                        }
                    }
                }
            } else {
                self.document = nil
            }
        }
    }
    
    public var document: PDFDocument? {
        
        didSet {
            if self.document == oldValue {
                return
            }
            
            pdfView.document = document
        }
    }

    public let openButton = UIButton(type: .custom)
    
    private lazy var bufferingIndicator: UIActivityIndicatorView = {
        #if swift(>=4.2)
        return UIActivityIndicatorView(style: .gray)
        #else
        return UIActivityIndicatorView(activityIndicatorStyle: .gray)
        #endif
    }()
    
    private var pdfView = PDFView()

    public init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupUI()
    }

    private func setupUI() {
        self.addSubview(pdfView)
        pdfView.displayDirection = .vertical
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfView.leftAnchor.constraint(equalTo: leftAnchor),
            pdfView.rightAnchor.constraint(equalTo: rightAnchor),
            pdfView.topAnchor.constraint(equalTo: topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        self.bufferingIndicator.hidesWhenStopped = true
        self.bufferingIndicator.isUserInteractionEnabled = false
        self.bufferingIndicator.center = self.center
        self.bufferingIndicator.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleRightMargin]
        self.addSubview(self.bufferingIndicator)
    }

}
