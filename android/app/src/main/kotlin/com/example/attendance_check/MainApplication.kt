package com.example.attendance_check

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setLocale("ru_RU")
        // Ключ задаётся в android/local.properties: yandex.mapkit.apiKey=...
        MapKitFactory.setApiKey(BuildConfig.YANDEX_MAPKIT_API_KEY)
    }
}
