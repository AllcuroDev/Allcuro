// URLs for the realistic category photos and illustrations
const arts = import.meta.glob<string>([
  '../assets/images/categories/*.jpg',
  '../assets/images/categories/*.png',
  '../assets/illustrations/*.svg'
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
