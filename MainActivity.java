package com.local.nativesettings;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;

/**
 * A tiny trampoline: it shows up in the TV home screen as a normal app tile
 * (it declares MAIN + LAUNCHER), and tapping it forwards to the stock
 * AOSP Settings app, which on many TV firmwares has no launcher entry of
 * its own and therefore never shows up in a home screen.
 */
public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Intent forward = new Intent();
        forward.setComponent(new ComponentName("com.android.settings", "com.android.settings.Settings"));
        forward.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        try {
            startActivity(forward);
        } catch (Exception e) {
            // Fall back to the plain settings action if the component is missing.
            Intent fallback = new Intent(android.provider.Settings.ACTION_SETTINGS);
            fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            try {
                startActivity(fallback);
            } catch (Exception ignored) {
            }
        }
        finish();
    }
}
