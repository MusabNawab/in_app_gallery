package com.musabnawab.in_app_gallery

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.otaliastudios.transcoder.Transcoder
import com.otaliastudios.transcoder.TranscoderListener
import com.otaliastudios.transcoder.strategy.DefaultAudioStrategy
import com.otaliastudios.transcoder.strategy.DefaultVideoStrategy
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.io.File
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/** InAppGalleryPlugin */
class InAppGalleryPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  private lateinit var channel : MethodChannel
  private lateinit var progressChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null
  private lateinit var context: Context
  private val scope = CoroutineScope(Dispatchers.IO)

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "video_compressor")
    channel.setMethodCallHandler(this)
    
    progressChannel = EventChannel(flutterPluginBinding.binaryMessenger, "video_compressor_progress")
    progressChannel.setStreamHandler(this)
    
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "compressVideo") {
      val inputPath = call.argument<String>("inputPath")
      if (inputPath != null) {
        scope.launch {
          try {
            val outputPath = compressVideoHardware(inputPath)
            withContext(Dispatchers.Main) {
              result.success(outputPath)
            }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              result.error("COMPRESSION_FAILED", e.message, null)
            }
          }
        }
      } else {
        result.error("INVALID_ARGUMENT", "inputPath cannot be null", null)
      }
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    progressChannel.setStreamHandler(null)
    scope.cancel()
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  private suspend fun compressVideoHardware(inputPath: String): String = suspendCancellableCoroutine { cont ->
    val randomLetters = (1..8).map { ('a'..'z').random() }.joinToString("")
    val outputFile = File(context.cacheDir, "compressed_${randomLetters}.mp4")

    val videoStrategy = DefaultVideoStrategy.atMost(720)
        .bitRate(1000000) // 1 Mbps
        .build()

    val audioStrategy = DefaultAudioStrategy.builder()
        .channels(DefaultAudioStrategy.CHANNELS_AS_INPUT)
        .sampleRate(DefaultAudioStrategy.SAMPLE_RATE_AS_INPUT)
        .bitRate(128000) // 128 kbps
        .build()

    val future = Transcoder.into(outputFile.absolutePath)
        .addDataSource(inputPath)
        .setVideoTrackStrategy(videoStrategy)
        .setAudioTrackStrategy(audioStrategy)
        .setListener(object : TranscoderListener {
            override fun onTranscodeProgress(progress: Double) {
                Log.d("VideoCompressor", "Transcode progress: $progress")
                Handler(Looper.getMainLooper()).post {
                    eventSink?.success(progress)
                }
            }

            override fun onTranscodeCompleted(successCode: Int) {
                Log.d("VideoCompressor", "Transcode completed successfully")
                Handler(Looper.getMainLooper()).post {
                    eventSink?.success(1.0)
                }
                if (cont.isActive) {
                    cont.resume(outputFile.absolutePath)
                }
            }

            override fun onTranscodeCanceled() {
                Log.d("VideoCompressor", "Transcode canceled")
                if (cont.isActive) {
                    cont.resumeWithException(CancellationException("Transcode canceled"))
                }
            }

            override fun onTranscodeFailed(exception: Throwable) {
                Log.e("VideoCompressor", "Transcode failed", exception)
                if (cont.isActive) {
                    cont.resumeWithException(exception)
                }
            }
        })
        .transcode()

    cont.invokeOnCancellation {
        future.cancel(true)
    }
  }
}
