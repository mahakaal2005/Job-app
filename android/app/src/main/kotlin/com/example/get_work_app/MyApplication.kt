package com.example.get_work_app

import android.content.Context
import androidx.multidex.MultiDex
import io.flutter.app.FlutterApplication

class MyApplication : FlutterApplication() {
    
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        // Enable MultiDex for older Android versions (API 19-20)
        MultiDex.install(this)
    }
    
    override fun onCreate() {
        super.onCreate()
        // Initialize any other services here if needed
    }
}
