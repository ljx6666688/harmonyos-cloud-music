// ==================== 数据模型 ====================
// 命名统一用 PascalCase, 避免 code-linter 的 naming-convention 告警

/** 歌曲 */
export interface SongItemType {
  img: ResourceStr // 封面(本地资源 $r, 不再依赖网络)
  name: string // 歌名
  author: string // 歌手
  raw: string // rawfile 里的音频文件名(音频已打包进 HAP, 不依赖网络)
  id: string // 唯一标识(ForEach 的 key 必须用它)
}

/** 底部 Tab */
export interface TabItem {
  text: string
  icon: ResourceStr
}

/**
 * 每日推荐卡片
 * 注意: 原来课程里叫 `type`, 但它存的是"每日推荐/华语流行"这类展示标签,
 * 不是类型, 所以改名 tag;
 */
export interface RecommendDailyType {
  img: ResourceStr // 封面
  title: string // 简介文字
  tag: string // 标签文字
  top: string // 渐变起始色
  bottom: string // 渐变结束色
}

/** 推荐歌单 */
export interface RecommendListItem {
  img: ResourceStr
  title: string
  count: string
}

/** 跳转播放页携带的参数: 告诉播放页要点哪一首 */
export interface PlayRouteParam {
  songId: string
}

/** 动态广场卡片 */
export interface MomentItem {
  avatar: ResourceStr
  name: string
  content: string
  song: SongItemType
  share: string
  comment: string
  like: string
}
