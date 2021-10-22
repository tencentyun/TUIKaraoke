package com.tencent.liteav.demo.login;

import android.content.Context;
import android.text.TextUtils;
import android.view.View;

import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.blankj.utilcode.util.ToastUtils;
import com.google.android.material.bottomsheet.BottomSheetDialog;
import com.tencent.liteav.basic.AvatarConstant;
import com.tencent.liteav.basic.UserModel;
import com.tencent.liteav.basic.UserModelManager;
import com.tencent.liteav.demo.R;

import java.util.Arrays;
import java.util.List;

public class ModifyUserAvatarDialog extends BottomSheetDialog {
    private UserModel             mUserModel;
    private Context               mContext;
    private ModifySuccessListener mListener;
    private RecyclerView          mRvAvatar;
    private String                mSelectAvatarUrl;

    public ModifyUserAvatarDialog(Context context, ModifySuccessListener listener) {
        super(context, R.style.KaraokeBottomDialog);
        mUserModel = UserModelManager.getInstance().getUserModel();
        if (mUserModel == null) {
            dismiss();
            return;
        }
        mContext = context;
        mListener = listener;
        setContentView(R.layout.karaoke_dialog_avatar_modify);
        mRvAvatar = findViewById(R.id.rv_avatar);
        GridLayoutManager gridLayoutManager = new GridLayoutManager(context, 4);
        mRvAvatar.setLayoutManager(gridLayoutManager);
        String[] avatarArr = AvatarConstant.USER_AVATAR_ARRAY;
        List<String> avatarList = Arrays.asList(avatarArr);
        AvatarListAdapter adapter = new AvatarListAdapter(context, avatarList, new AvatarListAdapter.OnItemClickListener() {
            @Override
            public void onItemClick(String avatarUrl) {
                mSelectAvatarUrl = avatarUrl;
            }
        });
        mRvAvatar.setAdapter(adapter);
        findViewById(R.id.confirm).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                setProfile(mSelectAvatarUrl);
            }
        });
    }

    private void setProfile(final String avatarUrl) {
        if (TextUtils.isEmpty(avatarUrl) || mUserModel.userId == null) {
            return;
        }
        HttpLogicRequest.getInstance().setAvatar(avatarUrl, new HttpLogicRequest.ActionCallback() {
            @Override
            public void onSuccess() {
                ToastUtils.showLong(mContext.getString(R.string.app_toast_success_to_set_username));
                mListener.onSuccess();
                dismiss();
            }

            @Override
            public void onFailed(int code, String msg) {
                ToastUtils.showLong(mContext.getString(R.string.app_toast_failed_to_set_username, msg));
            }
        });
    }

    public interface ModifySuccessListener {
        void onSuccess();
    }
}