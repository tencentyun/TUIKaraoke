package com.tencent.liteav.tuikaraoke.ui.lyric.model;

import java.util.List;

public class LineInfo {
    public String         content;
    public long           start;
    public long           end;
    public long           duration;
    public List<WordInfo> wordList;

    @Override
    public String toString() {
        return "LineInfo{"
                + "content='" + content
                + ", start=" + start
                + ", duration=" + duration
                + '}';
    }
}