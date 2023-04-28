package com.tencent.liteav.tuikaraoke.model.impl.base;

public class KaraokeResponse<T> {
    public int    errorCode;
    public String errorMessage;
    public T      data;
    public String requestId;
}
