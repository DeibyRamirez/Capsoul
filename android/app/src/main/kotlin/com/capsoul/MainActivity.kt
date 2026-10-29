package com.capsoul

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicInteger

/// Canal de avisos de alta importancia y permiso POST_NOTIFICATIONS (Android 13+).
class MainActivity : FlutterActivity() {
    private val secuencia = AtomicInteger(1000)
    private var canalAvisos: MethodChannel? = null
    private var rutaPendiente: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        crearCanalAvisos()
        val lanzamiento = intent?.getStringExtra(EXTRA_RUTA)
        if (!lanzamiento.isNullOrEmpty()) {
            rutaPendiente = lanzamiento
            intent?.removeExtra(EXTRA_RUTA)
        }
        val canal = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL_METODO)
        canalAvisos = canal
        canal.setMethodCallHandler { call, result ->
            when (call.method) {
                "prepararCanal" -> {
                    crearCanalAvisos()
                    result.success(ID_CANAL)
                }
                "sdk" -> result.success(Build.VERSION.SDK_INT)
                "pedirPermiso" -> {
                    pedirPermisoAvisos()
                    result.success(true)
                }
                "mostrar" -> {
                    val titulo = call.argument<String>("titulo") ?: "Capsoul"
                    val cuerpo = call.argument<String>("cuerpo") ?: ""
                    val ruta = call.argument<String>("ruta")
                    mostrarAviso(titulo, cuerpo, ruta)
                    result.success(null)
                }
                "rutaPendiente" -> {
                    val ruta = rutaPendiente
                    rutaPendiente = null
                    result.success(ruta)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val ruta = intent.getStringExtra(EXTRA_RUTA) ?: return
        intent.removeExtra(EXTRA_RUTA)
        canalAvisos?.invokeMethod("abrirRuta", ruta)
    }

    private fun crearCanalAvisos() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val canal = NotificationChannel(
            ID_CANAL,
            "Avisos de Capsoul",
            NotificationManager.IMPORTANCE_HIGH,
        )
        canal.description = "Cápsulas, amistades, legado y retos"
        val administrador = getSystemService(NotificationManager::class.java)
        administrador.createNotificationChannel(canal)
    }

    private fun pedirPermisoAvisos() {
        if (Build.VERSION.SDK_INT < 33) return
        val permiso = Manifest.permission.POST_NOTIFICATIONS
        if (checkSelfPermission(permiso) == PackageManager.PERMISSION_GRANTED) return
        requestPermissions(arrayOf(permiso), CODIGO_PERMISO)
    }

    private fun mostrarAviso(titulo: String, cuerpo: String, ruta: String?) {
        crearCanalAvisos()
        val abrir = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (!ruta.isNullOrEmpty()) putExtra(EXTRA_RUTA, ruta)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val pendiente = PendingIntent.getActivity(this, secuencia.incrementAndGet(), abrir, flags)
        val aviso = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, ID_CANAL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        aviso.setContentTitle(titulo)
            .setContentText(cuerpo)
            .setSmallIcon(applicationInfo.icon)
            .setAutoCancel(true)
            .setContentIntent(pendiente)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            aviso.setPriority(Notification.PRIORITY_HIGH)
        }
        val administrador = getSystemService(NotificationManager::class.java)
        administrador.notify(secuencia.incrementAndGet(), aviso.build())
    }

    companion object {
        const val ID_CANAL = "capsoul_avisos"
        private const val CANAL_METODO = "capsoul/avisos"
        private const val EXTRA_RUTA = "ruta_aviso"
        private const val CODIGO_PERMISO = 4100
    }
}
