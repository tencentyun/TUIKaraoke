package com.tencent.liteav.tuikaraoke.model.impl.base;

import com.google.gson.annotations.SerializedName;

public class KaraokeMusicTag {
    @SerializedName("TagId")
    public String id;
    @SerializedName("Name")
    public String name;

    public KaraokeMusicTag(String id, String name) {
        this.id = id;
        this.name = name;
    }

}
