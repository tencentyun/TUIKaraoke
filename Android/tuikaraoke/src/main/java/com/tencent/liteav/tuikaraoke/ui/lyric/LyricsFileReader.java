package com.tencent.liteav.tuikaraoke.ui.lyric;

import android.util.Log;

import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.ui.lyric.model.LineInfo;
import com.tencent.liteav.tuikaraoke.ui.lyric.model.LyricInfo;
import com.tencent.liteav.tuikaraoke.ui.lyric.model.WordInfo;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class LyricsFileReader {
    protected static final String TAG = "LyricsFileReader";

    public LyricInfo parseLyricInfo(String path) throws Exception {
        File lyricFile = new File(path);
        if (lyricFile == null || !lyricFile.exists() || lyricFile.length() == 0) {
            return null;
        }

        InputStream in = new FileInputStream(lyricFile);

        LyricInfo lyricInfo = new LyricInfo();
        List<LineInfo> lineList = new ArrayList<>();
        lyricInfo.lineList = lineList;

        if (in != null) {
            String lyricTimeLineString = "";
            BufferedReader reader = new BufferedReader(new InputStreamReader(in));
            while ((lyricTimeLineString = reader.readLine()) != null) {
                Pattern timePattern = Pattern.compile("(\\d{2}):(\\d{2}):(\\d{2}).(\\d{3})");
                Matcher timeMatcher = timePattern.matcher(lyricTimeLineString);
                if (timeMatcher.find()) {
                    LineInfo lyricsLineInfo = new LineInfo();

                    parserLyricTimeLine(lyricTimeLineString, lyricsLineInfo);

                    String lyricString = reader.readLine();
                    parserLyricWords(lyricString, lyricsLineInfo);

                    lineList.add(lyricsLineInfo);
                }
            }
            in.close();
        }
        return lyricInfo;
    }


    private void parserLyricTimeLine(String lineString, LineInfo lineInfo) {
        String[] lineTimes = lineString.split(" --> "); // 分割字符串

        lineInfo.start = dateToMilliseconds(lineTimes[0]);
        lineInfo.end = dateToMilliseconds(lineTimes[1]);
        lineInfo.duration = lineInfo.end - lineInfo.start;
    }

    private void parserLyricWords(String lineString, LineInfo lineInfo) {

        Pattern pattern = Pattern.compile("\\<(\\d+),(\\d+),(\\d+)\\>");
        Matcher matcher = pattern.matcher(lineString);

        String[] words = lineString.split("\\<\\d+,\\d+,\\d+\\>", -1);
        int index = 0;

        List<WordInfo> wordInfoList = new ArrayList<>();
        StringBuilder content = new StringBuilder("");

        while (matcher.find()) {
            WordInfo wordInfo = new WordInfo();
            wordInfo.offset = Long.parseLong(matcher.group(1));
            wordInfo.duration = Long.parseLong(matcher.group(2));
            wordInfo.word = words[++index];
            content = content.append(wordInfo.word);
            wordInfoList.add(wordInfo);
        }
        lineInfo.wordList = wordInfoList;
        lineInfo.content = content.toString();

        if (index != words.length) {
            TRTCLogger.e(TAG, "lyric line parsing error, times length not equal to words，line：" + lineString);
        }
    }

    private long dateToMilliseconds(String inputString) {
        long milliseconds = -1;
        Pattern pattern = Pattern.compile("(\\d{2}):(\\d{2}):(\\d{2}).(\\d{3})");
        Matcher matcher = pattern.matcher(inputString);
        if (matcher.matches()) {
            milliseconds = Long.parseLong(matcher.group(1)) * 3600000L
                    + Long.parseLong(matcher.group(2)) * 60000
                    + Long.parseLong(matcher.group(3)) * 1000
                    + Long.parseLong(matcher.group(4));
        } else {
            Log.e(TAG, " date to milliseconds error, inputString: " + inputString);
        }

        return milliseconds;
    }

}
