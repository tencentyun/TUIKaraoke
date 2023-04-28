package com.tencent.liteav.tuikaraoke.ui.widget;

import android.app.Dialog;
import android.app.DialogFragment;
import android.graphics.Typeface;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import com.tencent.liteav.tuikaraoke.R;

public class ConfirmDialogFragment extends DialogFragment {
    private PositiveClickListener mPositiveClickListener;
    private NegativeClickListener mNegativeClickListener;

    private String mMessageText;
    private String mPositiveButtonText;
    private String mNegativeButtonText;

    private int mPositiveTextColor = -1;
    private int mNegativeTextColor = -1;
    private boolean mMessageUseBoldStyle = true; // Message采用粗体（默认为true）

    @Override
    public Dialog onCreateDialog(Bundle savedInstanceState) {
        final Dialog dialog = new Dialog(getActivity(), R.style.TRTCKTVRoomDialogTheme);
        dialog.setContentView(R.layout.trtckaraoke_dialog_confirm);
        dialog.setCancelable(false);
        initTextMessage(dialog);
        initButtonPositive(dialog);
        initButtonNegative(dialog);
        return dialog;
    }

    private void initTextMessage(Dialog dialog) {
        TextView textMessage = (TextView) dialog.findViewById(R.id.tv_message);
        textMessage.setText(mMessageText);
        if (!mMessageUseBoldStyle) {
            textMessage.setTypeface(Typeface.create(textMessage.getTypeface(), Typeface.NORMAL), Typeface.NORMAL);
            textMessage.invalidate();
        }
    }

    private void initButtonPositive(Dialog dialog) {
        Button buttonPositive = (Button) dialog.findViewById(R.id.btn_positive);

        if (mPositiveClickListener == null) {
            buttonPositive.setVisibility(View.GONE);
            return;
        }

        if (!TextUtils.isEmpty(mPositiveButtonText)) {
            buttonPositive.setText(mPositiveButtonText);
        }

        if (mPositiveTextColor != -1) {
            buttonPositive.setTextColor(mPositiveTextColor);
        }

        buttonPositive.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mPositiveClickListener.onClick();
            }
        });
    }

    private void initButtonNegative(Dialog dialog) {
        Button buttonNegative = (Button) dialog.findViewById(R.id.btn_negative);

        if (mNegativeClickListener == null) {
            buttonNegative.setVisibility(View.GONE);
            return;
        }

        if (!TextUtils.isEmpty(mNegativeButtonText)) {
            buttonNegative.setText(mNegativeButtonText);
        }

        if (mNegativeTextColor != -1) {
            buttonNegative.setTextColor(mNegativeTextColor);
        }

        buttonNegative.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mNegativeClickListener.onClick();
            }
        });
    }

    public void setMessage(String message) {
        mMessageText = message;
    }

    public void setMessageUseBoldStyle(boolean messageUseBoldStyle) {
        mMessageUseBoldStyle = messageUseBoldStyle;
    }

    public void setPositiveButtonText(String text) {
        mPositiveButtonText = text;
    }

    public void setNegativeButtonText(String text) {
        mNegativeButtonText = text;
    }

    public void setPositiveTextColor(int color) {
        mPositiveTextColor = color;
    }

    public void setNegativeTextColor(int color) {
        mNegativeTextColor = color;
    }

    public void setPositiveClickListener(PositiveClickListener listener) {
        this.mPositiveClickListener = listener;
    }

    public void setNegativeClickListener(NegativeClickListener listener) {
        this.mNegativeClickListener = listener;
    }

    public interface PositiveClickListener {
        void onClick();
    }

    public interface NegativeClickListener {
        void onClick();
    }

}
