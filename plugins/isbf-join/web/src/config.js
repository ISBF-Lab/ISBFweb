// Replace copy and contact destinations here when integrating into isbf-one.com.
export const config = {
  homeUrl: 'https://isbf-one.com',
  recruitment: {
    email: 'hr@isbf-one.com',
    endpoint: '/api/applications',
  },
  gallery: {
    // Put your files in public/gallery/, then fill image with e.g. 'gallery/01.webp'.
    // Local paths also work when the site is deployed under /join/.
    speed: 28,
    items: [
      { image: 'gallery/01-orbit.png', title: '团队日常', alt: '' },
      { image: 'gallery/02-ascent.png', title: '一起创造', alt: '' },
      { image: 'gallery/03-current.png', title: '我们的现场', alt: '' },
      { image: 'gallery/04-aperture.png', title: '想法发生的地方', alt: '' },
      { image: 'gallery/05-connection.png', title: '和同路人同行', alt: '' },
      { image: 'gallery/06-next.png', title: '下一个可能', alt: '' },
    ],
  },
  model: {
    desktop: `${import.meta.env.BASE_URL}models/journey-desktop.glb`,
    mobile: `${import.meta.env.BASE_URL}models/journey-mobile.glb`,
    dracoPath: `${import.meta.env.BASE_URL}draco/`,
  },
  scene: {
    background: '#86C3F5',
    exposure: 0.93,
    smoothing: 7.5,
    // The original authored animation is 8 1/3 seconds, including the camera.
    start: 0.02,
    end: 1,
    parallax: 0.055,
  },
};
