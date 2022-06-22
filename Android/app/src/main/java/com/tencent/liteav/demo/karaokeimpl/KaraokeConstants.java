package com.tencent.liteav.demo.karaokeimpl;

public interface KaraokeConstants {
    String KARAOKE_KEY_CMD_VERSION     = "version";
    String KARAOKE_KEY_CMD_BUSINESSID  = "businessID";
    String KARAOKE_KEY_CMD_PLATFORM    = "platform";
    String KARAOKE_KEY_CMD_EXTINFO     = "extInfo";
    String KARAOKE_KEY_CMD_DATA        = "data";
    String KARAOKE_KEY_CMD_ROOMID      = "room_id";
    String KARAOKE_KEY_CMD_CMD         = "cmd";
    String KARAOKE_KEY_CMD_SEATNUMBER  = "seat_number";
    String KARAOKE_KEY_CMD_INSTRUCTION = "instruction";
    String KARAOKE_KEY_CMD_MUSICID     = "music_id";
    String KARAOKE_KEY_CMD_CONTENT     = "content";

    int    KARAOKE_VALUE_CMD_BASIC_VERSION           = 1;
    int    KARAOKE_VALUE_CMD_VERSION                 = 1;
    String KARAOKE_VALUE_CMD_BUSINESSID              = "Karaoke";
    String KARAOKE_VALUE_CMD_PLATFORM                = "Android";
    String KARAOKE_VALUE_CMD_PICK                    = "pickSeat";
    String KARAOKE_VALUE_CMD_TAKE                    = "takeSeat";
    String KARAOKE_VALUE_CMD_INSTRUCTION_MPREPARE    = "m_prepare";
    String KARAOKE_VALUE_CMD_INSTRUCTION_MCOMPLETE   = "m_complete";
    String KARAOKE_VALUE_CMD_INSTRUCTION_MPLAYMUSIC  = "m_play_music";
    String KARAOKE_VALUE_CMD_INSTRUCTION_MSTOP       = "m_stop";
    String KARAOKE_VALUE_CMD_INSTRUCTION_MLISTCHANGE = "m_list_change";
    String KARAOKE_VALUE_CMD_INSTRUCTION_MPICK       = "m_pick";
    String KARAOKE_VALUE_CMD_INSTRUCTION_MDELETE     = "m_delete";
    String KARAOKE_VALUE_CMD_INSTRUCTION_MTOP        = "m_top";
    String KARAOKE_VALUE_CMD_INSTRUCTION_MNEXT       = "m_next";
    String KARAOKE_VALUE_CMD_INSTRUCTION_MGETLIST    = "m_get_list";
    String KARAOKE_VALUE_CMD_INSTRUCTION_MDELETEALL  = "m_delete_all";
}
