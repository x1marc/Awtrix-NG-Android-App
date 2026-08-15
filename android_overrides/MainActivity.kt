package com.x1marc.awtrix_ng_remote

import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.autofill.AutofillManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // MIUI / HyperOS (Xiaomi/Redmi) legt über das Autofill-Framework einen
    // grauen Balken in die Eingabefelder. Unter Android 14 wird
    // importantForAutofill im onCreate teils ignoriert, darum setzen wir es
    // mehrfach im Lifecycle (auch bei Fokuswechsel) und brechen laufende
    // Autofill-Sessions ab.
    private fun killAutofill() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            window.decorView.importantForAutofill =
                View.IMPORTANT_FOR_AUTOFILL_NO_EXCLUDE_DESCENDANTS
            try {
                getSystemService(AutofillManager::class.java)?.cancel()
            } catch (_: Throwable) {
                // ignorieren – nicht kritisch
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        killAutofill()
    }

    override fun onResume() {
        super.onResume()
        killAutofill()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) killAutofill()
    }
}
