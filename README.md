# Karaoke

## 概述

**TUI组件化解决方案**是腾讯云TRTC针对直播、语聊、视频通话、Karaoke 等推出的低代码解决方案，依托腾讯在音视频&通信领域的技术积累，帮助开发者快速实现相关业务场景，聚焦核心业务，助力业务起飞！

- [音视频通话-TUICallKit](https://github.com/tencentyun/TUICalling/)
- [多人音视频房间-TUIRoomKit](https://github.com/tencentyun/TUIRoom/)
- [视频互动直播-TUILiveRoom](https://github.com/tencentyun/TUILiveRoom/)
- [语音聊天室-TUIVoiceRoom](https://github.com/tencentyun/TUIVoiceRoom/)
- [在线 K 歌-TUIKaraoke](https://github.com/tencentyun/TUIKaraoke/)

更多组件化方案，敬请期待，也欢迎加入我们的QQ交流群：770645461，期待一起交流&学习！


## 场景描述

在线K 歌场景的解决方案，集成了 腾讯云实时音视频、即时通信、正版曲库直通车等产品，将功能组件化，助您快速开发在线K歌房。在此方案中，歌房里的主播可以点歌成为主唱，跟随歌曲伴奏演唱给歌房内的听众。在演唱过程中： 主唱可以控制歌曲的暂停、播放和切换，并且可以自己调节伴奏和人声音量。 歌房内有歌词板块，唱歌时会根据歌曲播放进度显示对应的歌词。 腾讯云正版曲库直通车提供20万+歌曲曲库，连麦主播可以搜索想唱的歌曲，点歌并查看已点列表。 听众可以通过上麦点歌进行排麦演唱，并随时与房主和其他连麦主播进行实时音频互动。 房间内的角色及描述

| 角色     | 描述                                           |
| -------- | ---------------------------------------------- |
| 房主     | 歌房创建者                                     |
| 连麦主播 | 进入歌房后，通过上麦成为连麦主播               |
| 主唱     | 连麦主播点歌后进行排麦演唱，正在演唱者成为主唱 |
| 听众     | 进入歌房的倾听者                               |

在线 K 歌房场景化解决方案提供以下核心功能：
- **实时音频互动**：超低延时观看，听众实时接收房主和连麦主播的音频流，保证互动的流畅性。
- **互动连麦**：听众可上麦成为连麦主播，房间内所有用户都可以实时收听麦上主播互动。
- **正版曲库**：正版曲库直通车提供超20w热门曲目，全套高精度伴奏歌词，多码率音质灵活应用，搜索/榜单/歌手分类多维选曲。
- **排麦模块**：连麦主播点歌后，歌曲进入已点列表；当同时上麦人数大于 1 时，根据每首点播歌曲的排麦顺序上麦演唱。
- **歌词模块**：歌曲播放时，根据播放进度显示对应的歌词；听众收听的歌曲进度与歌词进度实时同步。

## 效果演示

<table>
     <tr>
         <th>房主麦位操作</th>  
         <th>听众麦位操作</th>  
     </tr>
<tr>
<td><img src="demo_owner.gif" width="300px" height="640px"/></td>
<td><img src="demo_audience.gif" width="300px" height="640px"/></td>
</tr>
</table>

## Demo 体验

| iOS                                                          | Android                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| <img src= https://liteav.sdk.qcloud.com/doc/res/trtc/picture/zh-cn/app_download_ios.png width=150> | <img src= https://main.qcloudimg.com/raw/8a603ced0a61983018c794df842f7029.png width=150> |
## 文档资源

| iOS                                                          | Android                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Karaoke（iOS）](https://cloud.tencent.com/document/product/647/45753)| [Karaoke（Android）](https://cloud.tencent.com/document/product/647/45737)|