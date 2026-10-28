// URLs for the 3D claymorphic category icons
const arts = import.meta.glob<string>([
  '../assets/images/categories/*.png',
  '../assets/images/categories/*.jpg',
], {
  query: '?url',
  import: 'default',
  eager: true,
})

const artByName = Object.fromEntries(
  Object.entries(arts).map(([path, url]) => {
    const filename = path.split('/').pop()!
    const name = filename.substring(0, filename.lastIndexOf('.'))
    return [name, url]
  }),
)

export const artUrl = (name: string) => artByName[name] ?? artByName.see_all ?? ''

// URLs for the 3D claymorphic individual service icons
const serviceArts = import.meta.glob<string>([
  '../assets/images/services/*.png',
  '../assets/images/services/*.jpg',
], {
  query: '?url',
  import: 'default',
  eager: true,
})

const serviceArtByName = Object.fromEntries(
  Object.entries(serviceArts).map(([path, url]) => {
    const filename = path.split('/').pop()!
    const name = filename.substring(0, filename.lastIndexOf('.'))
    return [name, url]
  }),
)

export const serviceArtUrl = (name: string) => serviceArtByName[name] ?? artByName[name] ?? ''

