package com.tencent.liteav.tuikaraoke.ui.utils;

public interface Constants {

    String CMD_REQUEST_TAKE_SEAT = "1";
    String CMD_PICK_UP_SEAT      = "2";
    String CMD_ORDER_SONG        = "3";

    String IMCMD_GIFT = "0"; //礼物消息
    String IMCMD_SELECTED_MUSIC = "selected_music"; //点歌消息

    String IMMSG_KEY_USER_ID = "user_id";
    String IMMSG_KEY_MUSIC_NAME = "music_name";

    /********************* 以下是TUICore通知事件Key ***********************/
    String KARAOKE_MUSIC_EVENT = "KaraokeMusicEvent";
    String KARAOKE_STOP_MUSIC_EVENT = "StopMusicEvent";
    String KARAOKE_ADD_MUSIC_EVENT = "AddMusicEvent";
    String KARAOKE_DELETE_MUSIC_EVENT = "DeleteMusicEvent";
    String KARAOKE_UPDATE_LYRICS_PATH_EVENT = "UpdateLyricsPathEvent";

    /*************** 以下是TUICore通知事件传递参数map用到的Key ***************/
    String KARAOKE_MUSIC_INFO_KEY = "MusicInfoKey";
    String KARAOKE_LYRICS_PATH_KEY = "LyricsPathKey";
}
