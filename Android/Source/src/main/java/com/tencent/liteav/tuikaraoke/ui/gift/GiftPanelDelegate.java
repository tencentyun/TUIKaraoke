package com.tencent.liteav.tuikaraoke.ui.gift;


import com.tencent.liteav.tuikaraoke.ui.gift.imp.GiftInfo;

public interface GiftPanelDelegate {
    /**
     * 礼物点击事件
     */
    void onGiftItemClick(GiftInfo giftInfo);

    /**
     * 充值点击事件
     */
    void onChargeClick();
}
