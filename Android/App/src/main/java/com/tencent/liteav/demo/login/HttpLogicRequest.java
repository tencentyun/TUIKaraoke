package com.tencent.liteav.demo.login;

import android.content.Context;
import android.text.TextUtils;
import android.util.Log;

import com.blankj.utilcode.util.SPUtils;
import com.blankj.utilcode.util.ToastUtils;
import com.tencent.liteav.basic.UserModel;
import com.tencent.liteav.basic.UserModelManager;
import com.tencent.liteav.demo.R;

import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.charset.UnsupportedCharsetException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import okhttp3.Interceptor;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.ResponseBody;
import okio.Buffer;
import okio.BufferedSource;
import retrofit2.Call;

import retrofit2.Callback;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import retrofit2.http.GET;
import retrofit2.http.QueryMap;

public class HttpLogicRequest {
    private static final HttpLogicRequest mOurInstance = new HttpLogicRequest();

    private static final String TAG                      = "HttpLogicRequest";
    public static final  int    ERROR_CODE_UNKNOWN       = -1;
    public static final  int    ERROR_CODE_NEED_REGISTER = -2;

    private static final String PER_DATA         = "per_profile_manager";
    private static final String PER_USER_ID      = "per_user_id";
    private static final String PER_APAASUSER_ID = "per_apaasuser_id";
    private static final String PER_TOKEN        = "per_user_token";
    private static final String PER_SDK_APP_ID   = "per_sdk_app_id";

    //您需要在这里替换你在腾讯云发布日志中获取API网关地址，例如：
    //https://service-xxxyyzzz-xxxxxxxxxx.gz.apigw.tencentcs.com
    private static final String HTTP_BASE_URL     = PLACEHOLDER;
    private static final String ENCRYPTION_METHOD = "md5"; //加密方法

    private String                         mToken;
    private Retrofit                       mRetrofit;
    private Api                            mApi;
    private Call<ResponseEntity<UserInfo>> mLoginCall;
    private UserInfo                       mUserInfo;

    private Context mContext;
    private String  mUserId;
    private String  mSdkAppid;
    private String  mApaasUserId;
    private boolean mIsLogin;

    public static HttpLogicRequest getInstance() {
        return mOurInstance;
    }

    public void initContext(Context context) {
        mContext = context;
    }

    private HttpLogicRequest() {
        OkHttpClient.Builder builder = new OkHttpClient.Builder();
        builder.addInterceptor(new HttpLogInterceptor());
        mRetrofit = new Retrofit.Builder()
                .baseUrl(HTTP_BASE_URL)
                .client(builder.build())
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        mApi = mRetrofit.create(Api.class);
    }

    public String getToken() {
        if (mToken == null) {
            loadToken();
        }
        return mToken;
    }

    public void setToken(String token) {
        mToken = token;
        SPUtils.getInstance(PER_DATA).put(PER_TOKEN, mToken);
    }

    private void loadToken() {
        mToken = SPUtils.getInstance(PER_DATA).getString(PER_TOKEN, "");
    }

    public void setApaasUserId(String apaasUserId) {
        mApaasUserId = apaasUserId;
        SPUtils.getInstance(PER_DATA).put(PER_APAASUSER_ID, mApaasUserId);
    }

    public String getApaasUserId() {
        if (mApaasUserId == null) {
            mApaasUserId = SPUtils.getInstance(PER_DATA).getString(PER_APAASUSER_ID, "");
        }
        return mApaasUserId;
    }

    public void setUserId(String userId) {
        mUserId = userId;
        SPUtils.getInstance(PER_DATA).put(PER_USER_ID, mUserId);
    }

    public String getUserId() {
        if (mUserId == null) {
            mUserId = SPUtils.getInstance(PER_DATA).getString(PER_USER_ID, "");
        }
        return mUserId;
    }

    public void setSdkAppId(String sdkAppid) {
        mSdkAppid = sdkAppid;
        SPUtils.getInstance(PER_DATA).put(PER_SDK_APP_ID, mSdkAppid);
    }

    public int getSdkAppId() {
        if (mSdkAppid == null) {
            mSdkAppid = SPUtils.getInstance(PER_DATA).getString(PER_SDK_APP_ID, "");
        }
        if (mSdkAppid == "") {
            return 0;
        }
        return Integer.parseInt(mSdkAppid);
    }

    public void login(String userName, final ActionCallback callback) {
        if (mLoginCall != null) {
            mLoginCall.cancel();
            mUserInfo = null;
        }

        StringBuilder str = new StringBuilder();
        str.append(userName);
        str.append(ENCRYPTION_METHOD);
        String signature = md5(str.toString());
        // 构造请求参数
        Map<String, String> data = new LinkedHashMap<>();
        data.put("username", userName);
        data.put("signature", signature);
        data.put("hash", ENCRYPTION_METHOD);
        mLoginCall = mApi.login(data);
        internalLogin(data, callback);
    }

    public void autoLogin(String token, final ActionCallback callback) {
        if (mLoginCall != null) {
            mLoginCall.cancel();
            mUserInfo = null;
        }

        if (TextUtils.isEmpty(mUserId)) {
            mUserId = getUserId();
        }
        if (TextUtils.isEmpty(mApaasUserId)) {
            mApaasUserId = getApaasUserId();
        }
        Map<String, String> data = new LinkedHashMap<>();
        data.put("userId", mUserId);
        data.put("token", token);
        data.put("apaasUserId", mApaasUserId);
        mLoginCall = mApi.autologin(data);
        internalLogin(data, callback);
    }

    private void internalLogin(Map<String, String> data, final ActionCallback callback) {
        mLoginCall.enqueue(new Callback<ResponseEntity<UserInfo>>() {
            @Override
            public void onResponse(Call<ResponseEntity<UserInfo>> call, retrofit2.Response<ResponseEntity<UserInfo>> response) {
                ResponseEntity<UserInfo> res = response.body();
                if (res == null) {
                    callback.onFailed(ERROR_CODE_UNKNOWN, "data is null");
                    return;
                }
                Log.d(TAG, "internalLogin : res = " + res);
                if (res.errorCode == 0 && res.data != null) {
                    UserInfo userInfo = res.data;
                    mUserInfo = userInfo;
                    setToken(userInfo.token);
                    setUserId(userInfo.userId);
                    setApaasUserId(userInfo.apaasUserId);
                    setSdkAppId(userInfo.sdkAppId);
                    final UserModel userModel = new UserModel();
                    userModel.phone = userInfo.phone;
                    userModel.userId = userInfo.userId;
                    if (!TextUtils.isEmpty(userInfo.sdkUserSig)) {
                        userModel.userSig = userInfo.sdkUserSig;
                    }

                    final UserModelManager userModelManager = UserModelManager.getInstance();
                    userModelManager.setUserModel(userModel);
                    //登录IM
                    loginIM(userModel, new ActionCallback() {
                        @Override
                        public void onSuccess() {
                            userModelManager.setUserModel(userModel);
                            callback.onSuccess();
                        }

                        @Override
                        public void onFailed(int code, String msg) {
                            callback.onFailed(code, msg);
                        }
                    });
                } else {
                    mIsLogin = false;
                    setToken("");
                    setUserId("");
                    setApaasUserId("");
                    setSdkAppId("");
                    callback.onFailed(res.errorCode, res.errorMessage);
                }
            }

            @Override
            public void onFailure(Call<ResponseEntity<UserInfo>> call, Throwable t) {
                mIsLogin = false;
                Log.d(TAG, "onFailure: t = " + t);
                callback.onFailed(ERROR_CODE_UNKNOWN, t.toString());
            }
        });
    }

    private void loginIM(final UserModel userModel, final ActionCallback callback) {
        if (mContext == null) {
            Log.d(TAG, "login im failed, context is null");
            return;
        }
        final IMManager imManager = IMManager.sharedInstance();
        imManager.initIMSDK(mContext);
        imManager.login(userModel.userId, userModel.userSig, new IMManager.ActionCallback() {
            @Override
            public void onSuccess() {
                //1. 登录IM成功
                ToastUtils.showLong(mContext.getString(R.string.app_toast_login_success));
                imManager.getUserInfo(userModel.userId, new IMManager.UserCallback() {
                    @Override
                    public void onCallback(int code, String msg, IMUserInfo userInfo) {
                        if (code == 0) {
                            if (userInfo == null) {
                                callback.onFailed(ERROR_CODE_UNKNOWN, "user info get is null");
                                return;
                            }
                            // 如果说第一次没有设置用户名，跳转注册用户名
                            if (TextUtils.isEmpty(userInfo.userName)) {
                                callback.onFailed(ERROR_CODE_NEED_REGISTER, mContext.getString(R.string.app_not_register));
                            } else {
                                userModel.userName = userInfo.userName;
                                userModel.userAvatar = userInfo.userAvatar;
                                callback.onSuccess();
                            }
                        } else {
                            callback.onFailed(code, msg);
                        }
                    }
                });
            }

            @Override
            public void onFailed(int code, String msg) {
                // 登录IM失败
                callback.onFailed(code, msg);
                ToastUtils.showLong(mContext.getString(R.string.app_toast_login_fail, code, msg));
            }
        });
    }

    //更新用户信息
    public void userUpdate(final String nickName, final String avatarUrl, final ActionCallback callback) {
        // 构造注销请求参数
        if (TextUtils.isEmpty(mToken)) {
            mToken = getToken();
        }

        if (TextUtils.isEmpty(mApaasUserId)) {
            mApaasUserId = getApaasUserId();
        }

        Map<String, String> data = new LinkedHashMap<>();
        data.put("apaasUserId", mApaasUserId);
        data.put("token", mToken);
        data.put("name", nickName);
        Call<ResponseEntityEmpty> userUpdateCall = mApi.userUpdate(data);
        userUpdateCall.enqueue(new Callback<ResponseEntityEmpty>() {
            @Override
            public void onResponse(final Call<ResponseEntityEmpty> call, retrofit2.Response<ResponseEntityEmpty> response) {
                if (response == null || response.body() == null) {
                    Log.d(TAG, "userUpdate failed");
                    return;
                }
                final int errCode = response.body().errorCode;
                String errMsg = response.body().errorMessage;
                if (errCode == 0) {
                    //后台登录成功后,更新IM信息
                    setNicknameAndAvatar(nickName, avatarUrl, callback);
                } else {
                    callback.onFailed(errCode, errMsg);
                    ToastUtils.showLong(mContext.getString(R.string.app_toast_failed_to_set_username), errMsg);
                }
            }

            @Override
            public void onFailure(Call<ResponseEntityEmpty> call, Throwable t) {
                callback.onFailed(ERROR_CODE_UNKNOWN, "unknown error");
            }
        });
    }

    public void setNicknameAndAvatar(final String nickname, final String avatarUrl, final ActionCallback callback) {
        IMManager.sharedInstance().setNicknameAndAvatar(nickname, avatarUrl, new IMManager.Callback() {
            @Override
            public void onCallback(int errorCode, String message) {
                if (errorCode == 0) {
                    UserModel userModel = UserModelManager.getInstance().getUserModel();
                    userModel.userAvatar = avatarUrl;
                    userModel.userName = nickname;
                    UserModelManager.getInstance().setUserModel(userModel);
                    callback.onSuccess();
                } else {
                    callback.onFailed(errorCode, message);
                    ToastUtils.showLong(mContext.getString(R.string.app_toast_failed_to_set_username), message);
                }
            }
        });
    }

    public void setAvatar(final String avatar, final HttpLogicRequest.ActionCallback callback) {
        IMManager.sharedInstance().setAvatar(avatar, new IMManager.Callback() {
            @Override
            public void onCallback(int errorCode, String message) {
                if (errorCode == 0) {
                    UserModel userModel = UserModelManager.getInstance().getUserModel();
                    userModel.userAvatar = avatar;
                    UserModelManager.getInstance().setUserModel(userModel);
                    callback.onSuccess();
                } else {
                    callback.onFailed(errorCode, message);
                    ToastUtils.showLong(mContext.getString(R.string.app_toast_failed_to_set_username), message);
                }
            }
        });
    }

    //md5加密方法
    public static String md5(String string) {
        byte[] hash;
        try {
            hash = MessageDigest.getInstance("MD5").digest(string.getBytes(StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Huh, MD5 should be supported?", e);
        }
        StringBuilder hex = new StringBuilder(hash.length * 2);
        for (byte b : hash) {
            int i = (b & 0xFF);
            if (i < 0x10) hex.append('0');
            hex.append(Integer.toHexString(i));
        }
        return hex.toString();
    }

    /**
     * ==== 网络层相关 ====
     */
    private interface Api {

        @GET("base/v1/oauth/signature")
        Call<ResponseEntity<UserInfo>> login(@QueryMap Map<String, String> map);

        @GET("base/v1/auth_users/user_login_token")
        Call<ResponseEntity<UserInfo>> autologin(@QueryMap Map<String, String> map);

        @GET("base/v1/auth_users/user_update")
        Call<ResponseEntityEmpty> userUpdate(@QueryMap Map<String, String> map);

    }

    private class ResponseEntityEmpty {
        public int    errorCode;
        public String errorMessage;
    }

    private class ResponseEntity<T> {
        public int    errorCode;
        public String errorMessage;
        public T      data;
    }

    private class UserInfo {
        public String userId;
        public String apaasAppId;
        public String apaasUserId;
        public String sdkAppId;
        public String sdkUserSig;
        public String token;
        public String expire;
        public String phone;
        public String email;
        public String name;
        public String avatar;

        @Override
        public String toString() {
            return "UserInfo{" +
                    "userId='" + userId + '\'' +
                    ", apaasAppId='" + apaasAppId + '\'' +
                    ", apaasUserId='" + apaasUserId + '\'' +
                    ", sdkAppId='" + sdkAppId + '\'' +
                    ", sdkUserSig='" + sdkUserSig + '\'' +
                    ", token='" + token + '\'' +
                    ", expire='" + expire + '\'' +
                    ", phone='" + phone + '\'' +
                    ", email='" + email + '\'' +
                    ", name='" + name + '\'' +
                    ", avatar='" + avatar + '\'' +
                    '}';
        }
    }

    /**
     * okhttp 拦截器
     */

    public static class HttpLogInterceptor implements Interceptor {
        private static final String  TAG  = "HttpLogInterceptor";
        private final        Charset UTF8 = Charset.forName("UTF-8");

        @Override
        public Response intercept(Chain chain) throws IOException {
            Request request = chain.request();
            RequestBody requestBody = request.body();
            String body = null;
            if (requestBody != null) {
                Buffer buffer = new Buffer();
                requestBody.writeTo(buffer);
                Charset charset = UTF8;
                MediaType contentType = requestBody.contentType();
                if (contentType != null) {
                    charset = contentType.charset(UTF8);
                }
                body = buffer.readString(charset);
            }

            Log.d(TAG, "发送请求: method：" + request.method()
                    + "\nurl：" + request.url()
                    + "\n请求头：" + request.headers()
                    + "\n请求参数: " + body);

            long startNs = System.nanoTime();
            Response response = chain.proceed(request);
            long tookMs = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - startNs);

            ResponseBody responseBody = response.body();
            String rBody;

            BufferedSource source = responseBody.source();
            source.request(Long.MAX_VALUE);
            Buffer buffer = source.buffer();

            Charset charset = UTF8;
            MediaType contentType = responseBody.contentType();
            if (contentType != null) {
                try {
                    charset = contentType.charset(UTF8);
                } catch (UnsupportedCharsetException e) {
                    e.printStackTrace();
                }
            }
            rBody = buffer.clone().readString(charset);

            Log.d(TAG, "收到响应: code:" + response.code()
                    + "\n请求url：" + response.request().url()
                    + "\n请求body：" + body
                    + "\nResponse: " + rBody);

            return response;
        }
    }

    // 操作回调
    public interface ActionCallback {
        void onSuccess();

        void onFailed(int code, String msg);
    }

    // IM登录回调
    public interface IMActionCallback {
        void onSuccess();

        void onFailed(int code, String msg);
    }
}
