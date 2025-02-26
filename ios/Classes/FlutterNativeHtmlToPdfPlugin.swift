import Flutter
import UIKit
import WebKit

public class FlutterNativeHtmlToPdfPlugin: NSObject, FlutterPlugin {
    var wkWebView : WKWebView!
    var urlObservation: NSKeyValueObservation?
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_native_html_to_pdf", binaryMessenger: registrar.messenger())
    let instance = FlutterNativeHtmlToPdfPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
       switch call.method {
       case "convertHtmlToPdf":
           let args = call.arguments as? [String: Any]
           let htmlFilePath = args!["htmlFilePath"] as? String
           
           // !!! this is workaround for issue with rendering PDF images on iOS !!!
           wkWebView = WKWebView.init(frame: CGRect.zero)
           let htmlFileContent = FileHelper.getContent(from: htmlFilePath!) // get html content from file
           wkWebView.loadHTMLString(htmlFileContent, baseURL: Bundle.main.bundleURL) // load html into hidden webview

           urlObservation = wkWebView.observe(\.isLoading, changeHandler: { (webView, change) in
               // this is workaround for issue with loading local images
               DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                   let convertedFileURL = PDFCreator.create(printFormatter: self.wkWebView.viewPrintFormatter())
                   let convertedFilePath = convertedFileURL.absoluteString.replacingOccurrences(of: "file://", with: "") // return generated pdf path

                   // dispose WKWebView
                   self.urlObservation = nil
                   self.wkWebView = nil
                   result(convertedFilePath)
               }
           })
       default:
           result(FlutterMethodNotImplemented)
       }
     }
}
