package com.wrctech.tecnico

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Canal "tickets": alta prioridad, con sonido y vibración (cartel arriba de la pantalla).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val canal = NotificationChannel(
                "tickets",
                "Tickets",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Avisos de tickets nuevos y cambios de estado"
                enableVibration(true)
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .build(),
                )
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(canal)
        }
    }
}
