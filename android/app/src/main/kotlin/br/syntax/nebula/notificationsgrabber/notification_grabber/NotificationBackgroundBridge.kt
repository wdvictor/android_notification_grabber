package br.syntax.nebula.notificationsgrabber.notification_grabber

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

object NotificationBackgroundBridge {
    const val actionOfflineNotificationsChanged =
        "br.syntax.nebula.notificationsgrabber.notification_grabber.OFFLINE_NOTIFICATIONS_CHANGED"

    private const val channelName = "notification_grabber/platform"
    private const val backgroundReadyTimeoutMs = 30000L
    private const val invocationTimeoutMs = 300000L
    private const val tag = "NotificationBridge"
    private val ignoredPackageTerms = listOf("whatsapp", "android", "samsung", "google")
    private val mainHandler = Handler(Looper.getMainLooper())

    val executor: ExecutorService = Executors.newSingleThreadExecutor()

    @Volatile
    private var applicationContext: Context? = null

    @Volatile
    private var backgroundEngine: FlutterEngine? = null

    @Volatile
    private var backgroundChannel: MethodChannel? = null

    @Volatile
    private var backgroundReady = false

    @Volatile
    private var readyLatch: CountDownLatch? = null

    private val engineLock = Any()

    fun shouldIgnorePackage(context: Context, packageName: String): Boolean {
        if (packageName == context.packageName) {
            return true
        }

        return ignoredPackageTerms.any { term ->
            packageName.contains(term, ignoreCase = true)
        }
    }

    fun processCapturedNotification(context: Context, app: String, text: String) {
        executor.execute {
            try {
                invokeBlocking(
                    context = context,
                    method = "processCapturedNotification",
                    arguments = mapOf("app" to app, "text" to text),
                )
            } catch (error: Throwable) {
                Log.e(tag, "Falha ao processar notificacao capturada.", error)
            }
        }
    }

    fun getOfflineNotifications(context: Context): List<Map<Any?, Any?>> {
        val result = invokeBlocking(context, "getOfflineNotifications", null)
        val values = result as? List<*> ?: return emptyList()
        return values.mapNotNull { value ->
            @Suppress("UNCHECKED_CAST")
            value as? Map<Any?, Any?>
        }
    }

    fun retryOfflineNotification(context: Context, id: String): Map<Any?, Any?> {
        val result = invokeBlocking(
            context = context,
            method = "retryOfflineNotification",
            arguments = mapOf("id" to id),
        )

        @Suppress("UNCHECKED_CAST")
        return result as? Map<Any?, Any?> ?: emptyMap<Any?, Any?>()
    }

    fun retryAllOfflineNotifications(context: Context): Map<Any?, Any?> {
        val result = invokeBlocking(context, "retryAllOfflineNotifications", null)

        @Suppress("UNCHECKED_CAST")
        return result as? Map<Any?, Any?> ?: emptyMap<Any?, Any?>()
    }

    private fun invokeBlocking(context: Context, method: String, arguments: Any?): Any? {
        check(Looper.myLooper() != Looper.getMainLooper()) {
            "invokeBlocking nao pode ser chamado na main thread."
        }

        val channel = ensureChannel(context)
        awaitBackgroundReady()

        val completionLatch = CountDownLatch(1)
        var value: Any? = null
        var error: ChannelInvocationError? = null
        var isNotImplemented = false

        runOnMainThreadBlocking("encaminhar $method ao processador Flutter") {
            channel.invokeMethod(method, arguments, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    value = result
                    completionLatch.countDown()
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    error = ChannelInvocationError(errorCode, errorMessage)
                    completionLatch.countDown()
                }

                override fun notImplemented() {
                    isNotImplemented = true
                    completionLatch.countDown()
                }
            })
        }

        if (!completionLatch.await(invocationTimeoutMs, TimeUnit.MILLISECONDS)) {
            throw IllegalStateException("Tempo esgotado ao invocar $method no processador Flutter.")
        }

        if (isNotImplemented) {
            throw IllegalStateException("Método Flutter não implementado: $method")
        }

        error?.let { failure ->
            throw IllegalStateException(failure.message ?: failure.code)
        }

        return value
    }

    private fun ensureChannel(context: Context): MethodChannel {
        backgroundChannel?.let { return it }

        val appContext = context.applicationContext
        applicationContext = appContext

        return runOnMainThreadBlocking("inicializar o FlutterEngine em background") {
            synchronized(engineLock) {
                backgroundChannel?.let { return@synchronized it }

                val flutterLoader = FlutterInjector.instance().flutterLoader()
                flutterLoader.startInitialization(appContext)
                flutterLoader.ensureInitializationComplete(appContext, null)

                val engine = FlutterEngine(appContext)
                GeneratedPluginRegistrant.registerWith(engine)

                val channel = MethodChannel(engine.dartExecutor.binaryMessenger, channelName)
                channel.setMethodCallHandler(::handleBackgroundMethodCall)

                backgroundReady = false
                readyLatch = CountDownLatch(1)
                backgroundEngine = engine
                backgroundChannel = channel

                val entrypoint = DartExecutor.DartEntrypoint(
                    flutterLoader.findAppBundlePath(),
                    "notificationBackgroundMain",
                )
                engine.dartExecutor.executeDartEntrypoint(entrypoint)

                channel
            }
        }
    }

    private fun awaitBackgroundReady() {
        if (backgroundReady) {
            return
        }

        val latch = readyLatch
            ?: throw IllegalStateException("Processador Flutter não inicializado.")

        if (!latch.await(backgroundReadyTimeoutMs, TimeUnit.MILLISECONDS)) {
            throw IllegalStateException("Tempo esgotado ao inicializar o processador Flutter.")
        }
    }

    private fun handleBackgroundMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "backgroundProcessorReady" -> {
                backgroundReady = true
                readyLatch?.countDown()
                result.success(null)
            }

            "getApiKey" -> result.success(BuildConfig.X_API_KEY)

            "getBackendBaseUrl" -> result.success(BuildConfig.BACKEND_BASE_URL)

            "broadcastOfflineNotificationsChanged" -> {
                val context = applicationContext
                if (context != null) {
                    broadcastOfflineNotificationsChanged(context)
                }
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun broadcastOfflineNotificationsChanged(context: Context) {
        context.sendBroadcast(Intent(actionOfflineNotificationsChanged).setPackage(context.packageName))
    }

    private fun <T> runOnMainThreadBlocking(operation: String, block: () -> T): T {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            return block()
        }

        val completionLatch = CountDownLatch(1)
        var value: T? = null
        var failure: Throwable? = null

        mainHandler.post {
            try {
                value = block()
            } catch (error: Throwable) {
                failure = error
            } finally {
                completionLatch.countDown()
            }
        }

        if (!completionLatch.await(backgroundReadyTimeoutMs, TimeUnit.MILLISECONDS)) {
            throw IllegalStateException("Tempo esgotado ao $operation.")
        }

        failure?.let { throw it }

        @Suppress("UNCHECKED_CAST")
        return value as T
    }

    private data class ChannelInvocationError(
        val code: String,
        val message: String?,
    )
}
