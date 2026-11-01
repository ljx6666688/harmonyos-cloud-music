import { SongItemType } from '../models/music'

// ==================== 共享歌单 ====================
// 封面已本地化到 resources/base/media/cover_0 ... cover_15 (来源: 课程 OSS 原图)
// 只有音频 url 还是远程: 16 首合计约 60MB, 打进 HAP 不合适。
//
// 注意: 这些封面在 OSS 上虽然名为 0.jpg~15.jpg, 但其中 2、5、7、10、13 实际是 PNG,
// 入库时已按真实格式改名(cover_2.png 等), 资源名里不含扩展名, 所以 $r 引用不受影响。
export const SONG_LIST: SongItemType[] = [
  {
    img: $r('app.media.cover_0'),
    name: '直到世界的尽头',
    author: 'WANDS',
    raw: '0.m4a',
    id: '0000'
  },
  {
    img: $r('app.media.cover_1'),
    name: '画',
    author: '赵磊',
    raw: '1.mp3',
    id: '0001'
  },
  {
    img: $r('app.media.cover_2'),
    name: 'Sweet Dreams',
    author: 'Paul Sax / Eurythmics',
    raw: '2.mp3',
    id: '0002'
  },
  {
    img: $r('app.media.cover_3'),
    name: '奢香夫人',
    author: '凤凰传奇',
    raw: '3.m4a',
    id: '0003'
  },
  {
    img: $r('app.media.cover_4'),
    name: '空心',
    author: '光泽',
    raw: '4.mp3',
    id: '0004'
  },
  {
    img: $r('app.media.cover_5'),
    name: '反转地球',
    author: '潘玮柏',
    raw: '5.mp3',
    id: '0005'
  },
  {
    img: $r('app.media.cover_6'),
    name: 'No.9',
    author: 'T-ara',
    raw: '6.m4a',
    id: '0006'
  },
  {
    img: $r('app.media.cover_7'),
    name: '孤独',
    author: 'G.E.M.邓紫棋',
    raw: '7.m4a',
    id: '0007'
  },
  {
    img: $r('app.media.cover_8'),
    name: 'Lose Control',
    author: 'Hedley',
    raw: '8.m4a',
    id: '0008'
  },
  {
    img: $r('app.media.cover_9'),
    name: '倩女幽魂',
    author: '张国荣',
    raw: '9.m4a',
    id: '0009'
  },
  {
    img: $r('app.media.cover_10'),
    name: '北京北京',
    author: '汪峰',
    raw: '10.m4a',
    id: '0010'
  },
  {
    img: $r('app.media.cover_11'),
    name: '苦笑',
    author: '汪苏泷',
    raw: '11.mp3',
    id: '0011'
  },
  {
    img: $r('app.media.cover_12'),
    name: '一生所爱',
    author: '卢冠廷 / 莫文蔚',
    raw: '12.m4a',
    id: '0012'
  },
  {
    img: $r('app.media.cover_13'),
    name: '月半小夜曲',
    author: '李克勤',
    raw: '13.mp3',
    id: '0013'
  },
  {
    img: $r('app.media.cover_14'),
    name: 'Rolling in the Deep',
    author: 'Adele',
    raw: '14.m4a',
    id: '0014'
  },
  {
    img: $r('app.media.cover_15'),
    name: '海阔天空',
    author: 'Beyond',
    raw: '15.m4a',
    id: '0015'
  }
]

// ==================== 首页轮播 ====================
// 这 5 个文件在 OSS 上叫 banner1.png ~ banner5.png, 但实际是 WebP, 已按真实格式入库
export const SWIPER_LIST: ResourceStr[] = [
  $r('app.media.banner_1'),
  $r('app.media.banner_2'),
  $r('app.media.banner_3'),
  $r('app.media.banner_4'),
  $r('app.media.banner_5')
]
