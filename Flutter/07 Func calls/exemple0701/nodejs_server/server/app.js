const express = require('express')
const fs = require('fs')
const path = require('path')
const { open } = require('sqlite')
const sqlite3 = require('sqlite3')

const app = express()
const port = 3000
let httpServer

const dataDir = path.join(__dirname, 'data')
const dbPath = process.env.SQLITE_PATH || path.join(dataDir, 'planets.sqlite')
const jsonPath = path.join(__dirname, 'data', 'planets.json')

// If calling MarIA models from local host, set up tunneling before:
// ssh -i $HOME/.ssh/id_rsa -p 20127 -L 11414:192.168.1.14:11434 apalaci8@ieticloudpro.ieti.cat
// ssh -i $HOME/.ssh/id_rsa -p 20127 -L 11424:192.168.1.24:11434 apalaci8@ieticloudpro.ieti.cat

const MODE_LOCAL      = 0
const MODE_CALL_MARIA = 1
const MODE_PROXMOX    = 2

var mode = MODE_CALL_MARIA

const localOllama = 'http://localhost:11434/api/chat'
const maria14local = 'http://localhost:11414/api/chat'
const maria24local = 'http://localhost:11424/api/chat'
const maria14proxmox = 'http://192.168.1.14:11434/api/chat'
const maria24proxmox = 'http://192.168.1.24:11434/api/chat'

const model_Granite3b = 'granite4:3b'
const model_Granite8b = 'granite3.3:8b'
const model_Qwen8b    = 'qwen3:8b'
//const model_Qwen3b    = 'qwen2.5:3b'

var primaryModelAUrl   = localOllama
var primaryModelBUrl   = localOllama
var judgeModelUrl      = localOllama
var tiebreakerModelUrl = localOllama
var jsonRepairModelUrl = localOllama

var primaryModelA   = model_Granite3b
var primaryModelB   = model_Granite3b
var judgeModel      = model_Granite3b
var tiebreakerModel = model_Granite3b
var jsonRepairModel = model_Granite3b

if (mode != MODE_LOCAL) {

    primaryModelA   = model_Granite3b
    primaryModelB   = model_Qwen8b
    judgeModel      = model_Granite8b
    tiebreakerModel = model_Granite3b
    jsonRepairModel = model_Granite3b

    if (mode == MODE_CALL_MARIA) {

      primaryModelAUrl   = maria14local
      primaryModelBUrl   = maria24local
      judgeModelUrl      = maria14local
      tiebreakerModelUrl = maria24local
      jsonRepairModelUrl = maria24local

    } else if (mode == MODE_PROXMOX) {

      primaryModelAUrl   = maria14proxmox
      primaryModelBUrl   = maria24proxmox
      judgeModelUrl      = maria14proxmox
      tiebreakerModelUrl = maria24proxmox
      jsonRepairModelUrl = maria24proxmox
    }
}

const HISTORY_LIMIT = 15

const sessions = new Map()

// Continguts estàtics (carpeta public)
app.use(express.static('public'))
app.use(express.json({ limit: '1mb' }))
app.use((req, res, next) => {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate')
  res.setHeader('Pragma', 'no-cache')
  res.setHeader('Expires', '0')
  res.setHeader('Surrogate-Control', 'no-store')
  next()
})

// Configurar direcció '/'
app.get('/', async (req, res) => {
  res.send(`Hello World /`)
})

// Configurar direcció '/chat' (post)
app.post('/chat', async (req, res) => {
  const requestId = `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`
  const startedAt = Date.now()
  const userMessage = req.body?.message
  const sessionId = getSessionId(req)
  if (shouldResetSession(req)) {
    sessions.delete(sessionId)
  }
  const session = getSession(sessionId)

  if (!userMessage || typeof userMessage !== 'string') {
    console.log(`[request ${requestId}] Invalid body:`, req.body)
    res.status(400).json({ error: 'Missing "message" string in request body.' })
    return
  }

  try {
    console.log(`[request ${requestId}] Received prompt: ${previewText(userMessage)}`)
    const schemaText = await getDbSchemaText()

    const tools = [
      {
        type: 'function',
        function: {
          name: 'dbQuery',
          description: 'Run a read-only SQLite query. Only SELECT (or WITH ... SELECT) is allowed.',
          parameters: {
            type: 'object',
            properties: {
              query: {
                type: 'string',
                description: 'A complete SQLite SELECT query. Examples: \
                  "SELECT name, mass_kg FROM planets ORDER BY mass_kg DESC LIMIT 5", \
                  "SELECT name FROM users WHERE age >= 18", \
                  "SELECT title, year FROM movies WHERE year > 2000 ORDER BY year DESC", \
                  "SELECT country, COUNT(*) FROM users GROUP BY country", \
                  "SELECT p.name, c.name FROM products p JOIN categories c ON p.category_id = c.id"'
              }
            },
            required: ['query']
          }
        }
      },
      {
        type: 'function',
        function: {
          name: 'directAnswer',
          description:
            'Return a response directly to the user when their request does NOT require querying the SQLite database. Use this when the request is general knowledge, instructions, or otherwise unrelated to the database data.',
          parameters: {
            type: 'object',
            properties: {
              answer: {
                type: 'string',
                description: 'The exact final message to send to the user. Keep it concise and helpful.'
              }
            },
            required: ['answer']
          }
        }
      },
      {
        type: 'function',
        function: {
          name: 'getValidatedHistory',
          description:
            'Get the last validated user/assistant turns for this session (most recent last). Use only if it helps maintain context. Returns an array of {user, assistant}.',
          parameters: {
            type: 'object',
            properties: {
              limit: {
                type: 'integer',
                description: `How many turns to return (max ${HISTORY_LIMIT}). Default ${HISTORY_LIMIT}.`
              }
            }
          }
        }
      }
    ]

    const systemPrompt = [
      'You are a SQLite database agent. The SQLite database is the ONLY source of truth.',
      'Do NOT use outside knowledge. Do NOT guess. Do NOT invent names or values.',
      '',
      'You have exactly these tools: dbQuery, directAnswer, getValidatedHistory.',
      '',
      'When to use tools:',
      '- If the user question can be answered ONLY using the database (planets data): you MUST call dbQuery.',
      '- Use directAnswer ONLY when the request is clearly unrelated to the database content.',
      '- You have access to previous conversation turns via the getValidatedHistory tool.',
      '- Use getValidatedHistory ONLY when the current user request depends on earlier context.',
      '- If the request is self-contained, do NOT call getValidatedHistory.',
      '',
      'ABSOLUTE RULE (planets domain):',
      '- For ANY question about planets (names, moons, diameter, gravity, distance, mass, rotation, orbit, inclination, etc.) you MUST call dbQuery BEFORE writing ANY planet name or ANY numeric value.',
      '',
      'Tool-call formatting rules (critical):',
      '- You MUST use the tool-call mechanism. Do NOT write tool calls as plain text.',
      '- Do NOT write: "dbQuery { ... }" or "Assistant dbQuery ...".',
      '- Do NOT write SQL or JSON in markdown code fences. Do NOT use ```.',
      '- Do NOT explain your plan before calling a tool.',
      '',
      'dbQuery rules:',
      '- Call dbQuery with exactly one argument: {"query":"<full SQL SELECT>"}',
      '- Only SELECT queries are allowed (WITH ... SELECT is allowed).',
      '- Never use: INSERT, UPDATE, DELETE, DROP, ALTER, PRAGMA, CREATE, REPLACE, ATTACH, DETACH, VACUUM.',
      '- Only one statement. No semicolons inside the query.',
      '',
      'Grounding rules:',
      '- Every planet name you mention MUST appear in dbQuery rows returned in THIS conversation.',
      '- Every numeric value you mention MUST appear in dbQuery rows returned in THIS conversation.',
      '- If dbQuery returns 0 rows, respond with exactly "0".',
      '',
      'Query strategy:',
      '- Prefer a single query (JOIN/subquery) if it directly answers the question.',
      '- You may call dbQuery multiple times if needed for intermediate steps.',
      '- If doing multi-step queries, include all columns needed for the next step.',
      '',
      'Failure handling:',
      '- If a dbQuery fails, you will see the SQLite error.',
      '- Then do exactly ONE of these:',
      '  (1) Call dbQuery again with a corrected SQL SELECT query.',
      '  (2) Ask a clarification question (no tool call) ONLY if required info is missing.',
      '',
      'Output formatting:',
      '- After you have the needed rows, answer in the user language.',
      '- If you return rows, include a markdown table.',
      '- If the user asks for "all data" / "totes les dades", use SELECT * (or list all columns).',
      '- Do NOT use LaTeX notation (no \hline, no \begin, no \end, no $...$, etc.).',
      '- Allowed formatting ONLY:',
      '  - Plain text',
      '  - Markdown emphasis: *italic* and **bold**',
      '  - Markdown tables',
      '  - Do NOT use any other Markdown features (no code blocks, no headings, no lists, no HTML).',
      '',
      'Database schema (tables and columns):',
      schemaText
    ].join('\\n')


    const candidateModels = [
      { model: primaryModelA, url: primaryModelAUrl },
      { model: primaryModelB, url: primaryModelBUrl }
    ]
    console.log(`[request ${requestId}] Action: run candidate models in parallel`)
    const candidatePromises = candidateModels.map(({ model, url }) =>
      runAssistantWithTools({
        model,
        url,
        userMessage,
        systemPrompt,
        tools,
        requestId,
        session
      }).catch((error) => ({
        model,
        answer: '',
        status: 'error',
        error: error?.message || 'candidate failed',
        evidence: [],
        messages: []
      }))
    )

    const candidates = await Promise.all(candidatePromises)
    const directAnswerCandidate = candidates.find((c) => c?.status === 'direct')

    if (directAnswerCandidate) {
      const finalAnswer = finalizeCandidateAnswer({ selected: directAnswerCandidate, candidates: [directAnswerCandidate] })
      addValidatedTurn(session, userMessage, finalAnswer)
      console.log(
        `[request ${requestId}] Selected model: ${directAnswerCandidate.model || 'unknown'} (directAnswer path)`
      )
      res.json({ message: finalAnswer })
      console.log(
        `[request ${requestId}] completed in ${Date.now() - startedAt}ms (direct answer, no multi-model judgment)`
      )
      return
    }

    console.log(`[request ${requestId}] Action: judge equivalence -> ${judgeModel}`)
    const firstJudge = await judgeCandidatesEquivalent({
      question: userMessage,
      candidates,
      judgeModel,
      judgeUrl: judgeModelUrl,
      requestId
    })

    if (firstJudge?.issues?.length) {
      console.log(`[request ${requestId}] Judge issues: ${previewText(JSON.stringify(firstJudge.issues), 160)}`)
    }

    let selected = pickCandidateByIndex(candidates, firstJudge?.best_index)

    if (firstJudge?.equivalent !== true) {
      console.log(`[request ${requestId}] Action: judge non-equivalence, run tiebreaker -> ${tiebreakerModel}`)
      const tiebreaker = await runAssistantWithTools({
        model: tiebreakerModel,
        url: tiebreakerModelUrl,
        userMessage,
        systemPrompt,
        tools,
        requestId,
        session
      })
      candidates.push(tiebreaker)

      console.log(`[request ${requestId}] Action: judge with tiebreaker -> ${judgeModel}`)
      const secondJudge = await judgeCandidatesWithTiebreaker({
        question: userMessage,
        candidates,
        judgeModel,
        judgeUrl: judgeModelUrl,
        requestId
      })

      if (secondJudge?.issues?.length) {
        console.log(`[request ${requestId}] Judge (tiebreak) issues: ${previewText(JSON.stringify(secondJudge.issues), 160)}`)
      }

      selected = pickCandidateByIndex(candidates, secondJudge?.best_index)
    }

    console.log(`[request ${requestId}] Action: finalize response`)
    const finalAnswer = finalizeCandidateAnswer({ selected, candidates })
    const chosenModel = selected?.answer?.trim()
      ? selected.model
      : pickBestFallbackCandidate(candidates)?.model || 'unknown'
    if (!finalAnswer) {
      res.status(400).json({ error: 'No valid answer produced.' })
      return
    }

    addValidatedTurn(session, userMessage, finalAnswer)
    console.log(`[request ${requestId}] Selected model: ${chosenModel}`)
    res.json({ message: finalAnswer })
    console.log(`[request ${requestId}] completed in ${Date.now() - startedAt}ms`)
    return
  } catch (error) {
    console.error(`[request ${requestId}] Chat error:`, error)
    res.status(500).json({ error: 'Chat processing failed.' })
  }
})

function stripCodeFences (text) {
  if (typeof text !== 'string') return ''
  return text
    .replace(/```[a-zA-Z0-9_-]*\n?/g, '')
    .replace(/```/g, '')
    .trim()
}

function fixJsonInStrings (data) {
  if (data && typeof data === 'object' && !Array.isArray(data)) {
    return Object.fromEntries(Object.entries(data).map(([key, value]) => [key, fixJsonInStrings(value)]))
  }
  if (Array.isArray(data)) {
    return data.map(fixJsonInStrings)
  }
  if (typeof data === 'string') {
    try {
      const parsed = JSON.parse(data)
      return fixJsonInStrings(parsed)
    } catch (_) {
      return data
    }
  }
  return data
}

function parseJsonString (value) {
  if (typeof value !== 'string') return value
  const cleaned = stripCodeFences(value)
    .replace(/«|»/g, '"')
    .replace(/"op"\s*:\s*"([^"]*)""/g, '"op":"$1"')
  try {
    return JSON.parse(cleaned)
  } catch (_) {
    return value
  }
}

async function repairJsonWithModel ({ text, requestId = 'n/a', context = '' }) {
  const system = [
    'You are a JSON repair assistant.',
    'Fix the following content into valid JSON.',
    'Return ONLY valid JSON. No extra text.'
  ].join('\n')

  try {
    console.log(`[request ${requestId}] Action: repair JSON${context ? ` (${context})` : ''} -> ${jsonRepairModel}`)
    const resp = await ollamaChat({
      model: jsonRepairModel,
      url: jsonRepairModelUrl,
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: text }
      ]
    })
    const fixed = typeof resp?.message?.content === 'string' ? resp.message.content.trim() : ''
    return fixed
  } catch (error) {
    console.error(`[request ${requestId}] JSON repair error:`, error)
    return ''
  }
}

async function parseJsonWithRepair ({ text, requestId = 'n/a', context = '' }) {
  const parsed = parseJsonString(text)
  if (parsed && typeof parsed === 'object') {
    return parsed
  }
  if (typeof text !== 'string' || !text.trim()) {
    return null
  }

  console.log(`[request ${requestId}] JSON parse failed${context ? ` (${context})` : ''}. Trying repair.`)
  const repaired = await repairJsonWithModel({ text, requestId, context })
  if (!repaired) {
    return null
  }

  const parsedRepaired = parseJsonString(repaired)
  if (parsedRepaired && typeof parsedRepaired === 'object') {
    return parsedRepaired
  }

  console.log(`[request ${requestId}] JSON repair parse failed${context ? ` (${context})` : ''}.`)
  return null
}

function coerceToolCallFromContent (message) {
  if (!message || message.tool_calls?.length) {
    return message
  }
  const contentRaw = typeof message.content === 'string' ? message.content.trim() : ''
  const content = stripCodeFences(contentRaw)
  if (!content) {
    return message
  }

  const parsed = parseJsonString(content)
  if (!parsed || typeof parsed !== 'object') {
    return message
  }

  if (Array.isArray(parsed.tool_calls) && parsed.tool_calls.length > 0) {
    return { ...message, tool_calls: parsed.tool_calls }
  }

  let args = null
  if (typeof parsed === 'string') {
    args = { query: parsed }
  } else if (parsed.name === 'dbQuery') {
    args = parsed.arguments ?? parsed.parameters ?? parsed.params ?? parsed
  } else if (parsed.function?.name === 'dbQuery') {
    args = parsed.function.arguments ?? parsed.function.parameters ?? parsed.function.params ?? parsed.function
  } else if (typeof parsed.query === 'string') {
    args = { query: parsed.query }
  }

  if (!args || typeof args.query !== 'string' || !args.query.trim()) {
    return message
  }

  return {
    ...message,
    tool_calls: [
      {
        type: 'function',
        function: {
          name: 'dbQuery',
          arguments: { query: args.query }
        }
      }
    ]
  }
}

function getSessionId (req) {
  const headerId = req.get('x-session-id') || req.get('x-session')
  if (headerId && typeof headerId === 'string' && headerId.trim()) {
    return headerId.trim()
  }
  const agent = typeof req.get('user-agent') === 'string' ? req.get('user-agent') : ''
  const ip = req.ip || req.connection?.remoteAddress || 'local'
  return `${ip}:${agent}`
}

function getSession (sessionId) {
  if (!sessions.has(sessionId)) {
    sessions.set(sessionId, { lastRows: null, lastResultAt: null, lastSelect: null, validatedHistory: [] })
  }
  return sessions.get(sessionId)
}

function shouldResetSession (req) {
  const header = req.get('x-session-reset')
  if (typeof header === 'string' && ['1', 'true', 'yes'].includes(header.toLowerCase().trim())) {
    return true
  }
  return req.body?.reset_session === true
}

function normalizeToolArgs (args) {
  if (typeof args === 'string') {
    return { query: args }
  }
  if (!args || typeof args !== 'object') {
    return { error: 'Invalid tool arguments.' }
  }

  if (args.arguments && typeof args.arguments === 'object') args = args.arguments
  if (args.params && typeof args.params === 'object') args = args.params
  if (args.parameters && typeof args.parameters === 'object') args = args.parameters
  if (args.object && typeof args.object === 'object' && !Array.isArray(args.object)) args = args.object

  if (typeof args.query === 'string') return { query: args.query }
  if (typeof args.sql === 'string') return { query: args.sql }
  if (typeof args.statement === 'string') return { query: args.statement }

  const onlyKey = Object.keys(args)
  if (onlyKey.length === 1 && typeof args[onlyKey[0]] === 'string') {
    return { query: args[onlyKey[0]] }
  }

  return { error: 'Missing "query" string for dbQuery.' }
}

function previewText (text, maxLength = 25) {
  const value = typeof text === 'string' ? text.trim() : ''
  if (value.length <= maxLength) return value
  return `${value.slice(0, maxLength - 1)}…`
}

function latestUserPrompt (messages) {
  for (let i = messages.length - 1; i >= 0; i -= 1) {
    if (messages[i]?.role === 'user') return typeof messages[i].content === 'string' ? messages[i].content : ''
  }
  return ''
}

function getLastToolResult (messages) {
  const lastToolMessage = [...messages].reverse().find((msg) => msg.role === 'tool')
  if (!lastToolMessage?.content) return null
  try {
    return JSON.parse(lastToolMessage.content)
  } catch (_) {
    return null
  }
}

function formatRowsAsTable (rows) {
  if (!Array.isArray(rows) || rows.length === 0) return '0'
  const header = Object.keys(rows[0] || {})
  if (header.length === 0) return '0'
  const headerRow = `| ${header.join(' | ')} |`
  const separator = `| ${header.map(() => '---').join(' | ')} |`
  const dataRows = rows.map((row) => {
    const cells = header.map((key) => {
      const value = row?.[key]
      return value === null || value === undefined ? '' : String(value)
    })
    return `| ${cells.join(' | ')} |`
  })
  return [headerRow, separator, ...dataRows].join('\n')
}

async function runToolCalls (assistantMessage, messages, requestId = 'n/a', session = null) {
  let toolHadError = false
  let directAnswerResult = null
  messages.push(assistantMessage)

  for (const toolCall of assistantMessage.tool_calls) {
    const toolName = toolCall?.function?.name
    const rawArgs = toolCall?.function?.arguments
    let args = {}

    if (rawArgs) {
      try {
        let parsedArgs
        if (typeof rawArgs === 'string') {
          try {
            parsedArgs = JSON.parse(rawArgs)
          } catch (_) {
            parsedArgs = await parseJsonWithRepair({
              text: rawArgs,
              requestId,
              context: `tool args for ${toolName || 'unknown'}`
            })
          }
        } else {
          parsedArgs = rawArgs
        }

        if (!parsedArgs) {
          throw new Error('Invalid tool arguments JSON.')
        }
        console.log(`[request ${requestId}] Raw parsed args:`, JSON.stringify(parsedArgs, null, 2))
        args = fixJsonInStrings(parsedArgs)
        console.log(`[request ${requestId}] After fixJsonInStrings:`, JSON.stringify(args, null, 2))
      } catch (_) {
        args = { error: 'Invalid tool arguments JSON.' }
      }
    }
    console.log(`[request ${requestId}] Running tools: ${toolName}`)

    let result
    try {
      if (args.error) {
        result = { error: args.error }
      } else if (toolName === 'dbQuery') {
        args = normalizeToolArgs(args)
        console.log(`[request ${requestId}] Final args:`, JSON.stringify(args, null, 2))
        console.log(`[request ${requestId}] Running SQL query: ${previewText(args.query, 120)}`)
        result = await dbQuery({ query: args.query })
        console.log(`[request ${requestId}] SQL rows returned: ${Array.isArray(result.rows) ? result.rows.length : 'n/a'}`)
        if (result.error) {
          console.log(`[request ${requestId}] SQL error: ${result.error}`)
        } else if (session && Array.isArray(result.rows)) {
          session.lastRows = result.rows
          session.lastResultAt = Date.now()
        }
      } else if (toolName === 'getValidatedHistory') {
        const limitRaw = rawArgs && (typeof rawArgs === 'string' ? parseJsonString(rawArgs) : rawArgs)
        const limit = Math.max(0, Math.min(HISTORY_LIMIT, Number(limitRaw?.limit ?? HISTORY_LIMIT) || HISTORY_LIMIT))
        const history = Array.isArray(session?.validatedHistory) ? session.validatedHistory : []
        result = { turns: history.slice(Math.max(0, history.length - limit)) }
      } else if (toolName === 'directAnswer') {
        const answer =
          typeof args === 'string'
            ? args
            : typeof args?.answer === 'string'
              ? args.answer
              : typeof rawArgs === 'string'
                ? rawArgs
                : ''
        result = answer ? { answer: answer.trim() } : { error: 'Missing "answer" string for directAnswer.' }
        if (!result.error) {
          directAnswerResult = result
        }
      } else {
        result = { error: `Unknown tool: ${toolName}` }
      }
    } catch (toolError) {
      console.error(`[request ${requestId}] Tool execution error:`, toolError)
      result = { error: toolError.message || 'Tool execution failed.' }
    }

    if (result?.error) {
      toolHadError = true
      console.log(`[request ${requestId}] Tool error details: ${result.error}`)
      console.log(`[request ${requestId}] Tool args: ${JSON.stringify(args)}`)
    }

    messages.push({
      role: 'tool',
      name: toolName,
      content: JSON.stringify(result)
    })
  }

  return { messages, toolHadError, directAnswerResult }
}

function buildCandidateResult ({ model, answer, messages, status, error }) {
  const finalAnswer = typeof answer === 'string' ? answer.trim() : ''
  return {
    model,
    answer: finalAnswer,
    status,
    error,
    evidence: getToolEvidenceSummary(messages),
    messages
  }
}

async function runAssistantWithTools ({
  model,
  url,
  userMessage,
  systemPrompt,
  tools,
  requestId = 'n/a',
  session = null
}) {
  console.log(`[request ${requestId}] Action: build messages -> ${model}`)
  let messages = [
    { role: 'system', content: systemPrompt },
    { role: 'user', content: userMessage }
  ]

  console.log(`[request ${requestId}] Action: request tool calls -> ${model}`)
  const firstResponse = await ollamaChat({ model, url, messages, tools })
  let assistantMessage = coerceToolCallFromContent(firstResponse?.message)

  if (!assistantMessage?.tool_calls?.length) {
    console.log(`[request ${requestId}] Action: no tool calls, retry -> ${model} (${previewText(assistantMessage?.content ?? '')})`)
    const retryMessages = [
      ...messages,
      {
        role: 'system',
        content:
          'Decide whether the request needs database data. If yes, call dbQuery with a SELECT. If not, call directAnswer with the final response. If the request is unclear, ask a clarification question.'
      }
    ]
    console.log(`[request ${requestId}] Action: retry tool calls -> ${model}`)
    const retryResponse = await ollamaChat({ model, url, messages: retryMessages, tools })
    assistantMessage = coerceToolCallFromContent(retryResponse?.message)
    if (!assistantMessage?.tool_calls?.length) {
      console.log(`[request ${requestId}] Action: still no tool calls -> ${model} (${previewText(assistantMessage?.content ?? '')})`)
    }
  }

  if (!assistantMessage?.tool_calls?.length) {
    if (assistantMessage) {
      messages = [...messages, assistantMessage]
    }
    const finalText = typeof assistantMessage?.content === 'string' ? assistantMessage.content.trim() : ''
    return buildCandidateResult({
      model,
      answer: finalText,
      messages,
      status: finalText ? 'answer' : 'empty'
    })
  }

  let toolRounds = 0
  let lastToolResult = null

  while (assistantMessage?.tool_calls?.length) {
    toolRounds += 1
    if (toolRounds > 5) {
      console.log(`[request ${requestId}] Action: abort tool calls (too many rounds) -> ${model}`)
      return buildCandidateResult({
        model,
        answer: '',
        messages,
        status: 'tool_rounds_exceeded',
        error: 'Too many tool-call rounds.'
      })
    }

    console.log(`[request ${requestId}] Action: run tool calls (round ${toolRounds}) -> ${model}`)
    const run = await runToolCalls(assistantMessage, messages, requestId, session)
    messages = run.messages
    lastToolResult = getLastToolResult(messages)
    if (run.directAnswerResult && !run.directAnswerResult.error) {
      const directText = typeof run.directAnswerResult.answer === 'string' ? run.directAnswerResult.answer.trim() : ''
      console.log(`[request ${requestId}] Action: directAnswer tool used -> ${model}`)
      return buildCandidateResult({
        model,
        answer: directText,
        messages,
        status: 'direct'
      })
    }

    if (run.toolHadError || lastToolResult?.error) {
      const sqliteError = typeof lastToolResult?.error === 'string' ? lastToolResult.error : null
      const originalPrompt = latestUserPrompt(messages)
      const retryMessages = [
        ...messages,
        {
          role: 'system',
          content: [
            'The previous dbQuery failed with a SQLite error.',
            sqliteError ? `SQLite error: ${sqliteError}` : '',
            'Original user request:',
            originalPrompt,
            'Decide what to do next:',
            '- If you can fix it: call dbQuery again with a corrected SQL SELECT query (argument must be {"query": "..."}).',
            '- If the request does not need database data, call directAnswer with the final response to return.',
            '- If you need more info: ask the user a clarification question (no tool call).',
            'Do not invent data.'
          ].filter(Boolean).join('\n')
        }
      ]
      console.log(`[request ${requestId}] Action: tool error, retry -> ${model}`)
      const retryResponse = await ollamaChat({ model, url, messages: retryMessages, tools })
      assistantMessage = coerceToolCallFromContent(retryResponse?.message)

      if (!assistantMessage?.tool_calls?.length) {
        const clarified = typeof assistantMessage?.content === 'string' ? assistantMessage.content.trim() : ''
        if (assistantMessage) {
          messages = [...messages, assistantMessage]
        }
        console.log(`[request ${requestId}] Action: no tool calls after error -> ${model}`)
        return buildCandidateResult({
          model,
          answer: clarified,
          messages,
          status: clarified ? 'clarification' : 'error'
        })
      }
      continue
    }

    if (Array.isArray(lastToolResult?.rows) && lastToolResult.rows.length === 0) {
      console.log(`[request ${requestId}] Action: tool returned 0 rows -> ${model}`)
      messages = [
        ...messages,
        {
          role: 'system',
          content: 'Tool returned 0 rows. Either call dbQuery again with an adjusted query or respond with exactly "0". Do not invent data.'
        }
      ]
    }

    console.log(`[request ${requestId}] Action: request follow-up after tools (round ${toolRounds}) -> ${model}`)
    const nextResponse = await ollamaChat({ model, url, messages, tools })
    assistantMessage = coerceToolCallFromContent(nextResponse?.message)
  }

  const finalText = typeof assistantMessage?.content === 'string' ? assistantMessage.content.trim() : ''
  if (finalText) {
    if (assistantMessage) {
      messages = [...messages, assistantMessage]
    }
    console.log(`[request ${requestId}] Action: final answer ready -> ${model}`)
    return buildCandidateResult({ model, answer: finalText, messages, status: 'answer' })
  }

  const rows = Array.isArray(lastToolResult?.rows) ? lastToolResult.rows : null
  const fallback = rows && rows.length > 0 ? formatRowsAsTable(rows) : '0'
  console.log(`[request ${requestId}] Action: fallback answer -> ${model}`)
  return buildCandidateResult({ model, answer: fallback, messages, status: 'fallback' })
}

function mapCandidateForJudge (candidate, index) {
  return {
    index,
    model: candidate?.model || 'unknown',
    answer: candidate?.answer || '',
    evidence: candidate?.evidence || []
  }
}

async function judgeCandidatesEquivalent ({ question, candidates, judgeModel, judgeUrl, requestId = 'n/a' }) {
  const system = [
    'You are a strict judge comparing answers from different models for a database assistant.',
    'Each candidate includes the answer text and tool evidence (SQL rows).',
    'Determine whether candidates are equivalent in data result (same rows/values).',
    'If equivalent, pick the single best answer that is closest to the user request and best formatted (list/table when rows).',
    'Return ONLY valid JSON with this shape:',
    '{"equivalent": boolean, "best_index": number, "issues": string[]}',
    'No extra text.'
  ].join('\n')

  const payload = {
    question,
    candidates: candidates.map(mapCandidateForJudge)
  }

  try {
    console.log(`[request ${requestId}] Action: judge equivalence prompt -> ${judgeModel}`)
    const resp = await ollamaChat({
      model: judgeModel,
      url: judgeUrl,
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: JSON.stringify(payload, null, 2) }
      ]
    })

    const text = typeof resp?.message?.content === 'string' ? resp.message.content.trim() : ''
    const parsed = await parseJsonWithRepair({ text, requestId, context: 'judge equivalence' })
    if (parsed && typeof parsed === 'object' && typeof parsed.equivalent === 'boolean' && Number.isFinite(parsed.best_index)) {
      return { equivalent: parsed.equivalent, best_index: parsed.best_index, issues: parsed.issues || [] }
    }
  } catch (error) {
    console.error(`[request ${requestId}] Judge error:`, error)
  }

  return { equivalent: false, best_index: -1, issues: ['Judge failed to return valid JSON.'] }
}

async function judgeCandidatesWithTiebreaker ({
  question,
  candidates,
  judgeModel,
  judgeUrl,
  requestId = 'n/a'
}) {
  const system = [
    'You are a strict judge comparing answers from different models for a database assistant.',
    'You MUST use evidence to decide which answers are correct.',
    'Discard any candidate that is unsupported or incorrect.',
    'Return the best answer among the correct ones, preferring closeness to the user request and clear list/table format.',
    'If only one candidate is correct, choose it. If none are correct, choose the least incorrect and explain issues.',
    'Return ONLY valid JSON with this shape:',
    '{"best_index": number, "correct_indices": number[], "issues": string[]}',
    'No extra text.'
  ].join('\n')

  const payload = {
    question,
    candidates: candidates.map(mapCandidateForJudge)
  }

  try {
    console.log(`[request ${requestId}] Action: judge tiebreaker prompt -> ${judgeModel}`)
    const resp = await ollamaChat({
      model: judgeModel,
      url: judgeUrl,
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: JSON.stringify(payload, null, 2) }
      ]
    })

    const text = typeof resp?.message?.content === 'string' ? resp.message.content.trim() : ''
    const parsed = await parseJsonWithRepair({ text, requestId, context: 'judge tiebreaker' })
    if (parsed && typeof parsed === 'object' && Number.isFinite(parsed.best_index)) {
      const correct = Array.isArray(parsed.correct_indices) ? parsed.correct_indices : []
      return { best_index: parsed.best_index, correct_indices: correct, issues: parsed.issues || [] }
    }
  } catch (error) {
    console.error(`[request ${requestId}] Judge (tiebreak) error:`, error)
  }

  return { best_index: -1, correct_indices: [], issues: ['Judge failed to return valid JSON.'] }
}

function scoreAnswerForFallback (answer) {
  if (typeof answer !== 'string') return -Infinity
  const trimmed = answer.trim()
  if (!trimmed) return -Infinity
  let score = 0
  if (/\|/.test(trimmed)) score += 3
  if (/\n- /.test(trimmed)) score += 2
  if (trimmed.includes('\n')) score += 1
  return score
}

function pickCandidateByIndex (candidates, index) {
  if (!Array.isArray(candidates)) return null
  if (!Number.isFinite(index)) return null
  const idx = Math.trunc(index)
  if (idx < 0 || idx >= candidates.length) return null
  return candidates[idx] || null
}

function pickBestFallbackCandidate (candidates) {
  if (!Array.isArray(candidates)) return null
  let best = null
  let bestScore = -Infinity
  for (const candidate of candidates) {
    const score = scoreAnswerForFallback(candidate?.answer)
    if (score > bestScore) {
      bestScore = score
      best = candidate
    }
  }
  return best
}

function finalizeCandidateAnswer ({ selected, candidates }) {
  const chosen = selected?.answer && selected.answer.trim() ? selected.answer.trim() : ''
  if (chosen) return chosen
  const fallback = pickBestFallbackCandidate(candidates)
  return fallback?.answer && fallback.answer.trim() ? fallback.answer.trim() : ''
}

async function getDbSchemaText () {
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

function quoteIdent (name) {
  const safe = String(name).replace(/"/g, '""')
  return `"${safe}"`
}

async function dbQuery ({ query }) {
  if (typeof query !== 'string') return { error: 'Invalid query.' }

  const trimmed = query.trim()
  const normalized = trimmed.replace(/;+\s*$/, '') // Remove trailing semicolons

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

function addValidatedTurn (session, user, assistant) {
  if (!session) return
  if (!Array.isArray(session.validatedHistory)) {
    session.validatedHistory = []
  }
  session.validatedHistory.push({ user, assistant })
  if (session.validatedHistory.length > HISTORY_LIMIT) {
    session.validatedHistory = session.validatedHistory.slice(session.validatedHistory.length - HISTORY_LIMIT)
  }
}

function getToolEvidenceSummary (messages, maxToolMessages = 6) {
  const tools = messages.filter((m) => m?.role === 'tool' && typeof m.content === 'string')
  const tail = tools.slice(Math.max(0, tools.length - maxToolMessages))
  return tail.map((m) => {
    try {
      return { name: m.name || 'tool', content: JSON.parse(m.content) }
    } catch (_) {
      return { name: m.name || 'tool', content: m.content }
    }
  })
}

async function ollamaChat ({ model, messages, tools, url }) {
  if (typeof fetch !== 'function') {
    throw new Error('Global fetch is not available. Please use Node.js 18+.')
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model,
      stream: false,
      messages,
      tools
    })
  })

  if (!response.ok) {
    const text = await response.text()
    console.error(`Ollama error: ${response.status} ${text}`)
    throw new Error(`Ollama error: ${response.status} ${text}`)
  }

  return response.json()
}


async function ensureDatabase () {
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

async function startServer () {
  try {
    if (!fs.existsSync(dbPath)) {
      await ensureDatabase()
    }
    httpServer = app.listen(port, appListen)
  } catch (error) {
    console.error('Failed to start server:', error)
    process.exit(1)
  }
}

// Activar el servidor
startServer()

function appListen () {
  console.log(`Example app listening on: http://0.0.0.0:${port}`)
}

// Aturar el servidor correctament
process.on('SIGTERM', shutDown)
process.on('SIGINT', shutDown)
function shutDown () {
  console.log('Received kill signal, shutting down gracefully')
  if (httpServer) {
    httpServer.close()
  }
  process.exit(0)
}
