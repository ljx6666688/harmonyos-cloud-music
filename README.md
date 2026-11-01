# 黑马云音乐 · HarmonyOS 云音乐 App

基于 **HarmonyOS NEXT / ArkTS / ArkUI** 实现的云音乐播放器练习项目。参考黑马程序员鸿蒙教程完成，
并在教程之外做了若干自主扩展与问题修复（详见「自主实现与问题修复」一节）。

> 本项目为学习用途的个人练习作品，非商业产品。UI 布局参考主流音乐 App。

---

## 功能

- **推荐页**：顶部轮播、每日推荐横滑卡片、推荐歌单网格
- **发现页**：歌曲列表，每行提供独立播放按钮，点击即进播放页播放指定曲目
- **动态页**：互动广场，展示用户动态与分享歌曲卡片
- **我的页**：封面墙 + 用户头像/昵称/标签与关注数据
- **播放页**：
  - AVPlayer 驱动的完整播放控制（播放/暂停、上一首/下一首、播完自动续播）
  - 进度条拖动 seek、实时进度与总时长同步
  - 唱片自转 + 唱针抬落联动动画，转动画随播放状态暂停/恢复
  - 播放列表面板，支持点击切歌与左右滑动删除

---

## 技术栈

| 分类 | 使用 |
|---|---|
| 语言 / 框架 | ArkTS、ArkUI（声明式） |
| 状态管理 | ArkUI V2：`@ComponentV2`、`@Local`、`@Param` |
| 页面路由 | `Navigation` + `NavDestination` + `NavPathStack` |
| 媒体播放 | `@kit.MediaKit` 的 `AVPlayer` |
| 资源 | `resources/base/media`（图标/封面）、`resources/rawfile`（音频） |
| 工具 | DevEco Studio 6.x、hvigor |

---

## 项目结构

```
entry/src/main/ets/
├── common/
│   └── SongData.ets        # 共享歌单、轮播图数据（收敛课程中重复的两份数据）
├── models/
│   └── music.ets           # SongItemType / TabItem / 各页面数据类型
├── pages/
│   ├── Index.ets           # 入口：Navigation + 底部 4 Tab
│   ├── Recommend.ets       # 推荐页
│   ├── Find.ets            # 发现页
│   ├── Moment.ets          # 动态页
│   ├── Mine.ets            # 我的页
│   └── Play.ets            # 播放页（核心）
├── entryability/
└── entrybackupability/
```

---

## 自主实现与问题修复

教程之外的实现，以及开发过程中定位并修复的典型问题。

### 1. 播放核心：AVPlayer 状态机

播放器不是一个 `play()` 调用就能用的，必须串联状态流转：

```
idle ──(设置 fdSrc / url)──> initialized ──prepare()──> prepared ──play()──> playing
                                │                          │
                                └── 失败回退网络流           └── 播完 ──> completed ──> 自动下一首
```

- 用 `timeUpdate` 回调驱动进度条，`durationUpdate` 同步总时长
- 组件销毁时 `release()` 播放器并解绑全部回调，避免资源泄漏
- 播放控制前先读取 `avPlayer.state` 再分支，避免在非法状态下调用 `play()` 抛异常

### 2. 音频本地化：rawfile + fdSrc 而非 url

教程使用网络 URL 流播。本项目将音频打包进 `resources/rawfile`，改用文件描述符播放：

```ts
const rawFd = await ctx.resourceManager.getRawFd(song.raw)
avPlayer.fdSrc = { fd: rawFd.fd, offset: rawFd.offset, length: rawFd.length }
```

要点：**`fd` / `offset` / `length` 三者必须同时提供**，少一个都播不出声。
同时保留网络流作为兜底通路，本地失败时自动切换。

### 3. 文件描述符的生命周期管理

每次切歌都会 `getRawFd` 一次。若不释放，长时间切歌会累积泄漏文件描述符。
因此在 `reset()`（播放器已脱手旧音源）之后调用 `closeRawFd` 释放上一首的句柄：

```ts
const prevRaw = this.currentRawPath
this.currentRawPath = songs[index].raw
if (prevRaw !== '' && prevRaw !== this.currentRawPath) {
  ctx.resourceManager.closeRawFd(prevRaw)
}
```

### 4. 修复：路由未传参导致「点哪首都播第一首」

原实现 `pushPathByName('Play', null)` 不携带参数，播放页固定加载第 0 首。
改为传递 `{ songId }`，播放页用 `findIndex` 定位目标曲目并自动播放。

```ts
const param: PlayRouteParam = { songId: item.id }
this.pathStack.pushPathByName('Play', param)
```

### 5. 修复：`ForEach` 缺少 key 导致删除后节点复用错乱

`ForEach` 不传第三个参数（keyGenerator）时会按下标兜底。播放列表支持滑动删除，
删除后列表会复用错误节点，显示错乱。补上按 `id` 生成 key：

```ts
ForEach(this.songs, (item: SongItemType, index: number) => { /* ... */ },
  (item: SongItemType) => item.id)
```

### 6. 修复：`.rotate()` 未指定旋转中心导致圆盘「离心公转」

唱片旋转表现为绕画面外某点公转而非原地自转。根因有两层：

1. `.rotate()` 不显式传 `centerX` / `centerY` 时，支点不保证落在组件中心
2. 原容器使用 `padding`，导致**内容盒小于组件盒**，视觉圆心与旋转支点错开

最终重构为正方形 `Stack` + 显式 50% 支点：

```ts
.rotate({ angle: this.cdAngle, centerX: '50%', centerY: '50%' })
```

### 7. 动画：为什么用定时器而不是 `iterations: -1`

`.animation()` 是对**属性变化**做补间，`iterations: -1` 的无限循环动画一旦启动就无法暂停。
唱片需要随播放状态暂停/恢复，因此改用定时器驱动角度，每 16ms 递增 2°（约 2.9 秒一圈）。

### 8. 其它修正

- `.animation()` 仅对**其之前**设置的属性生效 —— `.opacity()` 写在它后面则不参与动画
- `swipeAction` 的 `end` 需传入**延迟渲染的 Builder**（`() => { this.deleteButton(i) }`），
  直接传 `this.deleteButton(i)` 会在 build 阶段立即求值，滑删按钮不渲染
- `Stack` 子组件上的 `.layoutWeight()` 无效（仅对 Row/Column/Flex 生效）
- 空 `Column()` 作为遮罩时必须显式 `.width('100%')`，否则宽度为 0，既不可见也点不到

---

## 运行说明

### 环境

- DevEco Studio 6.x
- HarmonyOS SDK：`compatibleSdkVersion 6.1.1(24)`，`targetSdkVersion 26.0.0`

### 签名

仓库中的 `build-profile.json5` **不包含签名配置**（凭据不公开）。
在 DevEco Studio 中重新配置即可构建：

```
File → Project Structure → Signing Configs → Automatically generate signature
```

### 音频资源（重要）

**仓库不包含音频文件**，原因见下方「声明」。
如需完整运行播放功能，请将音频放入：

```
entry/src/main/resources/rawfile/
├── 0.m4a
├── 1.mp3
├── 2.mp3
...
└── 15.m4a
```

命名需与 `entry/src/main/ets/common/SongData.ets` 中每首歌的 `raw` 字段一致。
放好之后重新构建即可播放；**不放音频，除播放外的界面仍可正常浏览**。

### 网络权限

远程兜底音源需要网络，`entry/src/main/module.json5` 已声明：

```json5
"requestPermissions": [{ "name": "ohos.permission.INTERNET" }]
```

> 补充：Stage 模型默认**允许**明文 HTTP（见 SDK `@ohos.net.networkSecurity.d.ts`：
> *By default, plaintext HTTP access is allowed*），因此 `network_config.json` 仅在需要收紧限制时才需要。

---

## 后续计划

- [ ] 播放接入真实音乐 API，替换本地 mock 数据
- [ ] 歌词滚动、本地搜索、最近播放列表
- [ ] 与 51 单片机循迹小车联动，通过 BLE 实现 App-Device 遥控与状态回传

---

## 声明

- 本项目为**学习用途的个人练习项目**，参考黑马程序员鸿蒙教程完成，非原创商业作品。
- 界面布局参考主流音乐 App，仅供学习交流。
- **歌曲音频与专辑封面版权归各唱片公司及歌手所有**，仓库中不包含音频文件。
  封面图仅作学习演示用途，如涉及版权问题请联系删除。
- 项目中的歌单、用户昵称、动态内容等均为演示用 mock 数据。

---

## License

代码部分采用 MIT License。第三方资源（专辑封面等）版权归原作者所有，不在本协议范围内。
