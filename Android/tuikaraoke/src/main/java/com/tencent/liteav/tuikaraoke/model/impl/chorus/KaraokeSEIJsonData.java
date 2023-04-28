package com.tencent.liteav.tuikaraoke.model.impl.chorus;

import com.google.gson.annotations.SerializedName;

public class KaraokeSEIJsonData {

    /**
     * current_time : 0
     * music_id : 1002
     * total_time : 269.793
     */
    @SerializedName("current_time")
    private long currentTime;

    @SerializedName("music_id")
    private int musicId;

    @SerializedName("total_time")
    private long totalTime;

    @SerializedName("is_origin_music")
    private boolean isOriginMusic;

    public long getCurrentTime() {
        return currentTime;
    }

    public void setCurrentTime(long currentTime) {
        this.currentTime = currentTime;
    }

    public int getMusicId() {
        return musicId;
    }

    public void setMusicId(int musicId) {
        this.musicId = musicId;
    }

    public long getTotalTime() {
        return totalTime;
    }

    public void setTotalTime(long totalTime) {
        this.totalTime = totalTime;
    }


    public boolean getIsOriginMusic() {
        return isOriginMusic;
    }

    public void setIsOriginMusic(boolean isOriginMusic) {
        this.isOriginMusic = isOriginMusic;
    }

}
