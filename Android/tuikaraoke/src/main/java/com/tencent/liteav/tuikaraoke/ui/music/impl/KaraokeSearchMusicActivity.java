package com.tencent.liteav.tuikaraoke.ui.music.impl;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.util.Log;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.blankj.utilcode.util.ToastUtils;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicCallback;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.ui.room.RoomInfoController;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class KaraokeSearchMusicActivity extends AppCompatActivity {
    private static final String             TAG = "KaraokeSearchMusicActiv";
    private static       RoomInfoController mRoomInfoController;

    private EditText     mEtSearchMusic;
    private RecyclerView mRvSearchList;
    private Button       mBtnCancelSearch;
    private ProgressBar  mProgressBar;
    private ImageView    mImgClearSearch;

    private KaraokeMusicService            mMusicServiceImpl;
    private KaraokeMusicSearchAdapter      mSearchAdapter;
    private Map<String, KaraokeMusicModel> mSelectMap;
    private List<KaraokeMusicModel>        mSearchList;
    private long                           lastClickTime = -1;
    private int                            mPageOffset   = 0;
    private String                         mKeyWord;
    private Handler                        mMainHandler;
    private boolean                        mHasMore; //还有数据

    private static final int MUSIC_NUM_INTERNAL = 10; //每次获取10个数据
    //加载状态
    public static final  int STATE_NONE         = 0; //未加载
    public static final  int STATE_LOADING      = 1; //正在加载中
    public static final  int STATE_LASTED       = 2; //加载结束
    public static final  int STATE_ERROR        = 3; //加载失败

    public static void createSearchMusicActivity(Context context, RoomInfoController controller) {
        mRoomInfoController = controller;
        Intent intent = new Intent(context, KaraokeSearchMusicActivity.class);
        context.startActivity(intent);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // 应用运行时，保持不锁屏、全屏化
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.trtckaraoke_activity_search_music);
        initStatusBar();
        initView();
        initData();
        initListener();
    }

    private void initView() {
        mEtSearchMusic = (EditText) findViewById(R.id.et_search_music);
        mRvSearchList = (RecyclerView) findViewById(R.id.rl_search_list);
        mBtnCancelSearch = (Button) findViewById(R.id.btn_cancel_search);
        mImgClearSearch = (ImageView) findViewById(R.id.img_clear_music);
        mProgressBar = findViewById(R.id.progress_search);
        mProgressBar.setVisibility(View.GONE);
    }

    private void initData() {
        mSearchList = new ArrayList<>();
        mSelectMap = new HashMap<>();
        mMainHandler = new Handler(Looper.getMainLooper());
        if (mRoomInfoController != null) {
            mMusicServiceImpl = mRoomInfoController.getMusicServiceImpl();
            mSelectMap = mRoomInfoController.getUserSelectMap();
        }
        mSearchAdapter = new KaraokeMusicSearchAdapter(this, mRoomInfoController, mSearchList,
                new KaraokeMusicSearchAdapter.OnPickItemClickListener() {
                    @Override
                    public void onPickSongItemClick(final KaraokeMusicInfo info, int layoutPosition) {
                        //点歌
                        if (mMusicServiceImpl == null) {
                            return;
                        }
                        if (lastClickTime > 0) {
                            long current = System.currentTimeMillis();
                            if (current - lastClickTime < 300) {
                                return;
                            }
                        }
                        lastClickTime = System.currentTimeMillis();
                        RecyclerView.ViewHolder holder = mRvSearchList.findViewHolderForAdapterPosition(layoutPosition);
                        ProgressBar bar = null;
                        if (holder != null) {
                            bar = holder.itemView.findViewById(R.id.progress_bar_choose_song);
                        }
                        pickMusic(bar, info);
                    }
                });
        mRvSearchList.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.VERTICAL, false));
        mSearchAdapter.setHasStableIds(true);
        mRvSearchList.setAdapter(mSearchAdapter);
        mSearchAdapter.notifyDataSetChanged();
    }

    @Override
    public boolean dispatchTouchEvent(MotionEvent ev) {
        if (ev.getAction() == MotionEvent.ACTION_DOWN) {
            View view = getCurrentFocus();
            hideKeyboard(ev, view, KaraokeSearchMusicActivity.this);
        }
        return super.dispatchTouchEvent(ev);
    }

    private void hideKeyboard(MotionEvent event, View view, Activity activity) {
        try {
            if (view instanceof EditText) {
                int[] location = {0, 0};
                view.getLocationInWindow(location);
                int left = location[0], top = location[1], right = left
                        + view.getWidth(), bottom = top + view.getHeight();
                // 判断焦点位置坐标是否在空间内，如果位置在控件外，则隐藏键盘
                if (event.getRawX() < left || event.getRawX() > right
                        || event.getY() < top || event.getRawY() > bottom) {
                    // 隐藏键盘
                    IBinder token = view.getWindowToken();
                    InputMethodManager inputMethodManager = (InputMethodManager) activity
                            .getSystemService(Context.INPUT_METHOD_SERVICE);
                    inputMethodManager.hideSoftInputFromWindow(token,
                            InputMethodManager.HIDE_NOT_ALWAYS);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void initListener() {
        mEtSearchMusic.setOnEditorActionListener(new TextView.OnEditorActionListener() {
            @Override
            public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                    mPageOffset = 0;
                    mHasMore = true;
                    if (mSearchList != null) {
                        mSearchList.clear();
                    }
                    mKeyWord = v.getText().toString();
                    if (TextUtils.isEmpty(mKeyWord)) {
                        ToastUtils.showShort(R.string.trtckaraoke_input_keywords);
                        return false;
                    }
                    searchMusic(mPageOffset, mKeyWord);
                    return true;
                }
                return false;
            }
        });

        mEtSearchMusic.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence text, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence text, int start, int before, int count) {
                if (text.length() == 0) {
                    mImgClearSearch.setVisibility(View.GONE);
                } else {
                    mImgClearSearch.setVisibility(View.VISIBLE);
                }
            }

            @Override
            public void afterTextChanged(Editable s) {

            }
        });

        //清空搜索框
        mImgClearSearch.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mEtSearchMusic.setText("");
                mKeyWord = "";
                if (mSearchList != null) {
                    mSearchList.clear();
                    mSearchAdapter.notifyDataSetChanged();
                }
                setFooterViewState(STATE_NONE);
            }
        });

        //取消搜索后退出当前搜索界面
        mBtnCancelSearch.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mEtSearchMusic.setText("");
                InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
                boolean isOpen = imm.isActive();
                if (isOpen) {
                    imm.hideSoftInputFromWindow(mEtSearchMusic.getWindowToken(), InputMethodManager.HIDE_NOT_ALWAYS);
                }
                finish();
            }
        });

        mRvSearchList.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrollStateChanged(RecyclerView recyclerView, int newState) {
            }

            @Override
            public void onScrolled(RecyclerView recyclerView, int dx, int dy) {
                super.onScrolled(recyclerView, dx, dy);
                LinearLayoutManager lm = (LinearLayoutManager) recyclerView.getLayoutManager();
                if (null == lm) {
                    throw new RuntimeException("call setLayoutManager first");
                }
                if (lm instanceof LinearLayoutManager) {
                    int lastCompletelyVisibleItemPos = lm.findLastCompletelyVisibleItemPosition();
                    if (mSearchAdapter.getItemCount() > 10
                            && lastCompletelyVisibleItemPos == mSearchAdapter.getItemCount() - 1) {
                        //加载更多
                        if (mHasMore) {
                            mPageOffset = mSearchList.size();
                            if (!TextUtils.isEmpty(mKeyWord)) {
                                searchMusic(mPageOffset, mKeyWord);
                            }
                        } else {
                            //没有更多数据可加载了
                        }
                    }
                }
            }
        });
    }

    //更新加载状态
    private void updateLoadState() {
        int interval = mSearchList.size() - mPageOffset;
        //后台没有更多数据了
        if (interval >= 0 && interval < MUSIC_NUM_INTERNAL) {
            mHasMore = false;
            setFooterViewState(STATE_LASTED);
        } else {
            mHasMore = true;
            setFooterViewState(STATE_LOADING);
        }
    }

    //更新底部显示
    private void setFooterViewState(int status) {
        mSearchAdapter.setFooterViewState(status);
    }

    private void pickMusic(final ProgressBar bar, final KaraokeMusicInfo info) {
        mMusicServiceImpl.downLoadMusic(info, new KaraokeMusicCallback.MusicLoadingCallback() {
            @Override
            public void onStart(KaraokeMusicInfo musicInfo) {
            }

            @Override
            public void onProgress(KaraokeMusicInfo musicInfo, float progress) {
                publishProgress(bar, musicInfo.musicId, progress);
            }

            @Override
            public void onFinish(KaraokeMusicInfo musicInfo, int errorCode, String errorMessage) {
                if (errorCode != 0 || musicInfo == null) {
                    Log.d(TAG, "downloadMusic failed errorCode = " + errorCode + " , errorMessage = " + errorMessage);
                    ToastUtils.showShort(errorMessage);
                    return;
                }
                info.lrcUrl = musicInfo.lrcUrl;
                publishProgress(bar, musicInfo.musicId, 100);
                //歌词下载完后,更新列表中歌曲的lrcUrl
                updateSearchList(info);
                mMainHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        mSearchAdapter.notifyDataSetChanged();
                    }
                });
            }
        });

        //更新搜索列表
        KaraokeMusicModel model = new KaraokeMusicModel();
        model.musicId = info.musicId;
        model.singers = info.singers;
        model.musicName = info.musicName;
        model.userId = info.userId;
        updateSearchList(model);
        mSelectMap.put(model.musicId, model);
        mSearchAdapter.notifyDataSetChanged();

        mMusicServiceImpl.pickMusic(info, new KaraokeMusicCallback.ActionCallback() {
            @Override
            public void onCallback(int code, String msg) {
                if (code != 0) {
                    return;
                }
            }
        });
    }

    private void publishProgress(final ProgressBar progressBar, String id, final float progress) {
        if (progressBar == null || id == null) {
            return;
        }
        int curProgress = (int) (progress * 100);
        if (curProgress < 0) {
            curProgress = 0;
        }
        if (curProgress > 100) {
            curProgress = 100;
        }
        final int finalCurProgress = curProgress;
        progressBar.post(new Runnable() {
            @Override
            public void run() {
                progressBar.setProgress(finalCurProgress);
            }
        });
    }

    private void searchMusic(int offest, String keyWords) {
        if (mMusicServiceImpl == null) {
            Log.d(TAG, "searchMusic: can not search music");
            return;
        }
        mProgressBar.setVisibility(View.VISIBLE);
        mMusicServiceImpl.ktvSearchMusicByKeyWords(offest, MUSIC_NUM_INTERNAL, keyWords, new KaraokeMusicCallback.MusicListCallback() {
            @Override
            public void onCallback(int code, String msg, List<KaraokeMusicInfo> list) {
                if (code != 0) {
                    Log.d(TAG, "search music failed");
                    setFooterViewState(STATE_ERROR);
                    return;
                }

                for (KaraokeMusicInfo info : list) {
                    KaraokeMusicModel model = new KaraokeMusicModel();
                    model.musicId = info.musicId;
                    model.singers = info.singers;
                    model.musicName = info.musicName;
                    model.userId = info.userId;
                    model.isSelected = false;

                    //从已点列表中查找当前歌曲是否已点
                    KaraokeMusicModel selectModel = mSelectMap.get(model.musicId);
                    if (selectModel != null) {
                        model.isSelected = true;
                        model.lrcUrl = selectModel.lrcUrl;
                    }
                    mSearchList.add(model);
                }
                mSearchAdapter.notifyDataSetChanged();
                mProgressBar.setVisibility(View.GONE);
                updateLoadState();
            }
        });
    }

    private void updateSearchList(KaraokeMusicInfo info) {
        if (info == null || mSearchList == null || mSearchList.size() <= 0) {
            Log.d(TAG, "updateSearchList the list update failed");
            return;
        }

        for (KaraokeMusicModel temp : mSearchList) {
            if (temp != null && info.musicId.equals(temp.musicId)) {
                temp.isSelected = true;
                temp.lrcUrl = info.lrcUrl;
            }
        }
    }

    private void initStatusBar() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            Window window = getWindow();
            window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
            window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
            window.setStatusBarColor(Color.TRANSPARENT);
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
        }
    }
}