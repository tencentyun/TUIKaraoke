package com.tencent.liteav.tuikaraoke.ui.lyric.model;

public class WordInfo {
    public long   offset;
    public long   duration;
    public String word;

    @Override
    public String toString() {
        return "WordInfo{"
                + "offset='" + offset
                + ", duration=" + duration
                + ", word=" + word
                + '}';
    }
}