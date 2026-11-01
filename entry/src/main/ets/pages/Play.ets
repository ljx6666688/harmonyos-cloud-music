import { PlayRouteParam, SongItemType } from '../models/music'
import { SONG_LIST } from '../common/SongData'
import { media } from '@kit.MediaKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN: number = 0x0000
const TAG: string = 'MusicPlay'
// 本地 rawfile 播不出来时的兜底音源(课程 OSS)
const OSS_BASE: string = 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/'

// ==================== 播放页 ====================
// 根节点是 NavDestination, 由 Index 的 navDestination 路由按名字 'Play' 渲染
@ComponentV2
export struct Play {
  // ===================== 播放器状态 =====================
  @Local isPlaying: boolean = false
  @Local currentTime: number = 0 // 当前进度(ms)
  @Local duration: number = 0 // 总时长(ms)

  // ===================== 视觉动画状态 =====================
  @Local cdAngle: number = 0 // 唱片旋转角
  @Local stylusAngle: number = -30 // 唱针: -30 抬起, 0 落下
  @Local panelVisible: boolean = false // 播放列表面板

  // ===== 诊断: 把播放器内部状态直接显示在界面上 =====
  // 之前所有失败只走 console.error, 界面上"点了没反应", 完全没法定位
  @Local playerState: string = '未创建'
  @Local errMsg: string = ''

  // ===================== 歌单数据 =====================
  // 必须是 @Local: 删除歌曲要触发刷新, 普通成员改动在 V2 里不会通知 UI
  @Local songs: SongItemType[] = [...SONG_LIST]

  // 当前播放的歌曲 + 下标
  // V2 的 @Local 是浅层观察: 切歌必须整体赋值, 不能只改 playState.name
  @Local playState: SongItemType = this.songs[0]
  @Local currentIndex: number = 0

  // ===================== 非状态成员 =====================
  private avPlayer?: media.AVPlayer
  private spinTimer: number = -1
  private shouldPlayAfterLoad: boolean = false
  pathStack: NavPathStack = new NavPathStack()

  // 从列表点进来时指定的歌曲下标 / 是否自动播放
  private startIndex: number = 0
  private autoPlay: boolean = false
  // 当前占用的 rawfile 路径, 用于切歌时释放旧的 fd
  private currentRawPath: string = ''

  // ===================== 生命周期 =====================
  aboutToAppear(): void {
    this.initPlayer()
  }

  aboutToDisappear(): void {
    this.stopSpin()
    this.releasePlayer()
  }

  // ===================== AVPlayer =====================
  async initPlayer(): Promise<void> {
    try {
      this.avPlayer = await media.createAVPlayer()
      hilog.info(DOMAIN, TAG, '播放器创建成功')

      // 状态机: idle -> (设 fdSrc/url) initialized -> prepare() -> prepared -> play() -> playing
      this.avPlayer.on('stateChange', async (state: media.AVPlayerState) => {
        this.playerState = state
        hilog.info(DOMAIN, TAG, 'stateChange -> %{public}s', state)
        if (!this.avPlayer) {
          return
        }
        if (state === 'initialized') {
          try {
            await this.avPlayer.prepare()
          } catch (e) {
            // 本地 fd 准备失败 -> 改用网络流再试一次
            hilog.error(DOMAIN, TAG, 'prepare 失败: %{public}s', JSON.stringify(e))
            this.errMsg = '本地音频准备失败，已改用网络'
            await this.fallbackToNetwork()
          }
        } else if (state === 'prepared') {
          this.errMsg = ''
          this.duration = this.avPlayer.duration
          hilog.info(DOMAIN, TAG, 'prepared, duration=%{public}d', this.duration)
          if (this.shouldPlayAfterLoad) {
            await this.playInner()
          }
        } else if (state === 'completed') {
          this.playNext(true)
        }
      })

      // 播放进度回调
      this.avPlayer.on('timeUpdate', (time: number) => {
        this.currentTime = time
      })

      // 时长回调
      this.avPlayer.on('durationUpdate', (duration: number) => {
        this.duration = duration
      })

      this.avPlayer.on('error', (err: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'AVPlayer error code=%{public}d msg=%{public}s', err.code, err.message)
        this.errMsg = `播放错误 ${err.code}`
      })

      // 装载列表里点中的那一首; 从别处直接进来则默认第一首
      this.shouldPlayAfterLoad = this.autoPlay
      await this.loadSong(this.startIndex)
    } catch (err) {
      hilog.error(DOMAIN, TAG, '初始化失败: %{public}s', JSON.stringify(err))
      this.playerState = '初始化失败'
      this.errMsg = '播放器初始化失败: ' + JSON.stringify(err)
    }
  }

  // 兜底: 用网络地址重试
  async fallbackToNetwork(): Promise<void> {
    if (!this.avPlayer) {
      return
    }
    try {
      await this.avPlayer.reset()
      this.avPlayer.url = OSS_BASE + this.songs[this.currentIndex].raw
      hilog.info(DOMAIN, TAG, '改用网络源: %{public}s', this.songs[this.currentIndex].raw)
    } catch (e) {
      this.errMsg = '网络兜底也失败: ' + JSON.stringify(e)
      hilog.error(DOMAIN, TAG, '兜底失败: %{public}s', JSON.stringify(e))
    }
  }

  async releasePlayer(): Promise<void> {
    if (!this.avPlayer) {
      return
    }
    try {
      this.avPlayer.off('stateChange')
      this.avPlayer.off('timeUpdate')
      this.avPlayer.off('durationUpdate')
      this.avPlayer.off('error')
      await this.avPlayer.release()
      this.avPlayer = undefined
    } catch (err) {
      console.error('释放播放器失败: ' + JSON.stringify(err))
    }
  }

  async loadSong(index: number): Promise<void> {
    if (!this.avPlayer || this.songs.length === 0) {
      return
    }
    this.currentIndex = index
    this.playState = this.songs[index] // 整体替换才会刷新
    this.currentTime = 0
    this.duration = 0

    try {
      // 音频已打包进 resources/rawfile, 用 fdSrc 直接读, 不走网络
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext
      if (!ctx) {
        throw new Error('拿不到 UIAbilityContext')
      }
      const rawFd = await ctx.resourceManager.getRawFd(this.songs[index].raw)
      hilog.info(DOMAIN, TAG, 'getRawFd ok: %{public}s fd=%{public}d len=%{public}d',
        this.songs[index].raw, rawFd.fd, rawFd.length)

      await this.avPlayer.reset() // 回到 idle
      // fd + offset + length 三件套, 缺一不可
      this.avPlayer.fdSrc = { fd: rawFd.fd, offset: rawFd.offset, length: rawFd.length }
      this.errMsg = ''

      // 释放上一首的 fd: 此时 reset() 已让播放器脱手旧音源, 关掉是安全的,
      // 否则每切一次歌泄漏一个文件描述符
      const prevRaw = this.currentRawPath
      this.currentRawPath = this.songs[index].raw
      if (prevRaw !== '' && prevRaw !== this.currentRawPath) {
        try {
          ctx.resourceManager.closeRawFd(prevRaw)
          hilog.info(DOMAIN, TAG, 'closeRawFd: %{public}s', prevRaw)
        } catch (e) {
          hilog.warn(DOMAIN, TAG, 'closeRawFd 失败: %{public}s', JSON.stringify(e))
        }
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, '装载本地音频失败: %{public}s', JSON.stringify(err))
      this.errMsg = '本地音频读取失败，已改用网络'
      await this.fallbackToNetwork()
    }
  }

  // 真正开始播放, 并同步 UI(唱片转、唱针落)
  async playInner(): Promise<void> {
    if (!this.avPlayer) {
      return
    }
    await this.avPlayer.play()
    this.isPlaying = true
    this.stylusAngle = 0
    this.startSpin()
  }

  async togglePlay(): Promise<void> {
    if (!this.avPlayer) {
      this.errMsg = '播放器未创建'
      return
    }
    try {
      // 按当前状态决定怎么做, 不要盲目调 play()
      const st: media.AVPlayerState = this.avPlayer.state
      this.playerState = st
      hilog.info(DOMAIN, TAG, 'togglePlay, 当前状态=%{public}s', st)

      if (st === 'playing') {
        await this.avPlayer.pause()
        this.isPlaying = false
        this.stylusAngle = -30
        this.stopSpin()
      } else if (st === 'prepared' || st === 'paused' || st === 'completed') {
        await this.playInner()
      } else if (st === 'initialized') {
        // 还没 prepare: 先 prepare, 成功后在 stateChange 里继续播
        this.shouldPlayAfterLoad = true
        await this.avPlayer.prepare()
      } else {
        this.errMsg = `当前状态不能播放: ${st}`
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, '播放控制失败: %{public}s', JSON.stringify(err))
      this.errMsg = '播放失败: ' + JSON.stringify(err)
    }
  }

  playNext(auto: boolean = false): void {
    if (this.songs.length === 0) {
      return
    }
    this.shouldPlayAfterLoad = auto ? true : this.isPlaying
    this.loadSong((this.currentIndex + 1) % this.songs.length)
  }

  playPrev(): void {
    if (this.songs.length === 0) {
      return
    }
    this.shouldPlayAfterLoad = this.isPlaying
    this.loadSong((this.currentIndex - 1 + this.songs.length) % this.songs.length)
  }

  async seekTo(ms: number): Promise<void> {
    if (!this.avPlayer || this.duration <= 0) {
      return
    }
    try {
      await this.avPlayer.seek(ms, media.SeekMode.SEEK_PREV_SYNC)
      this.currentTime = ms
    } catch (err) {
      console.error('seek 失败: ' + JSON.stringify(err))
    }
  }

  // ===================== 唱片旋转 =====================
  // 用定时器而不是 iterations:-1 的无限动画, 这样才能真正暂停/继续
  private startSpin(): void {
    this.stopSpin()
    // 每 16ms 转 2 度 ≈ 125°/s, 约 2.9 秒一圈, 接近 60fps 更顺滑
    this.spinTimer = setInterval(() => {
      this.cdAngle = (this.cdAngle + 2) % 360
    }, 16)
  }

  private stopSpin(): void {
    if (this.spinTimer !== -1) {
      clearInterval(this.spinTimer)
      this.spinTimer = -1
    }
  }

  // ===================== 歌单操作 =====================
  deleteSong(index: number): void {
    if (this.songs.length <= 1) {
      return
    }
    const deletingCurrent = index === this.currentIndex

    this.songs.splice(index, 1)
    this.songs = [...this.songs] // 重新赋值确保 V2 观察到变化

    if (deletingCurrent) {
      this.shouldPlayAfterLoad = this.isPlaying
      this.currentIndex = -1
      this.loadSong(Math.min(index, this.songs.length - 1))
    } else if (index < this.currentIndex) {
      this.currentIndex -= 1
    }
  }

  number2time(ms: number): string {
    // 直接算, 不要 if/else: 原来正好 60000ms 会被错误显示成 00:00
    const totalSeconds = Math.floor(ms / 1000)
    const m = Math.floor(totalSeconds / 60)
    const s = totalSeconds % 60
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
  }

  // ===================== 删除按钮 =====================
  @Builder
  deleteButton(index: number) {
    Button('删除')
      .backgroundColor('#ec5c87')
      .fontColor(Color.White)
      .width(80)
      .height('100%')
      .type(ButtonType.Normal)
      .onClick(() => {
        this.deleteSong(index)
      })
  }

  // ===================== 唱片区 =====================
  @Builder
  albumArea() {
    Stack({ alignContent: Alignment.Top }) {
      // 唱片: 黑胶底图 + 封面叠在同一个正方形 Stack 里, 整体自转
      Stack({ alignContent: Alignment.Center }) {
        // 黑胶底
        Image($r('app.media.ic_cd'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)

        // 封面
        Image(this.playState.img)
          .width('60%')
          .aspectRatio(1)
          .borderRadius(500)
          .objectFit(ImageFit.Cover)
      }
      .width('90%')
      .aspectRatio(1)
      .borderRadius(500)
      .clip(true)
      // 关键: 显式把旋转中心定成组件自身的中心(50%, 50%)。
      // 不写 centerX/centerY 时支点可能被算到左上角,
      // 表现就是整张唱片绕着某个点"公转", 而不是原地"自转"。
      .rotate({ angle: this.cdAngle, centerX: '50%', centerY: '50%' })
      .margin({ top: 50 })

      // 唱针: 支点在顶部偏左(90, 27), 播放时落下
      Image($r('app.media.ic_stylus'))
        .width(180)
        .aspectRatio(1)
        .rotate({ angle: this.stylusAngle, centerX: 90, centerY: 27 })
        .animation({ duration: 500, curve: Curve.EaseInOut })
    }
    .layoutWeight(1)
    .width('100%')
  }

  // ===================== 歌曲信息 =====================
  @Builder
  songInfo() {
    Column({ space: 8 }) {
      Text(this.playState.name)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.playState.author)
        .fontSize(16)
        .fontColor('#d9ffffff')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 只在真正出错时才显示, 正常播放时界面保持干净
      if (this.errMsg) {
        Text(this.errMsg)
          .fontSize(10)
          .fontColor('#90ffb0b0')
          .maxLines(2)
          .textAlign(TextAlign.Center)
      }
    }
    .width('90%')
    .justifyContent(FlexAlign.Center)
    .margin({ top: 10, bottom: 14 })
  }

  // ===================== 操作栏 =====================
  @Builder
  actionBar() {
    Row() {
      Badge({ value: '99+', style: { badgeSize: 12, badgeColor: '#45CCCCCC' } }) {
        Image($r('app.media.ic_like'))
          .fillColor(Color.White)
          .width(24)
      }

      Badge({ value: '10W', style: { badgeSize: 12, badgeColor: '#45CCCCCC' } }) {
        Image($r('app.media.ic_comment_o'))
          .fillColor(Color.White)
          .width(18)
      }

      Badge({ value: 'hot', style: { badgeSize: 12, badgeColor: '#a8ff3131' } }) {
        Image($r('app.media.ic_bells_o'))
          .fillColor(Color.White)
          .width(24)
      }

      Badge({ value: 'vip', style: { badgeSize: 12, badgeColor: '#b7efd371' } }) {
        Image($r('app.media.ic_download_o'))
          .fillColor(Color.White)
          .width(24)
      }
    }
    .width('90%')
    .justifyContent(FlexAlign.SpaceAround)
  }

  // ===================== 进度条 =====================
  @Builder
  progressBar() {
    Row({ space: 4 }) {
      Text(this.number2time(this.currentTime))
        .fontSize(11)
        .fontColor(Color.White)
        .width(38)

      Slider({
        value: this.currentTime,
        min: 0,
        max: this.duration > 0 ? this.duration : 1 // max 不能为 0
      })
        .layoutWeight(1)
        .blockColor(Color.White)
        .selectedColor(Color.White)
        .trackColor('#ccc5c5c5')
        .trackThickness(2)
        .onChange((value: number, mode: SliderChangeMode) => {
          // 只在松手/点击时 seek, 拖拽过程中不要频繁跳
          if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
            this.seekTo(value)
          }
        })

      Text(this.number2time(this.duration))
        .fontSize(11)
        .fontColor(Color.White)
        .width(38)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18 })
  }

  // ===================== 控制栏 =====================
  @Builder
  controlBar() {
    Row() {
      Image($r('app.media.ic_auto'))
        .fillColor(Color.White)
        .width(26)

      Image($r('app.media.ic_prev'))
        .fillColor(Color.White)
        .width(28)
        .onClick(() => {
          this.playPrev()
        })

      Image(this.isPlaying ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
        .fillColor(Color.White)
        .width(44)
        .onClick(() => {
          this.togglePlay()
        })

      Image($r('app.media.ic_next'))
        .fillColor(Color.White)
        .width(28)
        .onClick(() => {
          this.playNext(false)
        })

      Image($r('app.media.ic_song_list'))
        .fillColor(Color.White)
        .width(26)
        .onClick(() => {
          this.panelVisible = true
        })
    }
    .width('100%')
    .padding({ top: 14, bottom: 20 })
    .justifyContent(FlexAlign.SpaceAround)
  }

  // ===================== 播放列表面板 =====================
  @Builder
  playListPanel() {
    Column() {
      // 遮罩: 空容器必须显式 width('100%'),
      // 否则在 Column 里按内容宽度布局 = 0, 既看不见也点不到
      Column()
        .width('100%')
        .layoutWeight(1)
        .onClick(() => {
          this.panelVisible = false
        })

      Column() {
        // 头部
        Row() {
          Row() {
            Image($r('app.media.ic_play'))
              .width(20)
              .fillColor('#ff5186')
          }
          .width(50)
          .aspectRatio(1)
          .justifyContent(FlexAlign.Center)

          Text(`播放列表 (${this.songs.length})`)
            .fontColor(Color.White)
            .fontSize(14)
            .layoutWeight(1)

          Image($r('app.media.ic_close'))
            .fillColor('#ffa49a9a')
            .width(22)
            .height(22)
            .margin({ right: 16 })
            .onClick(() => {
              this.panelVisible = false
            })
        }
        .width('100%')
        .backgroundColor('#ff353333')
        .padding(8)
        .border({ width: { bottom: 1 }, color: '#12ec5c87' })
        .borderRadius({ topLeft: 4, topRight: 4 })

        // 列表
        List() {
          // 第三个参数是 key: 不传会按下标兜底, 删歌后复用错节点
          ForEach(this.songs, (item: SongItemType, index: number) => {
            ListItem() {
              Row() {
                Row() {
                  Text((index + 1).toString())
                    .fontColor(item.id === this.playState.id ? '#ff5186' : '#ffa49a9a')
                    .fontSize(13)
                }
                .width(50)
                .aspectRatio(1)
                .justifyContent(FlexAlign.Center)

                Column({ space: 4 }) {
                  Text(item.name)
                    .fontSize(14)
                    .fontColor(item.id === this.playState.id ? '#ff5186' : '#ffa49a9a')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.author)
                    .fontSize(11)
                    .fontColor(Color.Gray)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.Center)

                // 播放按钮: 直接播这首
                Image($r('app.media.ic_play'))
                  .width(16)
                  .fillColor(item.id === this.playState.id ? '#ff5186' : '#8d8d8d')
                  .margin({ right: 14 })
                  .onClick(() => {
                    this.shouldPlayAfterLoad = true
                    this.loadSong(index)
                  })

                Image($r('app.media.ic_more'))
                  .width(20)
                  .height(20)
                  .margin({ right: 16 })
                  .fillColor(Color.Gray)
              }
              .width('100%')
              .height(52)
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                this.shouldPlayAfterLoad = true
                this.loadSong(index)
              })
            }
            // swipeAction 需要"延迟执行"的 builder, 直接调用会在 build 阶段就执行
            .swipeAction({ end: () => { this.deleteButton(index) } })
            .border({ width: { bottom: 1 }, color: '#12ec5c87' })
          }, (item: SongItemType) => item.id)
        }
        .layoutWeight(1)
        .backgroundColor('#ff353333')
        .contentEndOffset(20) // 别被底部手势条盖住
      }
      .width('100%')
      .height('60%') // 和父容器统一用百分比, 避免固定 400vp 在不同屏幕溢出
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height(this.panelVisible ? '100%' : '0%')
    .opacity(this.panelVisible ? 1 : 0) // 必须在 animation 之前, 否则淡入淡出没动画
    .animation({ duration: 300, curve: Curve.EaseInOut })
    // 收起时彻底不响应触摸, 否则透明区域会挡住下面播放控件的点击
    .hitTestBehavior(this.panelVisible ? HitTestMode.Default : HitTestMode.None)
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        // ============ 播放主界面 ============
        Stack() {
          // 背景: 小半径模糊 + 暗色蒙层
          // blur(1000) 全屏高斯模糊代价极高, 而且白字压在上面看不清
          Image(this.playState.img)
            .width('100%')
            .height('100%')
            .blur(40)
            .opacity(0.6)
            .objectFit(ImageFit.Cover)
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.4)')
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

          // 内容
          Column() {
            // 返回
            Row() {
              Image($r('app.media.ic_close'))
                .width(22)
                .height(22)
                .fillColor(Color.White)
                .onClick(() => {
                  this.pathStack.pop()
                })
            }
            .width('90%')
            .height(40)
            .justifyContent(FlexAlign.Start)

            this.albumArea()
            this.songInfo()
            this.actionBar()
            this.progressBar()
            this.controlBar()
          }
          .width('100%')
          .height('100%')
        }
        .width('100%')
        .height('100%')

        // ============ 播放列表 ============
        this.playListPanel()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
      // 列表里点了哪一首, 就播哪一首
      const param = context.pathInfo.param as PlayRouteParam
      if (param && param.songId) {
        const idx = this.songs.findIndex((s: SongItemType) => s.id === param.songId)
        if (idx >= 0) {
          this.startIndex = idx
          this.autoPlay = true
          // 播放器已就绪 = 初始化早于 onReady, 这里直接切歌并自动播放
          if (this.avPlayer) {
            this.shouldPlayAfterLoad = true
            this.loadSong(idx)
          }
        }
      }
    })
    .hideTitleBar(true)
  }
}
