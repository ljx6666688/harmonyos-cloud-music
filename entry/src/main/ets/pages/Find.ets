import { PlayRouteParam, SongItemType } from '../models/music'
import { SONG_LIST } from '../common/SongData'

// ==================== 发现页 ====================
@ComponentV2
export struct Find {
  // V2 里非装饰成员不允许父组件构造时传入, 必须用 @Param
  @Param pathStack: NavPathStack = new NavPathStack()

  // 从公共数据取, 不再和播放页各写一份
  @Local songs: SongItemType[] = [...SONG_LIST]

  // 跳播放页, 并把点中的歌曲告诉它
  openSong(item: SongItemType): void {
    const param: PlayRouteParam = { songId: item.id }
    this.pathStack.pushPathByName('Play', param)
  }

  build() {
    Column() {
      Text('猜你喜欢')
        .fontColor(Color.White)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 10 })

      List() {
        ForEach(this.songs, (item: SongItemType, index: number) => {
          ListItem() {
            Row() {
              // 封面 + 播放小图标
              Stack({ alignContent: Alignment.BottomEnd }) {
                Image(item.img)
                  .width(50)
                  .aspectRatio(1)
                  .borderRadius(6)
                  .objectFit(ImageFit.Cover)
                  .margin({ right: 10 })

                Image($r('app.media.ic_play_mini'))
                  .width(16)
                  .margin({ right: 13, bottom: 3 })
              }
              .height(50)

              // 歌名 + 标签 + 歌手
              Column() {
                Row({ space: 6 }) {
                  Text(item.name)
                    .fontColor('#f3f3f3')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .constraintSize({ maxWidth: '75%' })

                  Text('VIP')
                    .fontColor('#9ABE28')
                    .fontSize(9)
                    .border({ width: 1, color: '#9ABE28', radius: 12 })
                    .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                }
                .width('100%')

                Text(item.author)
                  .fontColor('#696969')
                  .fontSize(12)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 6 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .justifyContent(FlexAlign.Center)

              // 播放按钮: 直接进播放页并播放这一首
              Row() {
                Image($r('app.media.ic_play'))
                  .width(15)
                  .fillColor('#ff5186')
              }
              .width(30)
              .height(30)
              .borderRadius(15)
              .border({ width: 1.5, color: '#ff5186' })
              .justifyContent(FlexAlign.Center)
              .margin({ right: 10 })
              .onClick(() => {
                this.openSong(item)
              })

              Image($r('app.media.ic_more'))
                .width(20)
                .fillColor('#6e6e6e')
            }
            .width('100%')
            .height(62)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              // 点整行也能进播放页
              this.openSong(item)
            })
          }
        }, (item: SongItemType) => item.id)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, color: '#1f1f1f', startMargin: 60 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#131313')
    .padding({ left: 10, right: 10, top: 8 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}
