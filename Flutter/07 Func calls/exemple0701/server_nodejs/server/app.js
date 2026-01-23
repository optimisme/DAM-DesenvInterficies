const express = require('express')
const config = require('./config')
const db = require('./db')
const {
  buildTools,
  buildSystemPrompt,
  getJsonRepairSystemPrompt,
  getJudgeEquivalenceSystemPrompt,
  getJudgeTiebreakerSystemPrompt
} = require('./promptTools')
const { createOllamaAgent } = require('./ollamaAgent')

const app = express()
const port = config.port
let httpServer

const tools = buildTools(config.HISTORY_LIMIT)
const agent = createOllamaAgent({
  config,
  tools,
  db,
  buildSystemPrompt,
  getJsonRepairSystemPrompt,
  getJudgeEquivalenceSystemPrompt,
  getJudgeTiebreakerSystemPrompt
})

app.use(express.static('public'))
app.use(express.json({ limit: '1mb' }))
app.use((req, res, next) => {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate')
  res.setHeader('Pragma', 'no-cache')
  res.setHeader('Expires', '0')
  res.setHeader('Surrogate-Control', 'no-store')
  next()
})

app.get('/', async (req, res) => {
  res.send('Hello World /')
})

app.post('/chat', async (req, res) => {
  await agent.handleChat(req, res)
})

async function startServer () {
  try {
    await db.initDb(config)
    httpServer = app.listen(port, appListen)
  } catch (error) {
    console.error('Failed to start server:', error)
    process.exit(1)
  }
}

startServer()

function appListen () {
  console.log(`Example app listening on: http://0.0.0.0:${port}`)
}

process.on('SIGTERM', shutDown)
process.on('SIGINT', shutDown)
function shutDown () {
  console.log('Received kill signal, shutting down gracefully')
  if (httpServer) {
    httpServer.close()
  }
  process.exit(0)
}
