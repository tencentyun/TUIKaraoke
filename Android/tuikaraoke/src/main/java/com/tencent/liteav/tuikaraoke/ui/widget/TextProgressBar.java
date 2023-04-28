package com.tencent.liteav.tuikaraoke.ui.widget;

import static android.util.TypedValue.COMPLEX_UNIT_SP;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Shader;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.widget.ProgressBar;

import com.tencent.liteav.tuikaraoke.R;

public class TextProgressBar extends ProgressBar {

    protected final Context context;

    private String text = "";

    private Paint mPaint = new Paint();

    private int mNormalColor = Color.WHITE;
    private int mHighLightColor;

    public TextProgressBar(Context context) {
        this(context, null);
    }

    public TextProgressBar(Context context, AttributeSet attrs) {
        super(context, attrs);
        this.context = context;
        mHighLightColor = getResources().getColor(R.color.trtckaraoke_color_progress);
        mPaint.setTextSize(TypedValue.applyDimension(COMPLEX_UNIT_SP, 14, getResources().getDisplayMetrics()));
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (TextUtils.isEmpty(text)) {
            return;
        }

        Paint paint = mPaint;
        Paint.FontMetrics fm = paint.getFontMetrics();
        final int realTextHeight = (int) (-fm.leading - fm.ascent + fm.descent);
        float textWidth = paint.measureText(text);
        float measureTextHeight = fm.descent - fm.ascent;

        int x = (int) ((getWidth() - textWidth) / 2);
        int y = (int) ((getHeight() + measureTextHeight) / 2 - fm.descent);

        canvas.save();

        LinearGradient linearGradient = new LinearGradient(x, y + (fm.ascent + fm.descent),
                    x, y, new int[]{mNormalColor, mNormalColor}, null, Shader.TileMode.CLAMP);
        paint.setShader(linearGradient);
        canvas.drawText(text, x, y, paint);

        float progress = getProgress() / 100.0F;
        float r = getWidth() * progress;
        r = r < 0 ? 0 : r;
        canvas.clipRect(x, y - realTextHeight, r, y + realTextHeight);

        LinearGradient linearGradientHL = new LinearGradient(x, y - realTextHeight,
                    x, y, new int[]{mHighLightColor, mHighLightColor}, null, Shader.TileMode.CLAMP);

        paint.setShader(linearGradientHL);
        canvas.drawText(text, x, y, paint);
        canvas.restore();
    }

    public void setText(CharSequence text) {
        this.text = String.valueOf(text);
        invalidate();
    }

    @Override
    public void setEnabled(boolean enabled) {
        super.setEnabled(enabled);
        if (enabled) {
            mNormalColor = Color.WHITE;
            setBackgroundResource(R.drawable.trtckaraoke_button_border);
        } else {
            mNormalColor = getResources().getColor(R.color.trtckaraoke_color_progress_bg);
            setBackgroundResource(R.drawable.trtckaraoke_button_choose_song);
        }
        invalidate();
    }
}
