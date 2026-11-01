import { MomentItem, PlayRouteParam, SongItemType } from '../models/music'
import { SONG_LIST } from '../common/SongData'

// ==================== 动态 / 互动广场 ====================
@ComponentV2
export struct Moment {
  // V2 里非装饰成员不允许父组件构造时传入, 必须用 @Param
  @Param pathStack: NavPathStack = new NavPathStack()

  // 注意: 这些是演示用的 mock 数据, 不是真实用户内容
  @Local momentList: MomentItem[] = [
    {
      avatar: SONG_LIST[0].img,
      name: 'Feast-aws',
      content: '二十几岁的你，一无所有，也拥有一切',
      song: SONG_LIST[0],
      share: '分享',
      comment: '604',
      like: '23382'
    },
    {
      avatar: SONG_LIST[1].img,
      name: 'CeeYet',
      content: '画一个姑娘陪着我，再画一个姑娘陪着我',
      song: SONG_LIST[1],
      share: '分享',
      comment: '1237',
      like: '5482'
    },
    {
      avatar: SONG_LIST[2].img,
      name: 'Z_HOUSC',
      content: '这个歌必须得从两个职业选手说起',
      song: SONG_LIST[2],
      share: '分享',
      comment: '8425',
      like: '4224'
    }
  ]

  // 一条动态
  @Builder
  momentCard(item: MomentItem) {
    Row() {
      // 头像
      Image(item.avatar)
        .width(40)
        .height(40)
        .borderRadius(20)
        .objectFit(ImageFit.Cover)
        .margin({ right: 10 })

      Column({ space: 8 }) {
        Text(item.name)
          .fontColor(Color.White)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .width('100%')

        Text(item.content)
          .fontColor('#d0d0d0')
          .fontSize(13)
          .width('100%')

        // 分享的歌曲卡片
        Row() {
          Image(item.song.img)
            .width(42)
            .height(42)
            .borderRadius(4)
            .objectFit(ImageFit.Cover)
            .margin({ right: 8 })

          Column() {
            Text(item.song.name)
              .fontColor(Color.White)
              .fontSize(13)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(item.song.author)
              .fontColor('#8d8d8d')
              .fontSize(11)
              .margin({ top: 3 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Image($r('app.media.ic_play_mini'))
            .width(22)
            .margin({ right: 8 })
        }
        .width('100%')
        .padding(8)
        .backgroundColor('#1e1e1e')
        .borderRadius(6)
        .onClick(() => {
          const param: PlayRouteParam = { songId: item.song.id }
          this.pathStack.pushPathByName('Play', param)
        })

        // 底部分享/评论/点赞
        Row({ space: 26 }) {
          Row({ space: 4 }) {
            Image($r('app.media.ic_more'))
              .width(14)
              .fillColor('#8d8d8d')
            Text(item.share)
              .fontColor('#8d8d8d')
              .fontSize(11)
          }

          Row({ space: 4 }) {
            Image($r('app.media.ic_comment_o'))
              .width(14)
              .fillColor('#8d8d8d')
            Text(item.comment)
              .fontColor('#8d8d8d')
              .fontSize(11)
          }

          Row({ space: 4 }) {
            Image($r('app.media.ic_like'))
              .width(14)
              .fillColor('#8d8d8d')
            Text(item.like)
              .fontColor('#8d8d8d')
              .fontSize(11)
          }

          Blank()
        }
        .width('100%')
        .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 14, bottom: 14 })
  }

  build() {
    Column() {
      Text('互动广场')
        .fontColor(Color.White)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 6 })

      List() {
        ForEach(this.momentList, (item: MomentItem) => {
          ListItem() {
            this.momentCard(item)
          }
        }, (item: MomentItem) => item.name)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, color: '#1f1f1f' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#131313')
    .padding({ left: 12, right: 12, top: 8 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}
