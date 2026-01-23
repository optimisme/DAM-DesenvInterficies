const fs = require('fs')
const { open } = require('sqlite')
const sqlite3 = require('sqlite3')

function quoteIdent (name) {
  const safe = String(name).replace(/"/g, '""')
  return `"${safe}"`
}

async function getDbSchemaText (config) {
  const { dbPath } = config
  let db
  try {
    db = await open({ filename: dbPath, driver: sqlite3.Database })
    const tables = await db.all(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
    )

    if (!Array.isArray(tables) || tables.length === 0) {
      return '(no tables found)'
    }

    const parts = []
    for (const t of tables) {
      const tableName = t?.name
      if (typeof tableName !== 'string' || !tableName.trim()) continue
      const cols = await db.all(`PRAGMA table_info(${quoteIdent(tableName)})`)
      const colText = (cols || [])
        .map((c) => {
          const name = c?.name
          const type = c?.type || ''
          const pk = c?.pk ? ' PK' : ''
          const nn = c?.notnull ? ' NOT NULL' : ''
          return typeof name === 'string' ? `${name} ${type}${pk}${nn}`.trim() : null
        })
        .filter(Boolean)
        .join(', ')
      parts.push(`- ${tableName}: ${colText || '(no columns)'}`)
    }

    return parts.join('\n')
  } catch (error) {
    return `Failed to read schema: ${error.message || String(error)}`
  } finally {
    if (db) await db.close()
  }
}

async function dbQuery ({ query, config }) {
  const { dbPath } = config
  if (typeof query !== 'string') return { error: 'Invalid query.' }

  const trimmed = query.trim()
  const normalized = trimmed.replace(/;+\s*$/, '')

  const lower = normalized.toLowerCase()
  if (!lower.startsWith('select') && !lower.startsWith('with')) {
    return { error: 'Only SELECT queries are allowed.' }
  }
  if (/\b(insert|update|delete|drop|alter|create|replace|pragma|attach|detach|vacuum)\b/i.test(normalized)) {
    return { error: 'Only read-only SELECT queries are allowed.' }
  }
  if (normalized.includes(';')) {
    return { error: 'Multiple statements are not allowed.' }
  }

  let db
  try {
    db = await open({ filename: dbPath, driver: sqlite3.Database })
    const rows = await db.all(normalized)
    return { rows }
  } catch (error) {
    return { error: error.message || 'Query failed.' }
  } finally {
    if (db) await db.close()
  }
}

async function ensureDatabase (config) {
  const { dbPath, dataDir, jsonPath } = config
  if (fs.existsSync(dbPath)) {
    return
  }

  await fs.promises.mkdir(dataDir, { recursive: true })
  const raw = await fs.promises.readFile(jsonPath, 'utf8')
  const parsed = JSON.parse(raw)
  const planets = Array.isArray(parsed.planets) ? parsed.planets : []

  const db = await open({ filename: dbPath, driver: sqlite3.Database })
  await db.exec(`
    CREATE TABLE IF NOT EXISTS planets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      radius_km REAL,
      diameter_km REAL,
      mass_kg REAL,
      gravity_ms2 REAL,
      average_distance_to_sun_km REAL,
      average_distance_to_sun_AU REAL,
      orbital_period_days REAL,
      rotation_period_hours REAL,
      axial_inclination_degrees REAL,
      number_of_moons INTEGER
    );
  `)

  const stmt = await db.prepare(`
    INSERT INTO planets (
      name,
      radius_km,
      diameter_km,
      mass_kg,
      gravity_ms2,
      average_distance_to_sun_km,
      average_distance_to_sun_AU,
      orbital_period_days,
      rotation_period_hours,
      axial_inclination_degrees,
      number_of_moons
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `)

  try {
    await db.exec('BEGIN')
    for (const planet of planets) {
      await stmt.run(
        planet.name ?? null,
        planet.radius_km ?? null,
        planet.diameter_km ?? null,
        planet.mass_kg ?? null,
        planet.gravity_ms2 ?? null,
        planet.average_distance_to_sun_km ?? null,
        planet.average_distance_to_sun_AU ?? null,
        planet.orbital_period_days ?? null,
        planet.rotation_period_hours ?? null,
        planet.axial_inclination_degrees ?? null,
        planet.number_of_moons ?? null
      )
    }
    await db.exec('COMMIT')
  } catch (error) {
    await db.exec('ROLLBACK')
    throw error
  } finally {
    await stmt.finalize()
    await db.close()
  }
}

async function initDb (config) {
  await ensureDatabase(config)
}

module.exports = {
  initDb,
  dbQuery,
  getDbSchemaText
}
