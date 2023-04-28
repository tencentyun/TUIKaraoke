package com.tencent.liteav.tuikaraoke.ui.utils;

import android.content.Context;
import android.media.AudioDeviceInfo;
import android.media.AudioManager;
import android.os.Build;

public class Utils {
    public static boolean checkHasHeadset(Context context) {
        AudioManager audioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            AudioDeviceInfo[] devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS);
            for (AudioDeviceInfo device : devices) {
                int deviceType = device.getType();
                if (deviceType == AudioDeviceInfo.TYPE_WIRED_HEADSET
                        || deviceType == AudioDeviceInfo.TYPE_WIRED_HEADPHONES
                        || deviceType == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP
                        || deviceType == AudioDeviceInfo.TYPE_BLUETOOTH_SCO) {
                    return true;
                }
            }
        } else {
            return audioManager.isWiredHeadsetOn()
                    || audioManager.isBluetoothScoOn()
                    || audioManager.isBluetoothA2dpOn();
        }
        return false;
    }
}
