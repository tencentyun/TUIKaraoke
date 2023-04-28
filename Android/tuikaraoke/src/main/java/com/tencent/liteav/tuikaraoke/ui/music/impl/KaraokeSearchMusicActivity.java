package com.tencent.liteav.tuikaraoke.ui.music.impl;

import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_ADD_MUSIC_EVENT;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_MUSIC_EVENT;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_MUSIC_INFO_KEY;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ProgressBar;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.tencent.liteav.tuikaraoke.model.KaraokeAddMusicCallback;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicPageInfo;
import com.tencent.liteav.tuikaraoke.ui.utils.Toast;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.model.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.ui.room.RoomInfoController;
import com.tencent.qcloud.tuicore.TUICore;
import com.tencent.liteav.tuikaraoke.ui.music.impl.KaraokeMusicSearchAdapter.ViewHolder;
import com.tencent.qcloud.tuicore.interfaces.TUIValueCallback;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class KaraokeSearchMusicActivity extends AppCompatActivity {
    private static final String             TAG = "KaraokeSearchMusic";
    private static       RoomInfoController mRoomInfoController;

    private EditText     mEditSearchMusic;
    private RecyclerView mRecyclerSearchList;
    private Button       mButtonCancelSearch;
    private ProgressBar  mProgressBar;
    private ImageView    mImageClearSearch;

    private KaraokeMusicService            mMusicServiceImpl;
    private KaraokeMusicSearchAdapter      mSearchAdapter;
    private List<KaraokeMusicInfo>         mSearchList;
    private String                         mScrollToke;
    private boolean                        mHasMore; //还有数据

    private static final int MUSIC_NUM_INTERNAL = 10; //每次获取10个数据
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
        mEditSearchMusic = findViewById(R.id.et_search_music);
        mRecyclerSearchList = findViewById(R.id.rl_search_list);
        mButtonCancelSearch = findViewById(R.id.btn_cancel_search);
        mImageClearSearch = findViewById(R.id.img_clear_music);
        mProgressBar = findViewById(R.id.progress_search);
        mProgressBar.setVisibility(View.GONE);
    }

    private void initData() {
        mSearchList = new ArrayList<>();
        mMusicServiceImpl = mRoomInfoController.getMusicServiceImpl();
        mSearchAdapter = new KaraokeMusicSearchAdapter(this, mRoomInfoController, mSearchList,
                new KaraokeMusicSearchAdapter.OnPickItemClickListener() {
                    @Override
                    public void onPickSongItemClick(final KaraokeMusicInfo info, int position) {
                        addMusicToPlaylist(info, position);
                    }
                });
        mRecyclerSearchList.setLayoutManager(new LinearLayoutManager(this,
                LinearLayoutManager.VERTICAL, false));
        mSearchAdapter.setHasStableIds(true);
        mRecyclerSearchList.setAdapter(mSearchAdapter);
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
                int left = location[0];
                int top = location[1];
                int right = left + view.getWidth();
                int bottom = top + view.getHeight();
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
        mEditSearchMusic.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence text, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence text, int start, int before, int count) {
                if (text.length() == 0) {
                    mImageClearSearch.setVisibility(View.GONE);
                } else {
                    mImageClearSearch.setVisibility(View.VISIBLE);
                }
            }

            @Override
            public void afterTextChanged(Editable s) {
                mScrollToke = null;
                mHasMore = true;
                if (mSearchList != null) {
                    mSearchList.clear();
                }
                String inputWord = mEditSearchMusic.getText().toString();
                if (TextUtils.isEmpty(inputWord)) {
                    mSearchAdapter.notifyDataSetChanged();
                    setFooterViewState(STATE_NONE);
                } else {
                    searchMusic(mScrollToke, inputWord, false);
                }
            }
        });

        //清空搜索框
        mImageClearSearch.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mEditSearchMusic.setText("");
                if (mSearchList != null) {
                    mSearchList.clear();
                    mSearchAdapter.notifyDataSetChanged();
                }
                setFooterViewState(STATE_NONE);
            }
        });

        //取消搜索后退出当前搜索界面
        mButtonCancelSearch.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mEditSearchMusic.setText("");
                InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
                boolean isOpen = imm.isActive();
                if (isOpen) {
                    imm.hideSoftInputFromWindow(mEditSearchMusic.getWindowToken(), InputMethodManager.HIDE_NOT_ALWAYS);
                }
                finish();
            }
        });

        mRecyclerSearchList.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrollStateChanged(RecyclerView recyclerView, int newState) {
            }

            @Override
            public void onScrolled(RecyclerView recyclerView, int dx, int dy) {
                super.onScrolled(recyclerView, dx, dy);
                LinearLayoutManager layoutManager = (LinearLayoutManager) recyclerView.getLayoutManager();
                if (null == layoutManager) {
                    throw new RuntimeException("call setLayoutManager first");
                }
                if (layoutManager instanceof LinearLayoutManager) {
                    int lastCompletelyVisibleItemPos = layoutManager.findLastCompletelyVisibleItemPosition();
                    if (mSearchAdapter.getItemCount() > 10
                            && lastCompletelyVisibleItemPos == mSearchAdapter.getItemCount() - 1) {
                        //加载更多
                        if (mHasMore) {
                            searchMusic(mScrollToke, mEditSearchMusic.getText().toString(), true);
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
        setFooterViewState(mHasMore ? STATE_LOADING : STATE_LASTED);
    }

    //更新底部显示
    private void setFooterViewState(int status) {
        mSearchAdapter.setFooterViewState(status);
    }

    private void addMusicToPlaylist(final KaraokeMusicInfo info, int position) {
        info.isSelected = true;
        ViewHolder holder = (ViewHolder) mRecyclerSearchList.findViewHolderForAdapterPosition(position);
        ProgressBar progressBar = holder.itemView.findViewById(R.id.progress_bar_choose_song);
        holder.updateChooseButton(info.isSelected);
        mMusicServiceImpl.addMusicToPlaylist(info, new KaraokeAddMusicCallback() {
            @Override
            public void onStart(KaraokeMusicInfo musicInfo) {}

            @Override
            public void onProgress(KaraokeMusicInfo musicInfo, float progress) {
                int curProgress = (int) (progress * 100);
                curProgress = Math.max(curProgress, 0);
                curProgress = Math.min(curProgress, 100);
                progressBar.setProgress(curProgress);
            }

            @Override
            public void onFinish(KaraokeMusicInfo musicInfo, int errorCode, String errorMessage) {
                if (errorCode != 0 || musicInfo == null) {
                    Log.d(TAG, "downloadMusic failed errorCode = " + errorCode + " , errorMessage = " + errorMessage);
                    info.isSelected = false;
                    String tip = getString(R.string.trtckaraoke_toast_music_download_failed, musicInfo.musicName);
                    Toast.show(tip, Toast.LENGTH_SHORT);
                    holder.updateChooseButton(info.isSelected);
                    mMusicServiceImpl.deleteMusicFromPlaylist(info, null);
                } else {
                    Map<String, Object> params = new HashMap<>();
                    params.put(KARAOKE_MUSIC_INFO_KEY, info);
                    TUICore.notifyEvent(KARAOKE_MUSIC_EVENT, KARAOKE_ADD_MUSIC_EVENT, params);
                }
            }
        });
    }

    private void searchMusic(String scrollToken, String keyWords, boolean append) {
        if (TextUtils.isEmpty(keyWords)) {
            return;
        }
        if (mMusicServiceImpl == null) {
            TRTCLogger.e(TAG, "Can not search music，because karaokeMusicService instance is null ");
            return;
        }
        mProgressBar.setVisibility(View.VISIBLE);
        mMusicServiceImpl.getMusicsByKeywords(scrollToken, MUSIC_NUM_INTERNAL, keyWords,
                new TUIValueCallback<KaraokeMusicPageInfo>() {
                    @Override
                    public void onError(int errorCode, String errorMessage) {
                        Log.d(TAG, "search music failed");
                        setFooterViewState(STATE_ERROR);
                        return;
                    }

                    @Override
                    public void onSuccess(KaraokeMusicPageInfo pageInfo) {
                        if (TextUtils.isEmpty(pageInfo.scrollToken) && pageInfo.musicInfoList.isEmpty()) {
                            mHasMore = false;
                        } else {
                            mScrollToke = pageInfo.scrollToken;
                        }
                        if (!append) {
                            mSearchList.clear();
                        }
                        for (KaraokeMusicInfo info : pageInfo.musicInfoList) {
                            KaraokeMusicInfo model = new KaraokeMusicInfo();
                            model.musicId = info.musicId;
                            model.singers = info.singers;
                            model.musicName = info.musicName;
                            model.userId = info.userId;
                            model.isSelected = false;

                            //从已点列表中查找当前歌曲是否已点
                            KaraokeMusicInfo selectModel = mRoomInfoController.getUserSelectMap().get(model.musicId);
                            model.isSelected = selectModel != null;
                            if (selectModel != null) {
                                model.originUrl = selectModel.originUrl;
                                model.lrcUrl = selectModel.lrcUrl;
                                model.accompanyUrl = selectModel.accompanyUrl;
                            }
                            mSearchList.add(model);
                        }
                        mSearchAdapter.notifyDataSetChanged();
                        mProgressBar.setVisibility(View.GONE);
                        updateLoadState();
                    }
                });
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

    @Override
    protected void onDestroy() {
        super.onDestroy();
        mRoomInfoController = null;
    }
}