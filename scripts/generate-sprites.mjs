import sharp from 'sharp'
import { writeFileSync } from 'fs'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'
import { createRequire } from 'module'

const cjsRequire = createRequire(import.meta.url)
const __dirname = dirname(fileURLToPath(import.meta.url))

const iconNodes = cjsRequire('lucide-static/icon-nodes.json')

const ICON_SIZE = 32
const MAX_SHEET_PX = 1024
const COLS = Math.floor(MAX_SHEET_PX / ICON_SIZE)          // 32 columns
const ICONS_PER_SHEET = COLS * COLS                         // 1024 icons per sheet

const BLOCKED = new Set([
	"beer",
	"beer-off",
	"wine",
	"wine-off",
	"bottle-wine",
	"cigarette",
	"cigarette-off",
])

function buildSvg(nodes) {
	const elements = nodes.map(([tag, attrs]) => {
		const attrStr = Object.entries(attrs).map(([k, v]) => `${k}="${v}"`).join(' ')
		return `<${tag} ${attrStr}/>`
	}).join('')
	return `<svg xmlns="http://www.w3.org/2000/svg" width="${ICON_SIZE}" height="${ICON_SIZE}" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${elements}</svg>`
}

const names = Object.keys(iconNodes).filter(n => !BLOCKED.has(n)).sort()
const sheetCount = Math.ceil(names.length / ICONS_PER_SHEET)

console.log(`${names.length} icons → ${sheetCount} sheet(s) of up to ${ICONS_PER_SHEET}, ${COLS} cols at ${ICON_SIZE}px`)

const positions = {}
let composites = []

for (let i = 0; i < names.length; i++) {
	const name = names[i]
	const localIdx = i % ICONS_PER_SHEET
	const sheet = Math.floor(i / ICONS_PER_SHEET)
	const col = localIdx % COLS
	const row = Math.floor(localIdx / COLS)
	const x = col * ICON_SIZE
	const y = row * ICON_SIZE

	positions[name] = { sheet: sheet + 1, x, y }

	const buffer = await sharp(Buffer.from(buildSvg(iconNodes[name])))
		.resize(ICON_SIZE, ICON_SIZE)
		.png()
		.toBuffer()
	composites.push({ input: buffer, left: x, top: y })

	const isLastOnSheet = localIdx === ICONS_PER_SHEET - 1
	const isLast = i === names.length - 1

	if (isLastOnSheet || isLast) {
		const iconsOnSheet = composites.length
		const sheetRows = Math.ceil(iconsOnSheet / COLS)
		const outPath = join(__dirname, `../sprite${sheet + 1}.png`)
		await sharp({
			create: {
				width: COLS * ICON_SIZE,
				height: sheetRows * ICON_SIZE,
				channels: 4,
				background: { r: 0, g: 0, b: 0, alpha: 0 },
			},
		}).composite(composites).png().toFile(outPath)
		console.log(`\nSaved sprite${sheet + 1}.png (${iconsOnSheet} icons, ${COLS}x${sheetRows})`)
		composites = []
	}

	if ((i + 1) % 100 === 0 || isLast) {
		process.stdout.write(`\r  Rasterizing ${i + 1}/${names.length}...`)
	}
}

const luauLines = [
	'-- Created by scripts/generate-sprites.mjs',
	'-- WARNING! All changes made in this file will be lost!',
	'return {',
	`\ticonSize = ${ICON_SIZE},`,
	'\tsprites = {',
]
for (let i = 0; i < sheetCount; i++) {
	luauLines.push(`\t\t"rbxassetid://REPLACE_ME_SHEET${i + 1}",`)
}
luauLines.push('\t},')
luauLines.push('\ticons = {')
for (const [name, { sheet, x, y }] of Object.entries(positions).sort(([a], [b]) => a.localeCompare(b))) {
	luauLines.push(`\t\t["${name}"] = { ${sheet}, ${x}, ${y} },`)
}
luauLines.push('\t},')
luauLines.push('}')

const luauPath = join(__dirname, '../src/Modules/Assets.luau')
writeFileSync(luauPath, luauLines.join('\n') + '\n')
console.log(`Saved src/Modules/Assets.luau`)
console.log(`Upload ${Array.from({ length: sheetCount }, (_, i) => `sprite${i + 1}.png`).join(', ')} and replace the asset IDs in Assets.luau`)
