package com.tencent.liteav.demo;

import android.content.Intent;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;

import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.EditText;

import com.tencent.liteav.demo.login.HttpLogicRequest;

public class LoginActivity extends AppCompatActivity {
    private static final String TAG = "LoginActivity";

    private EditText mEditUserId;
    private Button   mButtonLogin;

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
        initButtonLogin();
    }

    private void initButtonLogin() {
        mButtonLogin = (Button) findViewById(R.id.tv_login);
        mButtonLogin.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
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
