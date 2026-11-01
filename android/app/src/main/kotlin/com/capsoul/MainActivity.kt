package com.capsoul

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Canal de avisos de alta importancia y permiso POST_NOTIFICATIONS (Android 13+).
class MainActivity : FlutterActivity() {
    private var canalAvisos: MethodChannel? = null
    private var rutaPendiente: String? = null

    override fun onStart() {
        super.onStart()
        EstadoPrimerPlano.activo = true
    }

    override fun onStop() {
        EstadoPrimerPlano.activo = false
        super.onStop()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AvisoBandeja.crearCanal(this)
        consumirRuta(intent)
        val canal = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL_METODO)
        canalAvisos = canal
        canal.setMethodCallHandler { call, result ->
            when (call.method) {
                "prepararCanal" -> {
                    AvisoBandeja.crearCanal(this)
                    result.success(AvisoBandeja.ID_CANAL)
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
                    val acciones = accionesDesde(call.argument<List<*>>("acciones"))
                    AvisoBandeja.mostrar(this, titulo, cuerpo, ruta, acciones)
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
        val ruta = consumirRuta(intent) ?: return
        canalAvisos?.invokeMethod("abrirRuta", ruta)
    }

    private fun consumirRuta(origen: Intent?): String? {
        val idAviso = origen?.getIntExtra(AvisoBandeja.EXTRA_ID_AVISO, -1) ?: -1
        if (idAviso >= 0) {
            getSystemService(NotificationManager::class.java).cancel(idAviso)
            origen?.removeExtra(AvisoBandeja.EXTRA_ID_AVISO)
        }
        val ruta = origen?.getStringExtra(AvisoBandeja.EXTRA_RUTA)
        if (ruta.isNullOrEmpty()) return null
        origen.removeExtra(AvisoBandeja.EXTRA_RUTA)
        if (canalAvisos == null) {
            rutaPendiente = ruta
        }
        return ruta
    }

    private fun accionesDesde(crudas: List<*>?): List<AccionAviso> {
        if (crudas == null) return emptyList()
        val acciones = mutableListOf<AccionAviso>()
        for (item in crudas) {
            val mapa = item as? Map<*, *> ?: continue
            val etiqueta = mapa["etiqueta"] as? String ?: continue
            val ruta = mapa["ruta"] as? String ?: continue
            if (etiqueta.isEmpty() || ruta.isEmpty()) continue
            acciones.add(AccionAviso(etiqueta, ruta))
        }
        return acciones
    }

    private fun pedirPermisoAvisos() {
        if (Build.VERSION.SDK_INT < 33) return
        val permiso = Manifest.permission.POST_NOTIFICATIONS
        if (checkSelfPermission(permiso) == PackageManager.PERMISSION_GRANTED) return
        requestPermissions(arrayOf(permiso), CODIGO_PERMISO)
    }

    companion object {
        private const val CANAL_METODO = "capsoul/avisos"
        private const val CODIGO_PERMISO = 4100
    }
}
