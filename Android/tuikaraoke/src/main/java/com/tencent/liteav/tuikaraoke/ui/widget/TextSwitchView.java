package com.tencent.liteav.tuikaraoke.ui.widget;

import static android.util.TypedValue.COMPLEX_UNIT_SP;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.drawable.BitmapDrawable;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.widget.Switch;

import com.tencent.liteav.tuikaraoke.R;

public class TextSwitchView extends Switch {

    private Bitmap mBackgroundBitmap;

    public TextSwitchView(Context context) {
        this(context, null);
    }

    public TextSwitchView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    @Override
    protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
        super.onLayout(changed, left, top, right, bottom);
        int w = getWidth();
        int h = getHeight();
        if (w > 0 && h > 0 && mBackgroundBitmap == null) {
            mBackgroundBitmap = createBackgroundBitmap(w, h);
            setBackground(new BitmapDrawable(getResources(), mBackgroundBitmap));
        }
    }

    private Bitmap createBackgroundBitmap(int width, int height) {
        Paint paint = new Paint();
        paint.setAntiAlias(true); // 抗锯齿
        paint.setDither(true); // 防抖动
        paint.setTextSize(TypedValue.applyDimension(COMPLEX_UNIT_SP, 14, getResources().getDisplayMetrics()));
        paint.setColor(getResources().getColor(R.color.trtckaraoke_white_alpha));
        String textOn = getTextOn().toString();
        String textOff = getTextOff().toString();
        Paint.FontMetrics fm = paint.getFontMetrics();
        float measureTextHeight = fm.bottom - fm.top;
        float measureOffWidth = paint.measureText(textOff);
        float measureOnWidth = paint.measureText(textOn);
        int xOff = (int) ((width / 2 - measureOffWidth) / 2);
        int xOn = (int) ((width / 2 - measureOnWidth) / 2 + width / 2);
        int y = (int) ((height + measureTextHeight) / 2 - fm.bottom);
        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        canvas.drawText(textOff, xOff, y, paint);
        canvas.drawText(textOn, xOn, y, paint);
        return bitmap;
    }
}
