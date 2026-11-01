package com.capsoul

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import java.util.concurrent.atomic.AtomicInteger

/** La actividad visible muestra el aviso desde Flutter; en segundo plano lo arma FCM. */
object EstadoPrimerPlano {
    @Volatile
    var activo: Boolean = false
}

data class AccionAviso(val etiqueta: String, val ruta: String)

object AvisoBandeja {
    const val ID_CANAL = "capsoul_avisos"
    const val EXTRA_RUTA = "ruta_aviso"
    const val EXTRA_ID_AVISO = "id_aviso"

    private val secuencia = AtomicInteger(1000)

    fun crearCanal(contexto: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val canal = NotificationChannel(
            ID_CANAL,
            "Avisos de Capsoul",
            NotificationManager.IMPORTANCE_HIGH,
        )
        canal.description = "Cápsulas, amistades, legado y retos"
        contexto.getSystemService(NotificationManager::class.java)
            .createNotificationChannel(canal)
    }

    fun accionesDeSolicitud(datos: Map<String, String>): List<AccionAviso> {
        if (datos["tipo"] != "solicitud_amistad") return emptyList()
        val id = datos["amistad_id"]
        val aceptar = datos["accion_aceptar"]?.takeIf { it.isNotEmpty() }
            ?: id?.let { "capsoul://amigos?accion=aceptar&amistad_id=$it" }
        val rechazar = datos["accion_rechazar"]?.takeIf { it.isNotEmpty() }
            ?: id?.let { "capsoul://amigos?accion=rechazar&amistad_id=$it" }
        val acciones = mutableListOf<AccionAviso>()
        if (!rechazar.isNullOrEmpty()) acciones.add(AccionAviso("Rechazar", rechazar))
        if (!aceptar.isNullOrEmpty()) acciones.add(AccionAviso("Aceptar", aceptar))
        return acciones
    }

    fun mostrar(
        contexto: Context,
        titulo: String,
        cuerpo: String,
        ruta: String?,
        acciones: List<AccionAviso> = emptyList(),
    ) {
        crearCanal(contexto)
        val idAviso = secuencia.incrementAndGet()
        val aviso = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(contexto, ID_CANAL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(contexto)
        }
        aviso.setContentTitle(titulo)
            .setContentText(cuerpo)
            .setStyle(Notification.BigTextStyle().bigText(cuerpo))
            .setSmallIcon(R.drawable.ic_notificacion)
            .setAutoCancel(true)
            .setContentIntent(intentAbrir(contexto, ruta, idAviso))
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            aviso.setPriority(Notification.PRIORITY_HIGH)
        }
        for (accion in acciones) {
            aviso.addAction(accionNativa(contexto, accion, idAviso))
        }
        contexto.getSystemService(NotificationManager::class.java)
            .notify(idAviso, aviso.build())
    }

    private fun accionNativa(
        contexto: Context,
        accion: AccionAviso,
        idAviso: Int,
    ): Notification.Action {
        val pendiente = intentAbrir(contexto, accion.ruta, idAviso)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Notification.Action.Builder(
                android.graphics.drawable.Icon.createWithResource(
                    contexto,
                    R.drawable.ic_notificacion,
                ),
                accion.etiqueta,
                pendiente,
            ).build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Action.Builder(0, accion.etiqueta, pendiente).build()
        }
    }

    private fun intentAbrir(contexto: Context, ruta: String?, idAviso: Int): PendingIntent {
        val abrir = Intent(contexto, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_ID_AVISO, idAviso)
            if (!ruta.isNullOrEmpty()) putExtra(EXTRA_RUTA, ruta)
        }
        val codigo = secuencia.incrementAndGet()
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getActivity(contexto, codigo, abrir, flags)
    }
}

/**
 * Con la app en segundo plano, FCM no llama a Dart si el mensaje trae
 * `notification`. Las solicitudes van solo en `data` para poder poner
 * Aceptar y Rechazar. El resto de avisos lo muestra el sistema.
 */
class ServicioAvisosFcm : FirebaseMessagingService() {
    override fun onMessageReceived(mensaje: RemoteMessage) {
        if (EstadoPrimerPlano.activo) return
        val datos = mensaje.data
        if (datos["tipo"] != "solicitud_amistad") return
        val titulo = datos["titulo"]
            ?: mensaje.notification?.title
            ?: "Nueva solicitud de amistad"
        val cuerpo = datos["cuerpo"]
            ?: mensaje.notification?.body
            ?: "Alguien quiere ser tu amigo en Capsoul."
        val ruta = datos["ruta"] ?: "capsoul://amigos"
        AvisoBandeja.mostrar(
            this,
            titulo,
            cuerpo,
            ruta,
            AvisoBandeja.accionesDeSolicitud(datos),
        )
    }
}
