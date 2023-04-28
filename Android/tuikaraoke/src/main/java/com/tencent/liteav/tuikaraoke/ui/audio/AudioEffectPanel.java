package com.tencent.liteav.tuikaraoke.ui.audio;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.CompoundButton;
import android.widget.SeekBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.SwitchCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.bottomsheet.BottomSheetDialog;
import com.tencent.liteav.basic.IntentUtils;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoom;

import java.util.ArrayList;
import java.util.List;

public class AudioEffectPanel extends BottomSheetDialog {

    private static final String TAG = AudioEffectPanel.class.getSimpleName();

    private static final int AUDIO_REVERB_TYPE_0 = 0;
    private static final int AUDIO_REVERB_TYPE_1 = 1;
    private static final int AUDIO_REVERB_TYPE_4 = 4;
    private static final int AUDIO_REVERB_TYPE_5 = 5;
    private static final int AUDIO_REVERB_TYPE_6 = 6;

    private static final int AUDIO_VOICE_CHANGER_TYPE_0  = 0;
    private static final int AUDIO_VOICE_CHANGER_TYPE_1  = 1;
    private static final int AUDIO_VOICE_CHANGER_TYPE_2  = 2;
    private static final int AUDIO_VOICE_CHANGER_TYPE_3  = 3;
    private static final int AUDIO_VOICE_CHANGER_TYPE_11 = 11;


    private Context             mContext;
    private RecyclerView        mRecycleVoiceReverb;
    private RecyclerView        mRecycleVoiceChanger;
    private SeekBar             mSeekBarVoiceCaptureVolume;
    private SeekBar             mSeekBarBGMVolume;
    private SeekBar             mSeekBarMusicPitch;
    private RecyclerViewAdapter mVoiceReverbAdapter;

    private RecyclerViewAdapter mVoiceChangerAdapter;
    private TextView            mTextBGMVolume;
    private TextView            mTextPitchLevel;
    private TextView            mTextVoiceCaptureVolume;
    private SwitchCompat        mSwitchVoiceEarMonitor;

    private List<Entity>        mVoiceReverbEntityList = new ArrayList<>();
    private int                 mVoiceReverbPosition   = 0;

    private List<Entity>        mVoiceChangerEntityList = new ArrayList<>();
    private int                 mVoiceChangerPosition   = 0;
    private TRTCKaraokeRoom     mTRTCKaraokeRoom;

    public AudioEffectPanel(@NonNull Context context) {
        super(context, R.style.TRTCKTVRoomDialogTheme);
        mContext = context;
        mTRTCKaraokeRoom = TRTCKaraokeRoom.sharedInstance(context);
        initVoiceReverbEntityList();
        initVoiceChangerEntityList();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.trtckaraoke_audio_effect_panel);
        initView();
    }

    private void initView() {
        findViewById(R.id.link_music).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(Intent.ACTION_VIEW);
                intent.setData(Uri.parse("https://cloud.tencent.com/product/ame"));
                IntentUtils.safeStartActivity(mContext, intent);
            }
        });

        mSwitchVoiceEarMonitor = findViewById(R.id.switch_ear_monitor);
        mSwitchVoiceEarMonitor.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                mTRTCKaraokeRoom.enableVoiceEarMonitor(isChecked);
            }
        });

        mTextBGMVolume = findViewById(R.id.tv_bgm_volume);
        mTextVoiceCaptureVolume = findViewById(R.id.tv_mic_volume);
        mTextPitchLevel = findViewById(R.id.tv_pitch_level);

        mSeekBarVoiceCaptureVolume = findViewById(R.id.sb_mic_volume);
        mSeekBarBGMVolume = findViewById(R.id.sb_bgm_volume);
        mSeekBarMusicPitch = findViewById(R.id.sb_pitch_level);

        mSeekBarBGMVolume.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                mTextBGMVolume.setText(String.valueOf(progress));
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                mTRTCKaraokeRoom.setMusicVolume(seekBar.getProgress());
            }
        });

        mSeekBarVoiceCaptureVolume.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                mTextVoiceCaptureVolume.setText(String.valueOf(progress));
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                mTRTCKaraokeRoom.setVoiceVolume(seekBar.getProgress());
            }
        });

        mSeekBarMusicPitch.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                float pitch = ((progress - 50) / (float) 50);
                // pitch 保留 1 位小数
                pitch = (float) (Math.round(pitch * 10)) / 10;
                mTextPitchLevel.setText(pitch + "");
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                float pitch = ((seekBar.getProgress() - 50) / (float) 50);
                mTRTCKaraokeRoom.setMusicPitch(pitch);
            }
        });

        initVoiceReverbRecycleView();
        initVoiceChangerRecycleView();
    }

    private void initVoiceReverbRecycleView() {
        mRecycleVoiceReverb = findViewById(R.id.rv_audio_reverb_type);
        LinearLayoutManager reverbLayoutManager = new LinearLayoutManager(mContext);
        reverbLayoutManager.setOrientation(LinearLayoutManager.HORIZONTAL);
        mRecycleVoiceReverb.setLayoutManager(reverbLayoutManager);

        mVoiceReverbEntityList.get(mVoiceReverbPosition).mIsSelected = true;
        mVoiceReverbAdapter = new RecyclerViewAdapter(mContext, mVoiceReverbEntityList,
                new RecyclerViewAdapter.OnItemClickListener() {
                    @Override
                    public void onItemClick(int position) {
                        int type = mVoiceReverbEntityList.get(position).mType;
                        mTRTCKaraokeRoom.setVoiceReverbType(type);
                        mVoiceReverbEntityList.get(position).mIsSelected = true;
                        mVoiceReverbEntityList.get(mVoiceReverbPosition).mIsSelected = false;
                        mVoiceReverbPosition = position;
                        mVoiceReverbAdapter.notifyDataSetChanged();
                    }
                });
        mRecycleVoiceReverb.setAdapter(mVoiceReverbAdapter);
    }

    private void initVoiceChangerRecycleView() {
        mRecycleVoiceChanger = findViewById(R.id.recycle_voice_changer);
        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(mContext);
        linearLayoutManager.setOrientation(LinearLayoutManager.HORIZONTAL);
        mRecycleVoiceChanger.setLayoutManager(linearLayoutManager);

        mVoiceChangerEntityList.get(mVoiceChangerPosition).mIsSelected = true;
        mVoiceChangerAdapter = new RecyclerViewAdapter(mContext, mVoiceChangerEntityList,
                new RecyclerViewAdapter.OnItemClickListener() {
                    @Override
                    public void onItemClick(int position) {
                        int type = mVoiceChangerEntityList.get(position).mType;
                        TRTCKaraokeRoom.sharedInstance(mContext).setVoiceChangerType(type);
                        mVoiceChangerEntityList.get(position).mIsSelected = true;
                        mVoiceChangerEntityList.get(mVoiceChangerPosition).mIsSelected = false;
                        mVoiceChangerPosition = position;
                        mVoiceChangerAdapter.notifyDataSetChanged();
                    }
                });
        mRecycleVoiceChanger.setAdapter(mVoiceChangerAdapter);
    }

    private void initVoiceReverbEntityList() {
        mVoiceReverbEntityList.add(new Entity(mContext.getResources().getString(R.string.trtckaraoke_no_effect),
                R.drawable.trtckaraoke_changetype_no_select_nomal,
                R.drawable.trtckaraoke_changetype_no_select_hover, AUDIO_REVERB_TYPE_0));
        mVoiceReverbEntityList.add(new Entity(
                mContext.getResources().getString(R.string.trtckaraoke_audio_reverb_type_ktv),
                R.drawable.trtckaraoke_reverbtype_ktv_normal,
                R.drawable.trtckaraoke_reverbtype_ktv_hover, AUDIO_REVERB_TYPE_1));
        mVoiceReverbEntityList.add(new Entity(
                mContext.getResources().getString(R.string.trtckaraoke_audio_reverb_type_lowdeep),
                R.drawable.trtckaraoke_reverbtype_lowdeep_normal,
                R.drawable.trtckaraoke_reverbtype_lowdeep_hover, AUDIO_REVERB_TYPE_4));
        mVoiceReverbEntityList.add(new Entity(
                mContext.getResources().getString(R.string.trtckaraoke_audio_reverb_type_heavymetal),
                R.drawable.trtckaraoke_reverbtype_heavymetal_normal,
                R.drawable.trtckaraoke_reverbtype_heavymetal_hover, AUDIO_REVERB_TYPE_6));
        mVoiceReverbEntityList.add(new Entity(
                mContext.getResources().getString(R.string.trtckaraoke_audio_reverb_type_hongliang),
                R.drawable.trtckaraoke_reverbtype_hongliang_normal,
                R.drawable.trtckaraoke_reverbtype_hongliang_hover, AUDIO_REVERB_TYPE_5));
    }

    private void initVoiceChangerEntityList() {
        mVoiceChangerEntityList.add(new Entity(
                mContext.getResources().getString(R.string.trtckaraoke_no_effect),
                R.drawable.trtckaraoke_changetype_no_select_nomal,
                R.drawable.trtckaraoke_changetype_no_select_hover, AUDIO_VOICE_CHANGER_TYPE_0));
        mVoiceChangerEntityList.add(new Entity(
                mContext.getResources().getString(R.string.trtckaraoke_audio_change_type_child),
                R.drawable.trtckaraoke_changetype_child_normal,
                R.drawable.trtckaraoke_changetype_child_hover, AUDIO_VOICE_CHANGER_TYPE_1));
        mVoiceChangerEntityList.add(new Entity(
                mContext.getResources().getString(R.string.trtckaraoke_audio_change_type_luoli),
                R.drawable.trtckaraoke_changetype_luoli_normal,
                R.drawable.trtckaraoke_changetype_luoli_hover, AUDIO_VOICE_CHANGER_TYPE_2));
        mVoiceChangerEntityList.add(new Entity(
                mContext.getResources().getString(R.string.trtckaraoke_audio_change_type_dashu),
                R.drawable.trtckaraoke_changetype_dashu_normal,
                R.drawable.trtckaraoke_changetype_dashu_hover, AUDIO_VOICE_CHANGER_TYPE_3));
        mVoiceChangerEntityList.add(new Entity(
                mContext.getResources().getString(R.string.trtckaraoke_audio_change_type_kongling),
                R.drawable.trtckaraoke_changetype_kongling_normal,
                R.drawable.trtckaraoke_changetype_kongling_hover, AUDIO_VOICE_CHANGER_TYPE_11));
    }
}
