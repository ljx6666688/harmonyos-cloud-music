import { PlayRouteParam, RecommendDailyType, RecommendListItem } from '../models/music'
import { SONG_LIST, SWIPER_LIST } from '../common/SongData'

// ==================== 推荐页 ====================
@ComponentV2
export struct Recommend {
  @Param pathStack: NavPathStack = new NavPathStack()

  // 图片全部改为本地资源, 不再依赖网络
  banner: ResourceStr[] = SWIPER_LIST

  // 卡片点进去先从第一首开始播
  openPlay(): void {
    const param: PlayRouteParam = { songId: SONG_LIST[0].id }
    this.pathStack.pushPathByName('Play', param)
  }

  // 每日推荐
  dailyRecommend: RecommendDailyType[] = [
    {
      img: $r('app.media.recommend_1'),
      title: '每日推荐 | 今天从《不得不爱》听起 | 私人雷达',
      tag: '每日推荐',
      top: '#660000',
      bottom: '#382e2f'
    },
    {
      img: $r('app.media.recommend_2'),
      title: '从 [Nothing on Me] 开启无限漫游',
      tag: '私人漫游',
      top: '#382e2f',
      bottom: '#a37862'
    },
    {
      img: $r('app.media.recommend_3'),
      title: '每日推荐 | 今天从《不得不爱》听起 | 私人雷达',
      tag: '华语流行',
      top: '#a37862',
      bottom: '#174847'
    },
    {
      img: $r('app.media.recommend_4'),
      title: '每日推荐 | 今天从《不得不爱》听起 | 私人雷达',
      tag: '私人雷达',
      top: '#174847',
      bottom: '#174847'
    }
  ]

  // 推荐歌单
  recommendList: RecommendListItem[] = [
    {
      img: $r('app.media.list_1'),
      title: '每日推荐 | 今天从《不得不爱》听起 | 私人雷达',
      count: '270.9万'
    },
    {
      img: $r('app.media.list_2'),
      title: 'Yasuo和更多好听的 | 华语私人雷达 | 回忆8090',
      count: '476.1万'
    },
    {
      img: $r('app.media.list_3'),
      title: 'Trap Remix丨当欧美热单遇上毒性低音',
      count: '186.3万'
    },
    {
      img: $r('app.media.list_4'),
      title: '满级人类进化之路必备BGM | 根本停不下来',
      count: '362.8万'
    },
    {
      img: $r('app.media.list_5'),
      title: '认真去聆听这个世界的每一分每一秒 (强烈推荐)',
      count: '362.8万'
    }
  ]

  // 标题栏
  @Builder
  titleBuilder(title: string) {
    Row() {
      Text(title)
        .fontColor(Color.White)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
      Image($r('app.media.ic_more'))
        .width(20)
        .fillColor('#9a9a9a')
    }
    .width('100%')
    .height(40)
  }

  // 每日推荐卡片
  @Builder
  dailyCard(item: RecommendDailyType) {
    Column() {
      // 上半部分: 封面 + 标签
      Stack({ alignContent: Alignment.TopStart }) {
        Image(item.img)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)

        Text(item.tag)
          .fontSize(11)
          .fontColor(Color.White)
          .backgroundColor(item.top)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(2)
          .margin({ left: 8, top: 8 })
      }
      .width('100%')
      .height(110)
      .clip(true)

      // 下半部分: 简介
      Text(item.title)
        .fontSize(12)
        .fontColor(Color.White)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ left: 8, right: 8, top: 6, bottom: 8 })
        .width('100%')
        .backgroundColor(item.bottom)
    }
    .width(140)
    .backgroundColor('#2a2a2a')
    .borderRadius(6)
    .clip(true)
    .onClick(() => {
      this.openPlay()
    })
  }

  // 歌单卡片
  @Builder
  listCard(item: RecommendListItem) {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(item.img)
          .width('100%')
          .aspectRatio(1)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)

        Row({ space: 2 }) {
          Image($r('app.media.ic_wave'))
            .width(10)
            .fillColor(Color.White)
          Text(item.count)
            .fontSize(10)
            .fontColor(Color.White)
        }
        .backgroundColor('rgba(0,0,0,0.5)')
        .borderRadius(8)
        .padding({ left: 4, right: 6, top: 1, bottom: 1 })
        .margin({ right: 6, top: 6 })
      }
      .width('100%')

      Text(item.title)
        .fontSize(12)
        .fontColor('#e6e6e6')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
        .width('100%')
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.openPlay()
    })
  }

  build() {
    Scroll() {
      Column() {
        // 轮播
        Swiper() {
          // img 已不是 string, ForEach 的 key 改用下标
          ForEach(this.banner, (item: ResourceStr, index: number) => {
            Image(item)
              .width('100%')
              .height('100%')
              .borderRadius(8)
              .objectFit(ImageFit.Cover)
          }, (item: ResourceStr, index: number) => index.toString())
        }
        .width('100%')
        .height(150)
        .autoPlay(true)
        .interval(3000)
        .indicator(true)

        // 每日推荐
        this.titleBuilder('每日推荐')
        List({ space: 10 }) {
          ForEach(this.dailyRecommend, (item: RecommendDailyType, index: number) => {
            ListItem() {
              this.dailyCard(item)
            }
          }, (item: RecommendDailyType, index: number) => index.toString())
        }
        .width('100%')
        .height(180)
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)

        // 推荐歌单
        this.titleBuilder('推荐歌单')
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.recommendList, (item: RecommendListItem, index: number) => {
            Column() {
              this.listCard(item)
            }
            .width('32%')
            .margin({ bottom: 12 })
          }, (item: RecommendListItem, index: number) => index.toString())
        }
        .width('100%')
        .padding({ bottom: 20 })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}
