package com.tencent.liteav.tuikaraoke.ui.floatwindow;

import android.content.Context;
import android.graphics.PixelFormat;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;

import com.tencent.liteav.basic.ImageLoader;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoom;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomCallback;
import com.tencent.liteav.tuikaraoke.ui.room.AudienceRoomEntity;
import com.tencent.liteav.tuikaraoke.ui.room.KaraokeRoomAudienceActivity;
import com.tencent.liteav.tuikaraoke.ui.widget.RoundCornerImageView;

import java.lang.reflect.Method;

public class FloatWindow implements IFloatWindowCallback {
    private static final String TAG = "FloatWindow";

    private Context                    mContext;
    private AudienceRoomEntity         mEntity;
    private View                       mRootView;
    private RoundCornerImageView       mImgCover;
    private RoundCornerImageView       mImgSpeaker;
    private RoundCornerImageView       mImgClose;
    private WindowManager              mWindowManager;
    private WindowManager.LayoutParams mLayoutParams;
    private TRTCKaraokeRoom            mTRTCKaraokeRoom;

    private float   startX;   //最开始点击的X坐标
    private float   startY;   //最开始点击的Y坐标
    private float   curX;     //X坐标
    private float   curY;     //Y坐标
    private boolean isMove;
    private OnClick onClick;  //点击事件接口
    private boolean mIsPlay;

    private static FloatWindow sInstance;
    public static  boolean     mIsShowing       = false; //悬浮窗是否显示
    public static  boolean     mIsDestroyByself = false; //悬浮窗是否自己关闭

    public String mRoomUrl = "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover1.png";

    public synchronized static FloatWindow getInstance() {
        if (sInstance == null) {
            sInstance = new FloatWindow();
        }
        return sInstance;
    }

    @Override
    public void onAppBackground(boolean isBackground) {
        Log.d(TAG, "onAppBackground: isBackground = " + isBackground);
        if (isBackground) {
            hide();
        } else {
            show();
        }
    }

    public void createDemoApplication(Context context, IFloatWindowCallback callback) {
        try {
            Class  clz    = Class.forName("com.tencent.liteav.demo.DemoApplication");
            Method method = clz.getMethod("setCallback", IFloatWindowCallback.class);
            Object obj    = method.invoke(context, callback);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void init(Context context) {
        mContext = context;
        initLayoutParams();
        initView();
        mIsShowing = false;
        mTRTCKaraokeRoom = TRTCKaraokeRoom.sharedInstance(context);
        createDemoApplication(context, this);
    }

    public void showView(View view) {
        if (null != mWindowManager) {
            mWindowManager.addView(view, mLayoutParams);
        }
    }

    public void createView() {
        Log.d(TAG, "createView: mIsShowing = " + mIsShowing);
        if (!mIsShowing) {
            showView(mRootView);
            mIsShowing = true;
        }

    }

    public void show() {
        Log.d(TAG, "show: mIsShowing = " + mIsShowing);
        if (!mIsShowing && mRootView != null) {
            mRootView.setVisibility(View.VISIBLE);
            mIsShowing = true;
        }
    }

    public void hide() {
        Log.d(TAG, "hide: mIsShowing = " + mIsShowing);
        if (mIsShowing && mRootView != null) {
            mRootView.setVisibility(View.GONE);
            mIsShowing = false;
        }

    }

    public void initView() {
        mRootView = LayoutInflater.from(mContext).inflate(R.layout.trtckaraoke_floatview, null);
        mImgCover = mRootView.findViewById(R.id.iv_cover);
        mImgSpeaker = mRootView.findViewById(R.id.iv_speaker);
        mImgClose = mRootView.findViewById(R.id.iv_close);
        mImgSpeaker.setImageResource(R.drawable.trtckaraoke_ic_speaker);
        ImageLoader.loadImage(mContext, mImgCover, mRoomUrl, R.drawable.trtckaraoke_ic_cover);

        mImgCover.setOnTouchListener(new FloatingOnTouchListener());
        mImgSpeaker.setOnTouchListener(new FloatingOnTouchListener());
        mImgClose.setOnTouchListener(new FloatingOnTouchListener());
    }

    private void initLayoutParams() {
        mWindowManager = (WindowManager) mContext.getSystemService(Context.WINDOW_SERVICE);
        mLayoutParams = new WindowManager.LayoutParams();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            mLayoutParams.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY;
        } else {
            mLayoutParams.type = WindowManager.LayoutParams.TYPE_PHONE;
        }
        mLayoutParams.format = PixelFormat.RGBA_8888;
        mLayoutParams.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
                | WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS;
        mLayoutParams.gravity = Gravity.LEFT | Gravity.TOP;
        //指定位置
        mLayoutParams.x = 0;
        mLayoutParams.y = mWindowManager.getDefaultDisplay().getHeight() / 2;
        //悬浮窗的宽高
        mLayoutParams.width = WindowManager.LayoutParams.WRAP_CONTENT;
        mLayoutParams.height = WindowManager.LayoutParams.WRAP_CONTENT;
        mLayoutParams.format = PixelFormat.TRANSPARENT;
    }

    public void setOnClick(OnClick onClick) {
        this.onClick = onClick;
    }

    //点击事件
    private void click(int i) {
        if (i == R.id.iv_speaker) {
            if (!mIsPlay) {
                mTRTCKaraokeRoom.muteAllRemoteAudio(true);
                mImgSpeaker.setImageResource(R.drawable.trtckaraoke_ic_speaker_off);
                mIsPlay = true;
            } else {
                mTRTCKaraokeRoom.muteAllRemoteAudio(false);
                mImgSpeaker.setImageResource(R.drawable.trtckaraoke_ic_speaker);
                mIsPlay = false;
            }
        } else if (i == R.id.iv_cover) {
            if (mEntity != null) {
                KaraokeRoomAudienceActivity.enterRoom(mContext, mEntity.roomId, mEntity.userId, mEntity.audioQuality);
            }
        } else if (i == R.id.iv_close) {
            mIsDestroyByself = true;
            destroy();
        }
    }

    public void destroy() {
        if (mWindowManager != null && mRootView != null) {
            Log.d(TAG, "destroy:  removeView ");
            mWindowManager.removeView(mRootView);
            mRootView = null;
            mWindowManager = null;
        }

        mIsShowing = false;
        mIsPlay = false;
        Log.d(TAG, "destroy: WindowManager");

        if (mTRTCKaraokeRoom != null) {
            mTRTCKaraokeRoom.exitRoom(new TRTCKaraokeRoomCallback.ActionCallback() {
                @Override
                public void onCallback(int code, String msg) {
                }
            });
        }
        createDemoApplication(mContext, null);
    }

    /**
     * 设置悬浮窗监听事件
     */
    int tag  = 0;//0：初始状态；1：非初始状态
    int oldX = 0;//原X
    int oldY = 0;//原Y

    private class FloatingOnTouchListener implements View.OnTouchListener {
        @Override
        public boolean onTouch(View v, MotionEvent event) {
            curX = mLayoutParams.x;
            curY = mLayoutParams.y;

            switch (event.getAction()) {
                case MotionEvent.ACTION_DOWN:
                    isMove = false;
                    oldX = (int) event.getRawX();
                    oldY = (int) event.getRawY();
                    //获取初始位置
                    startX = (event.getRawX() - mLayoutParams.x);
                    startY = (event.getRawY() - mLayoutParams.y);
                    break;
                case MotionEvent.ACTION_MOVE:
                    curX = event.getRawX();
                    curY = event.getRawY();
                    updateViewPosition();//更新悬浮窗口位置
                    if (Math.abs(curX - oldX) <= 5 && Math.abs(curY - oldY) <= 5) {
                    } else {
                        isMove = true;
                    }
                    break;

                case MotionEvent.ACTION_UP:
                    curX = event.getRawX();
                    curY = event.getRawY();
                    //若位置变动不大,默认为点击
                    if (Math.abs(curX - oldX) <= 5 && Math.abs(curY - oldY) <= 5 && !isMove) {
                        click(v.getId());
                    }
                    move();
                    oldX = (int) event.getRawX();
                    oldY = (int) event.getRawY();
                    break;
            }
            return true;
        }
    }

    /**
     * 更新悬浮窗口位置
     */
    private void updateViewPosition() {
        mLayoutParams.x = (int) (curX - startX);
        mLayoutParams.y = (int) (curY - startY);
        if (mWindowManager != null) {
            mWindowManager.updateViewLayout(mRootView, mLayoutParams);
        }
    }

    /**
     * 点击事件接口
     */
    public interface OnClick {
        void click(int type);
    }

    public void move() {
        if (mHandler == null || mWindowManager == null) {
            return;
        }

        for (int i = 0; i < mWindowManager.getDefaultDisplay().getWidth(); i++) {//一毫秒更新一次，直到达到边缘了
            mHandler.sendEmptyMessageDelayed(i, 300);
        }

        mWindowManager.updateViewLayout(mRootView, mLayoutParams);
    }

    private Handler mHandler = new Handler(Looper.getMainLooper()) {
        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
            moveToBeside();
        }
    };

    //滑动到左边
    private void moveToBeside() {
        if (!mIsShowing) {
            return;
        }
        if (mLayoutParams.x > 0) {
            mLayoutParams.x = mLayoutParams.x / 2;
            if (mLayoutParams.x < 10) {
                mLayoutParams.x = 0;
            }
        } else if (mLayoutParams.x < 0) {
            mLayoutParams.x++;
        }
        if (mWindowManager != null) {
            mWindowManager.updateViewLayout(mRootView, mLayoutParams);
        }
    }

    public void setRoomInfo(AudienceRoomEntity entity) {
        mEntity = entity;
    }
}
