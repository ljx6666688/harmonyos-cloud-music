import { TabItem } from '../models/music'
import { Find } from './Find'
import { Mine } from './Mine'
import { Moment } from './Moment'
import { Play } from './Play'
import { Recommend } from './Recommend'

// ==================== 入口: Navigation + 底部 Tabs ====================
@Entry
@ComponentV2
struct Index {
  @Local pathStack: NavPathStack = new NavPathStack()
  @Local currentIndex: number = 0

  // 底部 Tab 数据
  tabData: TabItem[] = [
    { text: '推荐', icon: $r('app.media.ic_recommend') },
    { text: '发现', icon: $r('app.media.ic_find') },
    { text: '动态', icon: $r('app.media.ic_moment') },
    { text: '我的', icon: $r('app.media.ic_mine') }
  ]

  // 自定义 Tab 图标 + 文字
  @Builder
  tabBuilder(index: number) {
    Column({ space: 3 }) {
      Image(this.tabData[index].icon)
        .width(21)
        .height(21)
        .fillColor(this.currentIndex === index ? '#ff5186' : '#8d8d8d')
      Text(this.tabData[index].text)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? '#ff5186' : '#8d8d8d')
    }
    .width('100%')
    .height(48)
    .justifyContent(FlexAlign.Center)
  }

  // 路由表: 按名字渲染 NavDestination
  @Builder
  pageMap(name: string) {
    if (name === 'Play') {
      Play()
    }
  }

  build() {
    Navigation(this.pathStack) {
      Tabs({ barPosition: BarPosition.End }) {
        TabContent() {
          Recommend({ pathStack: this.pathStack })
        }
        .tabBar(this.tabBuilder(0))

        TabContent() {
          Find({ pathStack: this.pathStack })
        }
        .tabBar(this.tabBuilder(1))

        TabContent() {
          Moment({ pathStack: this.pathStack })
        }
        .tabBar(this.tabBuilder(2))

        TabContent() {
          Mine()
        }
        .tabBar(this.tabBuilder(3))
      }
      .barBackgroundColor('#0d0d0d')
      .barMode(BarMode.Fixed)
      .scrollable(true)
      .animationDuration(200)
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .width('100%')
      .height('100%')
    }
    .navDestination(this.pageMap)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .backgroundColor('#131313')
    .width('100%')
    .height('100%')
  }
}
