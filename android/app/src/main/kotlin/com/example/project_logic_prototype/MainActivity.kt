package com.example.project_logic_prototype

import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "project_logic/sounds"
    private val soundIds = mutableMapOf<String, Int>()
    private lateinit var soundPool: SoundPool
    private val flutterLoader by lazy { FlutterInjector.instance().flutterLoader() }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        soundPool = SoundPool.Builder()
            .setMaxStreams(4)
            .setAudioAttributes(attributes)
            .build()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "preload" -> {
                        val assets = call.argument<List<String>>("assets").orEmpty()
                        assets.forEach(::loadSound)
                        result.success(null)
                    }
                    "play" -> {
                        val asset = call.argument<String>("asset")
                        val volume = call.argument<Double>("volume")?.toFloat() ?: 0.2f
                        if (asset != null) playSound(asset, volume)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun loadSound(asset: String): Int {
        return soundIds.getOrPut(asset) {
            val key = flutterLoader.getLookupKeyForAsset("assets/$asset")
            assets.openFd(key).use { descriptor ->
                soundPool.load(descriptor, 1)
            }
        }
    }

    private fun playSound(asset: String, volume: Float) {
        val soundId = loadSound(asset)
        soundPool.play(soundId, volume, volume, 1, 0, 1f)
    }

    override fun onDestroy() {
        if (::soundPool.isInitialized) soundPool.release()
        super.onDestroy()
    }
}
