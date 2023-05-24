package com.tencent.liteav.tuikaraoke.model.impl.base;

import com.google.gson.annotations.SerializedName;

import java.util.ArrayList;
import java.util.List;

public class KTVMusicInfoSet {
    @SerializedName(value = "ktvMusicInfoSet", alternate = {"musicInfo"})
    public List<KTVMusicInfo> musicInfoList = new ArrayList<>();
    @SerializedName("scrollToken")
    public String             scrollToken   = "";


    public static class KTVMusicInfo {
        @SerializedName("MusicId")
        public String musicId  = "";
        @SerializedName("Name")
        public String name     = "";
        @SerializedName("Duration")
        public int    duration = 0;

        @SerializedName("AlbumInfo")
        public AlbumInfo    albumInfo  = new AlbumInfo();
        @SerializedName("SingerSet")
        public List<String> singerList = new ArrayList<>();
        @SerializedName("AlbumInfoCoverUrl")
        public String       albumInfoCoverUrl;    //歌曲封面("copyright"歌曲的字段)
    }


    public static class AlbumInfo {
        @SerializedName("CoverInfoSet")
        public List<CoverInfo> coverInfoSet = new ArrayList<>();
    }


    public static class CoverInfo {
        @SerializedName("Dimension")
        public String dimension = "";
        @SerializedName("Url")
        public String url       = "";
    }
}

