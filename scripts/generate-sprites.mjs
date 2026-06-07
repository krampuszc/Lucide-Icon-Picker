// Reads Lucide icon SVG data, rasterizes every icon into a single sprite sheet PNG,
// and writes src/Modules/Assets.luau with each icon's pixel position in that sheet.
//
// Run with:  npm run generate
// Then upload sprite.png to Roblox and paste the asset ID into Assets.luau.

import sharp from 'sharp'
import { writeFileSync } from 'fs'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'
import { createRequire } from 'module'

const BLOCKED = new Set([
    "beer",
    "beer-off",
    "wine",
    "wine-off",
    "bottle-wine",
    "cigarette",
    "cigarette-off",
])

const cjsRequire = createRequire(import.meta.url)
const __dirname = dirname(fileURLToPath(import.meta.url))

const iconNodes = cjsRequire('lucide-static/icon-nodes.json')

const ICON_SIZE = 24

function buildSvg(nodes) {
    const elements = nodes.map(([tag, attrs]) => {
        const attrStr = Object.entries(attrs).map(([k, v]) => `${k}="${v}"`).join(' ')
        return `<${tag} ${attrStr}/>`
    }).join('')

    return [
        `<svg xmlns="http://www.w3.org/2000/svg"`,
        `     width="${ICON_SIZE}" height="${ICON_SIZE}"`,
        `     viewBox="0 0 24 24"`,
        `     fill="none" stroke="white" stroke-width="2"`,
        `     stroke-linecap="round" stroke-linejoin="round">`,
        elements,
        `</svg>`,
    ].join('')
}

const names = Object.keys(iconNodes).filter(n => !BLOCKED.has(n)).sort()
const cols = Math.ceil(Math.sqrt(names.length))
const rows = Math.ceil(names.length / cols)
const spriteWidth = cols * ICON_SIZE
const spriteHeight = rows * ICON_SIZE

console.log(`${names.length} icons → ${cols}x${rows} grid → ${spriteWidth}x${spriteHeight}px sprite`)

const composites = []
const positions = {}

for (let i = 0; i < names.length; i++) {
    const name = names[i]
    const col = i % cols
    const row = Math.floor(i / cols)
    const x = col * ICON_SIZE
    const y = row * ICON_SIZE

    positions[name] = { x, y }

    const svg = buildSvg(iconNodes[name])
    const buffer = await sharp(Buffer.from(svg))
        .resize(ICON_SIZE, ICON_SIZE)
        .png()
        .toBuffer()

    composites.push({ input: buffer, left: x, top: y })

    if (i % 100 === 0 || i === names.length - 1) {
        process.stdout.write(`\r  Rasterizing ${i + 1}/${names.length}...`)
    }
}
console.log(' done.')

const spritePath = join(__dirname, '../sprite.png')
await sharp({
    create: {
        width: spriteWidth,
        height: spriteHeight,
        channels: 4,
        background: { r: 0, g: 0, b: 0, alpha: 0 },
    },
})
    .composite(composites)
    .png()
    .toFile(spritePath)

console.log(`Saved sprite → sprite.png  (upload this to Roblox as a Decal)`)

const lines = [
    '-- Created by SCRIPTS/generate-sprites.mjs',
    '-- WARNING! All changes made in this file will be lost!',
    'return {',
    '\tspriteId = "rbxassetid://REPLACE_ME",',
    `\ticonSize = ${ICON_SIZE},`,
    `\tcols = ${cols},`,
    '\ticons = {',
]

for (const [name, { x, y }] of Object.entries(positions).sort(([a], [b]) => a.localeCompare(b))) {
    lines.push(`\t\t["${name}"] = { ${x}, ${y} },`)
}

lines.push('\t},')
lines.push('}')

const luauPath = join(__dirname, '../src/Modules/Assets.luau')
writeFileSync(luauPath, lines.join('\n') + '\n')
console.log(`Saved icon table → src/Modules/Assets.luau`)
