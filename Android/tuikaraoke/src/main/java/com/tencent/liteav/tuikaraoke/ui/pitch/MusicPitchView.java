package com.tencent.liteav.tuikaraoke.ui.pitch;

import android.animation.ValueAnimator;
import android.content.Context;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.drawable.GradientDrawable;
import android.os.Looper;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.View;
import android.view.animation.Interpolator;
import android.view.animation.LinearInterpolator;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.view.animation.PathInterpolatorCompat;

import com.tencent.liteav.basic.ResourceUtils;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.impl.base.MusicPitchModel;

import java.util.ArrayList;
import java.util.List;

public class MusicPitchView extends FrameLayout {

    // Pitch 命中检测误差±3
    private static final int HIT_PITCH_THRESHOLD = 3;
    private final LinearInterpolator mLinearInterpolator = new LinearInterpolator();
    private final Interpolator mPathInterpolator = PathInterpolatorCompat.create(0.5f,0.5f,0.5f,0.5f);
    private static final int DEFAULT_PITCH_COLOR = 0xFFB67CCC;
    private static final int HIT_PITCH_COLOR = 0xFFF884DB;
    private static final int VERTICAL_LINE_COLOR = 0xFF9548B5;
    private static final int INDICATOR_COLOR = Color.WHITE;
    private static final int SCORE_COLOR = Color.WHITE;

    // 从屏幕（PitchView）右侧滚动到左侧耗时（单位：毫秒）
    private static final int SCREEN_SCROLL_PERIOD = 4000;

    private final List<PitchItem> pitchItems = new ArrayList<>();

    private final Paint mLinePaint = createPaint();
    private final Paint mIndicatorPaint = createPaint();
    private final Paint mPitchPaint = createPaint();
    private final Paint mHitPitchPaint = createPaint();
    private final Paint mScorePaint = createPaint();

    private ValueAnimator mProgressAnimator;
    private ValueAnimator mIndicatorAnimator;

    private long mCurrentProgress = 0;
    // 为了提高音高线条左移的流畅性，模拟出前后2个播放进度之前的实时播放进度。
    private long mCurrentProgressMock = 0;
    private long mProgressMockInterval = 0;
    private int mCurrentPitch = 0;
    // 为了提高音高指示器运动的流畅性，模拟出前后2个pitch之间的实时pitch。
    private int mCurrentPitchMock = 0;

    // 像素与时间(ms)比例，决定音高线绘制宽度。
    private float mRatioOfPixelToTimeMS = 1000.0F / SCREEN_SCROLL_PERIOD;


    // 当前pitch位置（百分比），取值(0, 1)，
    private final float mCurrentPitchPositionX = 0.3F;

    // 音高条带的高度值（像素）
    private final int mPitchItemHeightPx = 8;

    // 当前PitchModel（经过竖线）的索引，命中就检测它
    private int mCurrentPitchModelIndex = 0;

    // 圆形指示器半径
    private final int mIndicatorRadius = 10;

    private int mScore = -1;
    private String mMusicInfo;
    private MusicScoreResultDialog mPitchScoreDialog;
    private Bitmap mBackBitmap;


    public MusicPitchView(@NonNull Context context) {
        this(context, null);
    }

    public MusicPitchView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        setBackgroundColor(Color.TRANSPARENT);
        setPadding(0, mIndicatorRadius, 0, mIndicatorRadius);
        mPitchPaint.setColor(DEFAULT_PITCH_COLOR);
        mHitPitchPaint.setColor(HIT_PITCH_COLOR);
        mLinePaint.setColor(VERTICAL_LINE_COLOR);
        mIndicatorPaint.setColor(INDICATOR_COLOR);
        mScorePaint.setColor(SCORE_COLOR);
        mScorePaint.setTextSize(getRawSize(TypedValue.COMPLEX_UNIT_SP, 10));
    }

    private Paint createPaint() {
        Paint paint = new Paint();
        paint.setDither(true);
        paint.setAntiAlias(true);
        paint.setStyle(Paint.Style.FILL);
        return paint;
    }

    private float getRawSize(int unit, float size) {
        Context context = getContext();
        Resources resources = getContext() == null ? Resources.getSystem() : context.getResources();
        return TypedValue.applyDimension(unit, size, resources.getDisplayMetrics());
    }

    @Override
    protected void onVisibilityChanged(@NonNull View changedView, int visibility) {
        super.onVisibilityChanged(changedView, visibility);
        if (visibility == VISIBLE) {
            if (mBackBitmap == null) {
                mBackBitmap = ResourceUtils.decodeResource(R.drawable.trtckaraoke_bg_pitch);
            }
        } else {
            if (mBackBitmap != null) {
                mBackBitmap.recycle();
                mBackBitmap = null;
            }
        }
    }

    public void setStandardPitch(List<MusicPitchModel> pitchList) {
        pitchItems.clear();
        if (pitchList == null) {
            return;
        }
        for (int i = 0; i < pitchList.size(); i++) {
            MusicPitchModel pitch = pitchList.get(i);
            if (pitch == null) {
                continue;
            }
            PitchItem pitchItem = new PitchItem(pitch);
            pitchItems.add(pitchItem);
        }
    }

    public void setMusicInfo(String musicInfo) {
        mMusicInfo = musicInfo;
    }

    public void setScore(int score) {
        mScore = score;
    }

    public void scoreFinish(int score) {
        if (mPitchScoreDialog == null) {
            mPitchScoreDialog = new MusicScoreResultDialog(getContext());
        }
        if (!TextUtils.isEmpty(mMusicInfo)) {
            mPitchScoreDialog.setMusicInfo(mMusicInfo);
        }
        mPitchScoreDialog.setScore(score);
        mPitchScoreDialog.show();
    }

    public void setCurrentSongProgress(long progress, int pitch) {
        startProgressAnimator(progress);
        startIndicatorAnimator(progress, pitch);
        mCurrentProgress = progress;
        mCurrentPitch = pitch;
    }

    private void checkHit(long progress, int pitch) {
        if (mCurrentPitchModelIndex >= pitchItems.size()) {
            return;
        }
        PitchItem pitchItem = pitchItems.get(mCurrentPitchModelIndex);
        MusicPitchModel musicPitch = pitchItem.musicPitch;
        if (Math.abs(pitchItem.musicPitch.pitch - pitch) <= HIT_PITCH_THRESHOLD
                && progress >= musicPitch.startTime
                && progress < musicPitch.startTime + musicPitch.duration) {
            // 检测到命中，命中时长比mProgressMockInterval要长一点（1.2倍），以便连续命中时绘制的命中条也是连续的。
            long start = (long) (progress - mProgressMockInterval * 1.2F);
            long end = progress;
            // 越界检查，命中start 和 end不能超过原始音高时长边界
            start = Math.max(musicPitch.startTime, start);
            end = Math.min(musicPitch.startTime + musicPitch.duration, end);
            MusicPitchModel hitMusicPitch = new MusicPitchModel(start, end - start, musicPitch.pitch);
            PitchItem hitPitchItem = new PitchItem(hitMusicPitch);
            hitPitchItem.isHit = true;
            hitPitchItem.rect.top = pitchItem.rect.top;
            hitPitchItem.rect.bottom = pitchItem.rect.bottom;
            pitchItem.hitPitchItems.add(hitPitchItem);
        }
    }

    private void startProgressAnimator(long progress) {
        final long progressInterval = progress - mCurrentProgress;
        final long lastProgress = mCurrentProgress;
        if (progressInterval <= 0) {
            return;
        }
        if (mProgressAnimator != null) {
            mProgressAnimator.removeAllListeners();
            mProgressAnimator.cancel();
        }
        mProgressAnimator = ValueAnimator.ofFloat(0, 1);
        mProgressAnimator.setInterpolator(mLinearInterpolator);
        mProgressAnimator.setDuration(progressInterval);
        mProgressAnimator.addUpdateListener(animation -> {
            float fraction = animation.getAnimatedFraction();
            long lastProgressMock = mCurrentProgressMock;
            mCurrentProgressMock = (long) (lastProgress + fraction * progressInterval);
            mProgressMockInterval = mCurrentProgressMock - lastProgressMock;
            invalidateView();
        });
        mProgressAnimator.start();
    }

    private void startIndicatorAnimator(long progress, int pitch) {
        final int pitchInterval = pitch - mCurrentPitch;
        final int lastPitch = mCurrentPitch;
        final long duration = progress - mCurrentProgress;
        if (duration <= 0) {
            return;
        }
        if (mIndicatorAnimator != null) {
            mIndicatorAnimator.removeAllListeners();
            mIndicatorAnimator.cancel();
        }
        mIndicatorAnimator = ValueAnimator.ofFloat(0, 1);
        mIndicatorAnimator.setInterpolator(mPathInterpolator);
        mIndicatorAnimator.setDuration(duration);
        mIndicatorAnimator.addUpdateListener(animation -> {
            float fraction = animation.getAnimatedFraction();
            mCurrentPitchMock = (int) (lastPitch + fraction * pitchInterval);
            mCurrentPitchMock = Math.max(mCurrentPitchMock, 0);
            checkHit(mCurrentProgressMock, mCurrentPitchMock);
            invalidateView();
        });
        mIndicatorAnimator.start();
    }

    public void reset() {
        setStandardPitch(null);
        mCurrentPitch = 0;
        mCurrentPitchMock = 0;
        mCurrentProgress = 0;
        mCurrentProgressMock = 0;
        mProgressMockInterval = 0;
        mCurrentPitchModelIndex = 0;
        mScore = -1;
    }

    private void invalidateView() {
        if (Looper.getMainLooper() == Looper.myLooper()) {
            //  当前线程是主UI线程，直接刷新。
            invalidate();
        } else {
            //  当前线程是非UI线程，post刷新。
            postInvalidate();
        }
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        drawBackground(canvas);
        drawCurrentPitchLine(canvas);
        drawMusicPitch(canvas);
        drawCurrentPitchIndicator(canvas);
        drawScore(canvas);
    }

    private void drawBackground(Canvas canvas) {
        // 绘制背景图，上下边距等于圆形指示器半径
        if (mBackBitmap != null) {
            Rect srcRect = new Rect(0, 0, mBackBitmap.getWidth(), mBackBitmap.getHeight());
            Rect dstRect = new Rect(0, getPaddingTop(), getWidth(), getHeight() - getPaddingBottom());
            canvas.drawBitmap(mBackBitmap, srcRect, dstRect, null);
        }
    }

    // 绘制竖线
    private void drawCurrentPitchLine(Canvas canvas) {
        float x = mCurrentPitchPositionX * getWidth();
        canvas.drawLine(x, getPaddingTop(), x, getHeight() - getPaddingBottom(), mLinePaint);
    }

    // 绘制当前音高指示器
    private void drawCurrentPitchIndicator(Canvas canvas) {
        float x = mCurrentPitchPositionX * getWidth();
        canvas.drawCircle(x, pitchToPositionY(mCurrentPitchMock), mIndicatorRadius, mIndicatorPaint);
    }

    private float pitchToPositionY(int pitch) {
        int heightNoPadding = getHeight() - getPaddingTop() - getPaddingBottom();
        return (100 - pitch) / 100.0F * (heightNoPadding - mPitchItemHeightPx) + mPitchItemHeightPx + getPaddingTop();
    }

    // 绘制音高条带
    private void drawMusicPitch(Canvas canvas) {
        float lineX = mCurrentPitchPositionX * getWidth();
        for (int i = 0; i < pitchItems.size(); i++) {
            // 绘制原始音高条带
            PitchItem pitchItem = pitchItems.get(i);
            drawPitchItem(canvas, pitchItem);
            RectF rect = pitchItem.rect;
            if (rect.left <= lineX && rect.right >= lineX) {
                mCurrentPitchModelIndex = i;
            }
            for (int j = 0; j < pitchItems.get(i).hitPitchItems.size(); j++) {
                // 绘制命中音高条带
                drawPitchItem(canvas, pitchItems.get(i).hitPitchItems.get(j));
            }
        }
    }

    private void drawPitchItem(Canvas canvas, PitchItem pitchItem) {
        int width = getWidth();
        mRatioOfPixelToTimeMS = 1.0F * width / SCREEN_SCROLL_PERIOD;
        float ratio = mRatioOfPixelToTimeMS;
        MusicPitchModel musicPitch = pitchItem.musicPitch;
        RectF rect = pitchItem.rect;
        rect.left = width * mCurrentPitchPositionX + musicPitch.startTime * ratio - mCurrentProgressMock * ratio;
        rect.right = rect.left + musicPitch.duration * ratio;
        if (rect.right <= 0 || rect.left >= getWidth()) {
            // 在界外就不绘制了。
            return;
        }
        if (!pitchItem.isHit) {
            // 对top做等距处理[0, 10, 20, ...]，使音高条带绘制形成阶梯状，阶梯高度为mPitchItemHeightPx
            rect.top = ((int) (pitchToPositionY(musicPitch.pitch) / mPitchItemHeightPx)) * mPitchItemHeightPx;
            rect.bottom = rect.top + mPitchItemHeightPx;
        }
        float r = (rect.bottom - rect.top) / 2.0F;
        canvas.drawRoundRect(rect, r, r, pitchItem.isHit ? mHitPitchPaint : mPitchPaint);
    }

    private void drawScore(Canvas canvas) {
        if (mScore == -1) {
            return;
        }
        final int padding = 10;
        final int marginTop = 20;
        String text = getContext().getString(R.string.trtckaraoke_single_score, mScore);
        Paint.FontMetrics fm = mScorePaint.getFontMetrics();
        float textHeight = fm.bottom - fm.top;
        float textWidth = mScorePaint.measureText(text);

        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(0x33FFFFFF);
        Rect rect = new Rect(0, marginTop, (int) (textWidth + 2 * padding),
                (int) (textHeight + 2 * padding + marginTop));
        drawable.setBounds(rect);
        float r = ResourceUtils.dip2px(rect.bottom - rect.top);
        drawable.setCornerRadii(new float[]{0, 0, r, r, r, r, 0, 0});
        drawable.draw(canvas);

        int y = (int) ((rect.bottom - rect.top + textHeight) / 2 - fm.bottom + marginTop);
        canvas.drawText(text, padding, y, mScorePaint);
    }

    private static class PitchItem {
        public boolean isHit = false;
        public final MusicPitchModel musicPitch;

        public final RectF rect = new RectF();

        public final List<PitchItem> hitPitchItems = new ArrayList<>();

        public PitchItem(MusicPitchModel data) {
            this.musicPitch = data;
        }
    }
}
