package com.tencent.liteav.tuikaraoke.ui.gift.imp;

import com.google.gson.annotations.SerializedName;

import java.util.List;

/**
 * 从网络端获取到的礼物数据信息
 */
public class GiftBean {

    private List<GiftListBean> giftList;

    public List<GiftListBean> getGiftList() {
        return giftList;
    }

    public void setGiftList(List<GiftListBean> giftList) {
        this.giftList = giftList;
    }

    public static class GiftListBean {
        /**
         * giftId : 1
         * giftImageUrl : https://8.url.cn/huayang/resource/now/new_gift/1507876472_1
         * lottieUrl : https://assets10.lottiefiles.com/packages/lf20_5NnzkM.json
         * price : 198
         * title : 点赞
         * type : 0
         */

        @SerializedName("giftId")
        private String giftId;
        @SerializedName("giftImageUrl")
        private String giftImageUrl;
        @SerializedName("lottieUrl")
        private String lottieUrl;
        @SerializedName("price")
        private int    price;
        @SerializedName("title")
        private String title;
        @SerializedName("title_en")
        private String titleEn;
        @SerializedName("type")
        private int    type;

        public String getGiftId() {
            return giftId;
        }

        public void setGiftId(String giftId) {
            this.giftId = giftId;
        }

        public String getGiftImageUrl() {
            return giftImageUrl;
        }

        public void setGiftImageUrl(String giftImageUrl) {
            this.giftImageUrl = giftImageUrl;
        }

        public String getLottieUrl() {
            return lottieUrl;
        }

        public void setLottieUrl(String lottieUrl) {
            this.lottieUrl = lottieUrl;
        }

        public int getPrice() {
            return price;
        }

        public void setPrice(int price) {
            this.price = price;
        }

        public String getTitle() {
            return title;
        }

        public void setTitle(String title) {
            this.title = title;
        }

        public String getTitleEn() {
            return titleEn;
        }

        public void setTitleEn(String titleEn) {
            this.titleEn = titleEn;
        }

        public int getType() {
            return type;
        }

        public void setType(int type) {
            this.type = type;
        }
    }
}
