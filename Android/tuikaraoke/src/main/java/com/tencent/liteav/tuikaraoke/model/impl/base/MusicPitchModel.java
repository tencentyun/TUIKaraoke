package com.tencent.liteav.tuikaraoke.model.impl.base;

public class MusicPitchModel {
    public long startTime = 0;
    public long duration = 0;
    public int pitch = 0;

    public MusicPitchModel(long startTime, long duration, int pitch) {
        this.startTime = startTime;
        this.duration = duration;
        this.pitch = pitch;
    }
}
