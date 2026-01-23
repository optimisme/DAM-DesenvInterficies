function createOllamaAgent ({
  config,
  tools,
  db,
  buildSystemPrompt,
  getJsonRepairSystemPrompt,
  getJudgeEquivalenceSystemPrompt,
  getJudgeTiebreakerSystemPrompt
}) {
  const {
    HISTORY_LIMIT,
    primaryModelA,
    primaryModelB,
    judgeModel,
    tiebreakerModel,
    jsonRepairModel,
    primaryModelAUrl,
    primaryModelBUrl,
    judgeModelUrl,
    tiebreakerModelUrl,
    jsonRepairModelUrl
  } = config
  const { dbQuery, getDbSchemaText } = db
  const sessions = new Map()

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
    const system = getJsonRepairSystemPrompt()

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
    const toolMsgs = messages.filter((m) => m?.role === 'tool' && typeof m.content === 'string')
    const tail = toolMsgs.slice(Math.max(0, toolMsgs.length - maxToolMessages))
    return tail.map((m) => {
      try {
        return { name: m.name || 'tool', content: JSON.parse(m.content) }
      } catch (_) {
        return { name: m.name || 'tool', content: m.content }
      }
    })
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
          result = await dbQuery({ query: args.query, config })
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
    const system = getJudgeEquivalenceSystemPrompt()

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
    const system = getJudgeTiebreakerSystemPrompt()

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

  async function handleChat (req, res) {
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
      const schemaText = await getDbSchemaText(config)
      const systemPrompt = buildSystemPrompt({ schemaText })

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

  return { handleChat }
}

module.exports = {
  createOllamaAgent
}
