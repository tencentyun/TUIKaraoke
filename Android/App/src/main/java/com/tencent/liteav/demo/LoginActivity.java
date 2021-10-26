package com.tencent.liteav.demo;

import android.content.Intent;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.TextPaint;
import android.text.TextUtils;
import android.text.method.LinkMovementMethod;
import android.text.style.ClickableSpan;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.TextView;

import com.blankj.utilcode.util.ToastUtils;
import com.tencent.liteav.demo.login.HttpLogicRequest;

public class LoginActivity extends AppCompatActivity {
    private static final String TAG = "LoginActivity";

    private EditText mEditUserId;
    private Button   mButtonLogin;
    private TextView mTvUserProtocol;
    private CheckBox mCheckBoxProtocol;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);
        initStatusBar();
        initView();
        Log.d(TAG, "*********** Congratulations! You have completed Lab Experiment Step 1！***********");
        HttpLogicRequest.getInstance().initContext(this);
        initData();
    }

    private void initView() {
        mEditUserId = (EditText) findViewById(R.id.et_userId);
        mCheckBoxProtocol = findViewById(R.id.cb_protocol);
        mTvUserProtocol = findViewById(R.id.tv_protocol);
        initButtonLogin();
        updateStatement();
    }

    private void initButtonLogin() {
        mButtonLogin = (Button) findViewById(R.id.tv_login);
        mButtonLogin.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!mCheckBoxProtocol.isChecked()) {
                    ToastUtils.showShort(R.string.app_protocol_tip);
                    return;
                }
                login();
            }
        });
    }

    private void initData() {
        String token = HttpLogicRequest.getInstance().getToken();
        if (!TextUtils.isEmpty(token)) {
            HttpLogicRequest.getInstance().autoLogin(token, new HttpLogicRequest.ActionCallback() {
                @Override
                public void onSuccess() {
                    startMainActivity();
                }

                @Override
                public void onFailed(int code, String msg) {
                    if (code == HttpLogicRequest.ERROR_CODE_NEED_REGISTER) {
                        Intent starter = new Intent(LoginActivity.this, ProfileActivity.class);
                        startActivity(starter);
                        finish();
                    }
                }
            });
        }
    }

    private void login() {
        String userId = mEditUserId.getText().toString().trim();
        if (TextUtils.isEmpty(userId)) {
            ToastUtils.showShort(R.string.hint_user_id);
            return;
        }
        Log.d(TAG, "login: userId = " + userId);
        HttpLogicRequest.getInstance().login(userId, new HttpLogicRequest.ActionCallback() {
            @Override
            public void onSuccess() {
                startMainActivity();
                finish();
            }

            @Override
            public void onFailed(int code, String msg) {
                if (code == HttpLogicRequest.ERROR_CODE_NEED_REGISTER) {
                    Intent starter = new Intent(LoginActivity.this, ProfileActivity.class);
                    startActivity(starter);
                    finish();
                }
            }
        });
    }

    private void startMainActivity() {
        Intent intent = new Intent(LoginActivity.this, MainActivity.class);
        startActivity(intent);
        finish();
    }

    private void updateStatement() {
        final SpannableStringBuilder builder = new SpannableStringBuilder();
        String protocolStart = getString(R.string.app_protocol_start);
        String privacyProtocol = getString(R.string.app_privacy_protocol_detail);
        String userAgreement = getString(R.string.app_user_agreement_detail);
        String protocolAnd = getString(R.string.app_protocol_and);
        builder.append(protocolStart);
        builder.append(privacyProtocol);
        builder.append(protocolAnd);
        builder.append(userAgreement);

        int privacyStartIndex = protocolStart.length();
        int privacyEndIndex = privacyStartIndex + privacyProtocol.length();
        ClickableSpan privacyClickableSpan = new ClickableSpan() {
            @Override
            public void updateDrawState(@NonNull TextPaint ds) {
                super.updateDrawState(ds);
                ds.setColor(getResources().getColor(R.color.app_color_blue));
                ds.setUnderlineText(false);
            }

            @Override
            public void onClick(View widget) {
                Intent intent = new Intent("com.tencent.liteav.action.ktv.webview");
                intent.putExtra("title", getString(R.string.app_privacy_protocol));
                intent.putExtra("url", "https://web.sdk.qcloud.com/document/Tencent-RTC-Privacy-Protection-Guidelines.html");
                startActivity(intent);
            }
        };
        builder.setSpan(privacyClickableSpan, privacyStartIndex, privacyEndIndex, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);

        int userAgreementStartIndex = privacyEndIndex + protocolAnd.length();
        int userAgreementEndIndex = userAgreementStartIndex + userAgreement.length();
        ClickableSpan userAgreementClickableSpan = new ClickableSpan() {
            @Override
            public void updateDrawState(@NonNull TextPaint ds) {
                super.updateDrawState(ds);
                ds.setColor(getResources().getColor(R.color.app_color_blue));
                ds.setUnderlineText(false);
            }

            @Override
            public void onClick(View widget) {
                Intent intent = new Intent("com.tencent.liteav.action.ktv.webview");
                intent.putExtra("title", getString(R.string.app_user_agreement));
                intent.putExtra("url", "https://web.sdk.qcloud.com/document/Tencent-RTC-User-Agreement.html");
                startActivity(intent);
            }
        };
        builder.setSpan(userAgreementClickableSpan, userAgreementStartIndex, userAgreementEndIndex, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);

        mTvUserProtocol.setMovementMethod(LinkMovementMethod.getInstance());
        mTvUserProtocol.setText(builder);
        mTvUserProtocol.setHighlightColor(Color.TRANSPARENT);
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
