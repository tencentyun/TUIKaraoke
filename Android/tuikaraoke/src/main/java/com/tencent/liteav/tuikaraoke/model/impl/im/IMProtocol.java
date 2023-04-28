package com.tencent.liteav.tuikaraoke.model.impl.im;

import static com.tencent.liteav.tuikaraoke.model.impl.im.IMProtocol.Define.CODE_ROOM_CUSTOM_MSG;
import static com.tencent.liteav.tuikaraoke.model.impl.im.IMProtocol.Define.CODE_ROOM_DESTROY;
import static com.tencent.liteav.tuikaraoke.model.impl.im.IMProtocol.Define.KEY_ATTR_VERSION;
import static com.tencent.liteav.tuikaraoke.model.impl.im.IMProtocol.Define.KEY_CMD_ACTION;
import static com.tencent.liteav.tuikaraoke.model.impl.im.IMProtocol.Define.KEY_CMD_VERSION;
import static com.tencent.liteav.tuikaraoke.model.impl.im.IMProtocol.Define.KEY_ROOM_INFO;
import static com.tencent.liteav.tuikaraoke.model.impl.im.IMProtocol.Define.KEY_SEAT;
import static com.tencent.liteav.tuikaraoke.model.impl.im.IMProtocol.Define.VALUE_ATTR_VERSION;
import static com.tencent.liteav.tuikaraoke.model.impl.im.IMProtocol.Define.VALUE_CMD_VERSION;

import android.text.TextUtils;
import android.util.Pair;

import com.google.gson.Gson;
import com.google.gson.JsonSyntaxException;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class IMProtocol {
    private static final String TAG = IMProtocol.class.getName();


    public static class Define {
        public static final String KEY_ATTR_VERSION   = "version";
        public static final String VALUE_ATTR_VERSION = "1.0";
        public static final String KEY_ROOM_INFO      = "roomInfo";
        public static final String KEY_SEAT           = "seat";

        public static final String KEY_CMD_VERSION   = "version";
        public static final String VALUE_CMD_VERSION = "1.0";
        public static final String KEY_CMD_ACTION    = "action";


        public static final int CODE_UNKNOWN         = 0;
        public static final int CODE_ROOM_DESTROY    = 200;
        public static final int CODE_ROOM_CUSTOM_MSG = 301;
    }

    public static class SignallingDefine {
        public static String KEY_VERSION     = "version";
        public static String KEY_BUSINESS_ID = "businessID";
        public static String KEY_DATA        = "data";
        public static String KEY_ROOM_ID     = "room_id";
        public static String KEY_CMD         = "cmd";
        public static String KEY_SEAT_NUMBER = "seat_number";
        public static String KEY_INSTRUCTION = "instruction";
        public static String KEY_CONTENT     = "content";
        public static String KEY_MUSICID     = "music_id";
        public static String KEY_PLATFORM    = "platform";


        public static final int    VALUE_VERSION     = 1;
        public static final String VALUE_BUSINESS_ID = "Karaoke"; //Ktv场景
        public static final String VALUE_PLATFORM    = "Android";   //当前平台
    }

    public static HashMap<String, String> getInitRoomMap(TRTCKaraokeRoomDef.RoomInfo roomInfo,
                                                         List<TRTCKaraokeRoomDef.SeatInfo> seatInfoList) {
        Gson gson = new Gson();
        HashMap<String, String> jsonMap = new HashMap<>();
        jsonMap.put(KEY_ATTR_VERSION, VALUE_ATTR_VERSION);
        jsonMap.put(KEY_ROOM_INFO, gson.toJson(roomInfo));
        for (int i = 0; i < seatInfoList.size(); i++) {
            String json = gson.toJson(seatInfoList.get(i), TRTCKaraokeRoomDef.SeatInfo.class);
            jsonMap.put(KEY_SEAT + i, json);
        }
        return jsonMap;
    }

    public static HashMap<String, String> getSeatInfoListJsonStr(List<TRTCKaraokeRoomDef.SeatInfo> txSeatInfoList) {
        Gson gson = new Gson();
        HashMap<String, String> jsonMap = new HashMap<>();
        for (int i = 0; i < txSeatInfoList.size(); i++) {
            String json = gson.toJson(txSeatInfoList.get(i), TRTCKaraokeRoomDef.SeatInfo.class);
            jsonMap.put(KEY_SEAT + i, json);
        }
        return jsonMap;
    }

    public static HashMap<String, String> getSeatInfoJsonStr(int index, TRTCKaraokeRoomDef.SeatInfo info) {
        Gson gson = new Gson();
        String json = gson.toJson(info, TRTCKaraokeRoomDef.SeatInfo.class);
        HashMap<String, String> map = new HashMap<>();
        map.put(KEY_SEAT + index, json);
        return map;
    }

    public static TRTCKaraokeRoomDef.RoomInfo getRoomInfoFromAttr(Map<String, String> map) {
        TRTCKaraokeRoomDef.RoomInfo txRoomInfo;
        Gson gson = new Gson();
        String json = map.get(KEY_ROOM_INFO);
        if (TextUtils.isEmpty(json)) {
            return null;
        }
        try {
            txRoomInfo = gson.fromJson(json, TRTCKaraokeRoomDef.RoomInfo.class);
        } catch (Exception e) {
            TRTCLogger.e(TAG, "parse room info json error! " + json);
            txRoomInfo = null;
        }
        return txRoomInfo;
    }

    public static List<TRTCKaraokeRoomDef.SeatInfo> getSeatListFromAttr(Map<String, String> map, int seatSize) {
        Gson gson = new Gson();
        List<TRTCKaraokeRoomDef.SeatInfo> txSeatInfoList = new ArrayList<>();
        for (int i = 0; i < seatSize; i++) {
            String json = map.get(KEY_SEAT + i);
            TRTCKaraokeRoomDef.SeatInfo txSeatInfo;
            if (TextUtils.isEmpty(json)) {
                txSeatInfo = new TRTCKaraokeRoomDef.SeatInfo();
            } else {
                try {
                    txSeatInfo = gson.fromJson(json, TRTCKaraokeRoomDef.SeatInfo.class);
                } catch (Exception e) {
                    TRTCLogger.e(TAG, "parse seat info json error! " + json);
                    txSeatInfo = new TRTCKaraokeRoomDef.SeatInfo();
                }
            }
            txSeatInfoList.add(txSeatInfo);
        }
        return txSeatInfoList;
    }

    public static SignallingData convert2SignallingData(String json) {
        SignallingData signallingData = new SignallingData();
        Map<String, Object> extraMap;
        try {
            extraMap = new Gson().fromJson(json, Map.class);
            if (extraMap == null) {
                TRTCLogger.e(TAG, " extraMap is null, ignore");
                return signallingData;
            }
            if (extraMap.containsKey(SignallingDefine.KEY_VERSION)) {
                Object version = extraMap.get(SignallingDefine.KEY_VERSION);
                if (version instanceof Double) {
                    signallingData.setVersion(((Double) version).intValue());
                } else {
                    TRTCLogger.e(TAG, "version is not int, value is :" + version);
                }
            }

            if (extraMap.containsKey(SignallingDefine.KEY_BUSINESS_ID)) {
                Object businessId = extraMap.get(SignallingDefine.KEY_BUSINESS_ID);
                if (businessId instanceof String) {
                    signallingData.setBusinessID((String) businessId);
                } else {
                    TRTCLogger.e(TAG, "businessId is not string, value is :" + businessId);
                }
            }

            if (extraMap.containsKey(SignallingDefine.KEY_DATA)) {
                Object dataMapObj = extraMap.get(SignallingDefine.KEY_DATA);
                if (dataMapObj != null && dataMapObj instanceof Map) {
                    Map<String, Object> dataMap = (Map<String, Object>) dataMapObj;
                    SignallingData.DataInfo dataInfo = convert2DataInfo(dataMap);
                    signallingData.setData(dataInfo);
                } else {
                    TRTCLogger.e(TAG, "dataMapObj is not map, value is :" + dataMapObj);
                }
            }
        } catch (JsonSyntaxException e) {
            TRTCLogger.i(TAG, "convert2SignallingData json parse error");
        }
        return signallingData;
    }

    private static SignallingData.DataInfo convert2DataInfo(Map<String, Object> dataMap) {
        SignallingData.DataInfo dataInfo = new SignallingData.DataInfo();
        try {
            if (dataMap.containsKey(SignallingDefine.KEY_CMD)) {
                Object cmd = dataMap.get(SignallingDefine.KEY_CMD);
                if (cmd instanceof String) {
                    dataInfo.setCmd((String) cmd);
                } else {
                    TRTCLogger.e(TAG, "cmd is not string, value is :" + cmd);
                }
            }
            if (dataMap.containsKey(SignallingDefine.KEY_ROOM_ID)) {
                Object roomId = dataMap.get(SignallingDefine.KEY_ROOM_ID);
                if (roomId instanceof Double) {
                    dataInfo.setRoomID(((Double) roomId).intValue());
                } else {
                    TRTCLogger.e(TAG, "roomId is not Double, value is :" + roomId);
                }
            }
            if (dataMap.containsKey(SignallingDefine.KEY_SEAT_NUMBER)) {
                Object seatNumber = dataMap.get(SignallingDefine.KEY_SEAT_NUMBER);
                if (seatNumber instanceof String) {
                    dataInfo.setSeatNumber((String) seatNumber);
                } else {
                    TRTCLogger.e(TAG, "seatNumber is not string, value is :" + seatNumber);
                }
            }
        } catch (JsonSyntaxException e) {
            TRTCLogger.e(TAG, "onReceiveNewInvitation JsonSyntaxException:" + e);
        }
        return dataInfo;
    }

    public static String getRoomDestroyMsg() {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put(KEY_CMD_VERSION, VALUE_CMD_VERSION);
            jsonObject.put(KEY_CMD_ACTION, CODE_ROOM_DESTROY);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsonObject.toString();
    }

    public static String getCusMsgJsonStr(String cmd, String msg) {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put(KEY_ATTR_VERSION, VALUE_ATTR_VERSION);
            jsonObject.put(KEY_CMD_ACTION, CODE_ROOM_CUSTOM_MSG);
            jsonObject.put("command", cmd);
            jsonObject.put("message", msg);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsonObject.toString();
    }

    public static Pair<String, String> parseCusMsg(JSONObject jsonObject) {
        String cmd = jsonObject.optString("command");
        String message = jsonObject.optString("message");
        return new Pair<>(cmd, message);
    }
}
