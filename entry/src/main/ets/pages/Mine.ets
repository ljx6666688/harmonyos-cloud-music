import { SongItemType } from '../models/music'
import { SONG_LIST } from '../common/SongData'

// ==================== 我的 ====================
@ComponentV2
export struct Mine {
  // 上面用的封面墙: 把 16 张封面重复排列铺满
  @Local covers: SongItemType[] = [...SONG_LIST, ...SONG_LIST]

  // 关注 / 粉丝 / 赞
  private stats: string[][] = [['1', '关注'], ['100万', '粉丝'], ['1.67亿', '赞']]

  // ===== 用户信息: 以后改头像/昵称/标签只需要动这几行 =====
  private nickname: string = '桤锦'
  private avatar: Resource = $r('app.media.ic_avatar')
  private subtitle: string = '00后  处女座  北京  歌龄·18年'

  @Builder
  statItem(value: string, label: string) {
    Row({ space: 4 }) {
      Text(value)
        .fontColor(Color.White)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontColor('#a49a9a')
        .fontSize(13)
    }
    .margin({ right: 18 })
  }

  build() {
    Column() {
      // ============ 上部: 封面墙 (约 70%) ============
      Stack({ alignContent: Alignment.Bottom }) {
        Grid() {
          ForEach(this.covers, (item: SongItemType) => {
            GridItem() {
              Image(item.img)
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
            }
          }, (item: SongItemType, index: number) => `${item.id}-${index}`)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .columnsGap(2)
        .rowsGap(2)
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)

        // 底部渐隐, 让头像区过渡自然
        Column()
          .width('100%')
          .height(140)
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [['rgba(0,0,0,0)', 0.0], ['rgba(0,0,0,0.85)', 1.0]]
          })

        // 用户头像
        Image(this.avatar)
          .width(80)
          .height(80)
          .borderRadius(40)
          .objectFit(ImageFit.Cover)
          .border({ width: 2, color: '#ff5186' })
          .margin({ bottom: 10 })
      }
      .width('100%')
      .layoutWeight(7)

      // ============ 下部: 介绍区 (约 30%) ============
      Column({ space: 10 }) {
        Row({ space: 8 }) {
          Text(this.nickname)
            .fontColor(Color.White)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)

          Text('VIP')
            .fontColor('#ff5186')
            .fontSize(9)
            .border({ width: 1, color: '#ff5186', radius: 8 })
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
        }

        Text(this.subtitle)
          .fontColor('#a49a9a')
          .fontSize(13)

        Row() {
          ForEach(this.stats, (item: string[]) => {
            this.statItem(item[0], item[1])
          }, (item: string[]) => item[1])

          Blank()
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(3)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .padding({ left: 20, right: 20 })
      .backgroundColor('#0d0d0d')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0d0d0d')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}
