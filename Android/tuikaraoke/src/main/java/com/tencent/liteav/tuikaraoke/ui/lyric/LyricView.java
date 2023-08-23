package com.tencent.liteav.tuikaraoke.ui.lyric;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ValueAnimator;
import android.content.Context;
import android.content.res.Resources;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.os.Looper;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.View;
import android.view.animation.LinearInterpolator;

import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.ui.lyric.model.LineInfo;
import com.tencent.liteav.tuikaraoke.ui.lyric.model.LyricInfo;
import com.tencent.liteav.tuikaraoke.ui.lyric.model.WordInfo;

import java.util.List;

public class LyricView extends View {
    private static final String TAG = "LyricView";

    private static final long MAX_SMOOTH_SCROLL_DURATION = 300;

    private Paint mDefaultTextPaint;
    private Paint mHighLightTextPaint;

    private float mDefaultTextHeight;
    private float mHighLightTextHeight;

    private float mDefaultTextSizePx;
    private float mHighLightTextSizePx;

    private float mDefaultTextPy      = 0;
    private float mHighLightTextPy    = 0;

    private int   mDefaultTextColor   = Color.parseColor("#CCFFFFFF");
    private int   mHighLightTextColor = Color.parseColor("#FF8607");

    private int     mLineCount;
    private float   mLineSpace       = 50;
    private int     mCurrentPlayLine = 0;
    private long    mCurrentTimeMillis;
    private long    mCurrentProgressMock;
    private int     mScale           = 3; //设置长歌词从屏幕 1/mScale 处开始滚动到结束停止，当前默认为长歌词播放到1/3之一就开始滚动。
    private boolean mSliding         = false;

    private          String        mDefaultLyricText = "lyric is empty";
    private volatile LyricInfo     mLyricInfo;
    private          ValueAnimator mValueAnimator;
    private final    Path          mHighLightPath    = new Path();

    private ValueAnimator mProgressAnimator;
    private final LinearInterpolator mLinearInterpolator = new LinearInterpolator();

    public LyricView(Context context) {
        super(context);
        initView();
    }

    public LyricView(Context context, AttributeSet attrs) {
        super(context, attrs);
        initView();
    }

    public LyricView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView();
    }

    private void initView() {
        this.setLayerType(View.LAYER_TYPE_HARDWARE, null);
        float defaultTextSizeForPx = getRawSize(TypedValue.COMPLEX_UNIT_SP, 12);

        mDefaultTextSizePx = defaultTextSizeForPx;
        mHighLightTextSizePx = defaultTextSizeForPx;

        initAllPaints();
    }

    private void initAllPaints() {
        mDefaultTextPaint = new Paint();
        mDefaultTextPaint.setDither(true);
        mDefaultTextPaint.setAntiAlias(true);
        mDefaultTextPaint.setTextAlign(Paint.Align.CENTER);
        mDefaultTextPaint.setColor(mDefaultTextColor);
        mDefaultTextPaint.setTextSize(mDefaultTextSizePx);

        mHighLightTextPaint = new Paint();
        mHighLightTextPaint.setDither(true);
        mHighLightTextPaint.setAntiAlias(true);
        mHighLightTextPaint.setTextAlign(Paint.Align.CENTER);
        mHighLightTextPaint.setColor(mHighLightTextColor);
        mHighLightTextPaint.setTextSize(mHighLightTextSizePx);

        Rect lineBound = new Rect();
        mDefaultTextPaint.getTextBounds(mDefaultLyricText, 0, mDefaultLyricText.length(), lineBound);
        mDefaultTextHeight = lineBound.height();
        mHighLightTextPaint.getTextBounds(mDefaultLyricText, 0, mDefaultLyricText.length(), lineBound);
        mHighLightTextHeight = lineBound.height();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        if (mCurrentPlayLine < 0) {
            return;
        }
        final int height = getMeasuredHeight();
        final int width = getMeasuredWidth();
        final int paddingTop = getPaddingTop();

        if (mLyricInfo != null && mLyricInfo.lineList != null && mLyricInfo.lineList.size() > 0) {
            // 绘制歌词第一行
            if ((mCurrentPlayLine - 1 < mLyricInfo.lineList.size()) && (mCurrentPlayLine - 1 >= 0
                    || mCurrentPlayLine == mLyricInfo.lineList.size())) {
                float progress = calculateCurrentKrcProgress(mCurrentProgressMock,
                        mLyricInfo.lineList.get(mCurrentPlayLine - 1));
                drawKaraokeHighLightLrcRow(canvas, mLyricInfo.lineList.get(mCurrentPlayLine - 1).content, progress,
                        width, width * 0.5f, mHighLightTextHeight - mHighLightTextPy + paddingTop);
            }

            if (mCurrentPlayLine < mLyricInfo.lineList.size()) {
                // 绘制歌词第二行
                canvas.drawText(mLyricInfo.lineList.get(mCurrentPlayLine).content, width * 0.5f,
                        mHighLightTextHeight + mLineSpace + mDefaultTextHeight
                                - mDefaultTextPy + paddingTop, mDefaultTextPaint);
            }
        } else {
            // 绘制提示语
            canvas.drawText(mDefaultLyricText, width * 0.5f, (height - mDefaultTextHeight) * 0.5f, mDefaultTextPaint);
        }
    }

    private void drawKaraokeHighLightLrcRow(Canvas canvas, String text, float progress, int width, float rowX,
                                            float rowY) {
        // 保存临时变量 等会儿需要还原，默认文本画笔字体大小
        final float defaultTextSize = mDefaultTextPaint.getTextSize();
        mDefaultTextPaint.setTextSize(mHighLightTextPaint.getTextSize());

        int highLineWidth = (int) mDefaultTextPaint.measureText(text);
        float location = progress * highLineWidth;

        //如果歌词长于屏幕宽度就需要滚动
        if (highLineWidth > rowX * 2) {
            if (location < rowX * 2 / mScale) {
                //歌词当前播放位置未到屏幕1/mScale处不需要滚动
                rowX = (float) (highLineWidth / 2.0);
            } else {
                //歌词当前播放位置超过屏幕1/mScale处开始滚动，滚动到歌词结尾到达屏幕边缘时停止滚动。
                float offsetX = location - (rowX * 2 / mScale);
                float widthGap = highLineWidth - rowX * 2;
                if (offsetX < widthGap) {
                    rowX = highLineWidth / 2.0f - offsetX;
                } else {
                    rowX = highLineWidth / 2.0f - widthGap;
                }
            }
        }

        // 先画一层普通颜色的
        canvas.drawText(text, rowX, rowY, mDefaultTextPaint);

        // 再画一层高亮颜色的

        float leftOffset = rowX - highLineWidth / 2f;
        // 高亮的宽度
        int highWidth = (int) (progress * highLineWidth);

        if (highWidth > 1 && ((int) (rowY * 2)) > 1) {
            final int storeCount = canvas.save();

            mHighLightPath.reset();
            mHighLightPath.addRect(leftOffset, rowY - mHighLightTextHeight,
                    leftOffset + highWidth, rowY + mLineSpace, Path.Direction.CW);
            canvas.clipPath(mHighLightPath);
            canvas.drawText(text, rowX, rowY, mHighLightTextPaint);

            canvas.restoreToCount(storeCount);
        }

        // 还原，默认文本画笔字体大小
        mDefaultTextPaint.setTextSize(defaultTextSize);
    }


    private void invalidateView() {
        if (Looper.getMainLooper() == Looper.myLooper()) {
            invalidate();
        } else {
            postInvalidate();
        }
    }

    private void smoothScroll(final int toPosition) {
        mSliding = true;
        mHighLightTextPaint.setColor(mHighLightTextColor);
        mDefaultTextPaint.setColor(mDefaultTextColor);
        // 数值计算动效
        mValueAnimator = ValueAnimator.ofFloat(0, 1);

        mValueAnimator.setDuration(MAX_SMOOTH_SCROLL_DURATION);
        mValueAnimator.addUpdateListener(new ValueAnimator.AnimatorUpdateListener() {
            @Override
            public void onAnimationUpdate(ValueAnimator animation) {
                // 计算所有动效数值
                // 计算字体大小
                mHighLightTextPaint.setTextSize((mDefaultTextSizePx - mHighLightTextSizePx)
                        * animation.getAnimatedFraction() + mHighLightTextSizePx);
                mDefaultTextPaint.setTextSize((mHighLightTextSizePx - mDefaultTextSizePx)
                        * animation.getAnimatedFraction() + mDefaultTextSizePx);
                // 计算歌词位移
                mHighLightTextPy = (mHighLightTextHeight + mLineSpace) * animation.getAnimatedFraction();
                mDefaultTextPy = (mDefaultTextHeight + mLineSpace) * animation.getAnimatedFraction();
                invalidateView();
            }
        });
        mValueAnimator.addListener(new AnimatorListenerAdapter() {

            @Override
            public void onAnimationEnd(Animator animation) {
                // 重置变量
                if (mCurrentPlayLine != toPosition) {
                    mCurrentPlayLine = toPosition;
                    // 重置字体大小
                    mHighLightTextPaint.setTextSize(mHighLightTextSizePx);
                    mDefaultTextPaint.setTextSize(mDefaultTextSizePx);
                    // 重置偏移量
                    mHighLightTextPy = 0;
                    mDefaultTextPy = 0;
                    // 重新设置字体颜色
                    mHighLightTextPaint.setColor(mHighLightTextColor);
                    mDefaultTextPaint.setColor(mDefaultTextColor);
                    // 重置滑动标识
                    mSliding = false;
                    invalidateView();
                }
            }
        });
        mValueAnimator.start();
    }

    private boolean isScrollable() {
        return mLyricInfo != null && mLyricInfo.lineList != null && mLyricInfo.lineList.size() > 0;
    }

    private void scrollToCurrentTimeMillis(long time) {
        int position = 0;
        if (isScrollable()) {
            for (int i = 0, size = mLineCount; i < size; i++) {
                LineInfo lineInfo = mLyricInfo.lineList.get(i);
                if (lineInfo != null && lineInfo.start > time) {
                    position = i;
                    break;
                }
                if (i == mLineCount - 1) {
                    position = mLineCount;
                }
            }
        }

        if (mCurrentPlayLine != position && !mSliding) {
            smoothScroll(position);
        }
    }

    private void resetLyricInfo() {
        if (mLyricInfo != null) {
            if (mLyricInfo.lineList != null) {
                mLyricInfo.lineList.clear();
                mLyricInfo.lineList = null;
            }
            mLyricInfo = null;
        }
    }


    private void resetView() {
        resetLyricInfo();
        invalidateView();
        // 停止歌词滚动动效
        if (mValueAnimator != null) {
            mValueAnimator.cancel();
        }
        mLineCount = 0;
        mDefaultTextPy = 0;
        mHighLightTextPy = 0;
    }

    private float getRawSize(int unit, float size) {
        Context context = getContext();
        Resources resources;
        if (context == null) {
            resources = Resources.getSystem();
        } else {
            resources = context.getResources();
        }
        return TypedValue.applyDimension(unit, size, resources.getDisplayMetrics());
    }

    /**
     * 逐字播放模式下，根据当前播放的时间戳计算出这一行文字的百分比进度
     * 因为一行中不同的词语占用的时间比重是不均匀的，所以不是一个简单的线性函数（是一个折线函数，单个词语视为线性的），需要单独处理
     *
     * @param currentTimeMillis 当前播放的时间戳
     * @param lineInfo          当前行model
     */
    private float calculateCurrentKrcProgress(long currentTimeMillis, LineInfo lineInfo) {
        List<WordInfo> words = lineInfo.wordList;
        long offsetTime = currentTimeMillis - lineInfo.start;

        WordInfo lastWord;
        // 念完所有字所花费的总时长
        long allWordDuration = 0L;
        if (words.size() > 0) {
            lastWord = words.get(words.size() - 1);
            allWordDuration = lastWord.offset + lastWord.duration;
        }

        float progressAll = 0f;
        if (offsetTime < allWordDuration) {
            for (int i = 0; i < words.size(); i++) {
                WordInfo currentWordInfo = words.get(i);
                if (offsetTime >= currentWordInfo.offset
                        && offsetTime <= currentWordInfo.offset + currentWordInfo.duration) {
                    // 在这个词组区间内
                    // 算出之前所有词组的时间占比
                    float progressBefore = i / (float) words.size();
                    // 这个词组占的比重，按份数来算
                    float percent = 1 / (float) words.size();
                    // 在计算当前时间戳在这个词组内的时间占比，线性
                    float progressCurrentWord =
                            (offsetTime - currentWordInfo.offset) / (float) currentWordInfo.duration;
                    // 这两个progress加起来就是总的时间百分比
                    progressAll = progressBefore + progressCurrentWord * percent;
                    break;
                } else if (i < words.size() - 1) {
                    // 不是最后一个字
                    WordInfo nextWordInfo = words.get(i + 1);
                    // 时间在两个字之间的时间间隔
                    // 这里按理来说是不应该被高亮的时间段，即百分比计算出来是不变的
                    if (offsetTime > currentWordInfo.offset + currentWordInfo.duration
                            && offsetTime < nextWordInfo.offset) {
                        progressAll = (i + 1) / (float) words.size();
                    }
                }
            }
        } else {
            progressAll = 1f;
        }
        return progressAll;
    }

    /**
     * 设置逐行、逐字歌词，
     * 需要先调用 setupLyric 设置歌词数据后，再调用 setCurrentTimeMillis(long current) 方法，才能将歌词展示出来
     *
     * @param lyricInfo info model
     */
    public void setupLyric(LyricInfo lyricInfo) {
        resetView();
        mCurrentPlayLine = 0;
        if (lyricInfo != null) {
            mLyricInfo = lyricInfo;
            mLineCount = mLyricInfo.lineList.size();
        } else {
            mDefaultLyricText = getContext().getString(R.string.trtckaraoke_lyric_empty_hint);
        }
        invalidateView();
    }

    /**
     * 设置当前时间显示位置
     *
     * @param current 时间戳
     */
    public void updateLyricsPlayProgress(long current) {
        long lastInterval = current - mCurrentTimeMillis;
        mCurrentTimeMillis = current;
        // 估算下次progress值 = 当前progress + 上次进度间隔
        long nextProgress = current + lastInterval;
        startProgressAnimator(nextProgress);
        scrollToCurrentTimeMillis(current);
    }

    /**
     * 正常歌词进度更新间隔大约是200ms，在这个200ms间隔内，再加一个动画使进度产生更加小的均匀变化
     *
     * @param progress
     */
    private void startProgressAnimator(long progress) {
        final long progressInterval = progress - mCurrentTimeMillis;
        final long lastProgress = mCurrentTimeMillis;
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
            mCurrentProgressMock = (long) (lastProgress + fraction * progressInterval);
            invalidateView();
        });
        mProgressAnimator.start();
    }

    /**
     * 重置、设置歌词内容被重置后的提示内容
     *
     * @param message 提示内容
     */
    public void reset(String message) {
        mDefaultLyricText = message;
        resetView();
    }

    /**
     * 设置默认文本内容字体大小
     */
    public void setDefaultTextSizeSp(float size) {
        float textSizePx = getRawSize(TypedValue.COMPLEX_UNIT_SP, size);
        mDefaultTextSizePx = textSizePx;
        mDefaultTextPaint.setTextSize(textSizePx);
        Rect lineBound = new Rect();
        mDefaultTextPaint.getTextBounds(mDefaultLyricText, 0, mDefaultLyricText.length(), lineBound);
        mDefaultTextHeight = lineBound.height();
        invalidateView();
    }

    /**
     * 设置高亮字体大小
     */
    public void setHighLightTextSizeSp(float size) {
        float textSizePx = getRawSize(TypedValue.COMPLEX_UNIT_SP, size);
        mHighLightTextSizePx = textSizePx;
        mHighLightTextPaint.setTextSize(textSizePx);
        Rect lineBound = new Rect();
        mHighLightTextPaint.getTextBounds(mDefaultLyricText, 0, mDefaultLyricText.length(), lineBound);
        mHighLightTextHeight = lineBound.height();
        invalidateView();
    }
}
