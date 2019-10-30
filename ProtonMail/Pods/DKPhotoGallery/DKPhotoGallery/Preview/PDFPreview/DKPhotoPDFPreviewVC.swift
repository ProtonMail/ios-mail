import UIKit
import PDFKit

@available(iOS 11.0, *)
open class DKPhotoPDFPreviewVC: DKPhotoBasePreviewVC {

    public var closeBlock: (() -> Void)?
    
    public var autoHidesControlView = true
    
    public var tapToToggleControlView = true
    
    public var beginPlayBlock: (() -> Void)?
    
    private var pdfView: DKPDFView?
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        
        pdfView?.url = nil
        pdfView?.document = nil
    }
    
    // MARK: - DKPhotoBasePreviewDataSource
    
    open override func createContentView() -> UIView {
        self.pdfView = DKPDFView()
        return self.pdfView!
    }
    
    open override func contentSize() -> CGSize {
        return self.view.bounds.size
    }
    
    open override func fetchContent(withProgressBlock progressBlock: @escaping ((Float) -> Void), completeBlock: @escaping ((Any?, Error?) -> Void)) {
        if let pdfURL = self.item.pdfURL {
            completeBlock(pdfURL, nil)
        }
    }
    
    open override func updateContentView(with content: Any) {
        if let document = content as? PDFDocument {
            self.pdfView?.document = document
        } else if let url = content as? URL {
            self.pdfView?.url = url
        }
    }
    
    open override func enableZoom() -> Bool {
        return false
    }
    
    public override func enableIndicatorView() -> Bool {
        return false
    }
    
    open override var previewType: DKPhotoPreviewType {
        get { return .pdf }
    }

}
