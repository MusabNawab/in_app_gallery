import Flutter
import UIKit
import AVFoundation

public class InAppGalleryPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "video_compressor", binaryMessenger: registrar.messenger())
    let progressChannel = FlutterEventChannel(name: "video_compressor_progress", binaryMessenger: registrar.messenger())
    
    let instance = InAppGalleryPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    progressChannel.setStreamHandler(instance)
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "compressVideo" {
        guard let args = call.arguments as? [String: Any],
              let inputPath = args["inputPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "inputPath is missing", details: nil))
            return
        }
        
        compressVideo(inputPath: inputPath) { outputPath, error in
            if let error = error {
                result(FlutterError(code: "COMPRESSION_FAILED", message: error.localizedDescription, details: nil))
            } else if let outputPath = outputPath {
                result(outputPath)
            } else {
                result(FlutterError(code: "UNKNOWN_ERROR", message: "Compression failed without specific error", details: nil))
            }
        }
    } else if call.method == "getPlatformVersion" {
      result("iOS " + UIDevice.current.systemVersion)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func compressVideo(inputPath: String, completion: @escaping (String?, Error?) -> Void) {
      let inputURL = URL(fileURLWithPath: inputPath)
      let asset = AVAsset(url: inputURL)
      
      // Create output URL in temp directory
      let tempDir = NSTemporaryDirectory()
      let randomLetters = String((0..<8).map { _ in "abcdefghijklmnopqrstuvwxyz".randomElement()! })
      let fileName = "compressed_\(randomLetters).mp4"
      let outputURL = URL(fileURLWithPath: tempDir).appendingPathComponent(fileName)
      
      // Remove existing file if it exists
      if FileManager.default.fileExists(atPath: outputURL.path) {
          do {
              try FileManager.default.removeItem(at: outputURL)
          } catch {
              completion(nil, error)
              return
          }
      }
      
      guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
          completion(nil, NSError(domain: "VideoCompressor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAssetExportSession"]))
          return
      }
      
      exportSession.outputURL = outputURL
      exportSession.outputFileType = .mp4
      exportSession.shouldOptimizeForNetworkUse = true // Helps with fast start streaming
      
      var timer: Timer?
      DispatchQueue.main.async {
          timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
              self.eventSink?(Double(exportSession.progress))
          }
      }
      
      exportSession.exportAsynchronously {
          DispatchQueue.main.async {
              timer?.invalidate()
              switch exportSession.status {
              case .completed:
                  self.eventSink?(1.0) // Ensure we push 100% at the end
                  completion(outputURL.path, nil)
              case .failed:
                  completion(nil, exportSession.error)
              case .cancelled:
                  completion(nil, NSError(domain: "VideoCompressor", code: -2, userInfo: [NSLocalizedDescriptionKey: "Compression cancelled"]))
              default:
                  completion(nil, NSError(domain: "VideoCompressor", code: -3, userInfo: [NSLocalizedDescriptionKey: "Unknown compression status"]))
              }
          }
      }
  }
}
