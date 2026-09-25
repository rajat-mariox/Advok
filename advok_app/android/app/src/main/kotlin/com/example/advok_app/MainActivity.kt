package com.example.advok_app

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
        createNotificationChannel()
    }

    /**
     * Push notifications land on this channel (see the FCM meta-data in
     * AndroidManifest.xml and channelId in backend push.service.ts). It is
     * created with sound + high importance so alerts ring and pop up even
     * when the app is closed; FCM's own fallback channel is silent.
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        // Channels from earlier builds (Android keeps a channel's settings
        // once created, so a changed sound needs a new id).
        for (old in listOf("advok_alerts", "advok_alerts_v2", "advok_alerts_v3")) {
            manager.deleteNotificationChannel(old)
        }
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        // The phone's own notification sound (Settings > Sound), so alerts
        // sound like every other app on the device.
        val sound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Alerts",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Bookings, messages, case updates and support replies"
            setSound(sound, attrs)
            enableVibration(true)
            enableLights(true)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val CHANNEL_ID = "advok_alerts_v4"
    }
}
