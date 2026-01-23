const path = require('path')

// If calling MarIA models from local host, set up tunneling before:
// ssh -i $HOME/.ssh/id_rsa -p 20127 -L 11414:192.168.1.14:11434 apalaci8@ieticloudpro.ieti.cat
// ssh -i $HOME/.ssh/id_rsa -p 20127 -L 11424:192.168.1.24:11434 apalaci8@ieticloudpro.ieti.cat

const MODE_LOCAL_CALLS_OLLAMA = 0
const MODE_LOCAL_CALLS_MARIA = 1
const MODE_PROXMOX_CALLS_MARIA = 2

const mode = MODE_LOCAL_CALLS_OLLAMA

const dataDir = path.join(__dirname, 'data')
const dbPath = process.env.SQLITE_PATH || path.join(dataDir, 'planets.sqlite')
const jsonPath = path.join(__dirname, 'data', 'planets.json')

const localOllama = 'http://localhost:11434/api/chat'
const maria14local = 'http://localhost:11414/api/chat'
const maria24local = 'http://localhost:11424/api/chat'
const maria14proxmox = 'http://192.168.1.14:11434/api/chat'
const maria24proxmox = 'http://192.168.1.24:11434/api/chat'

const model_Granite3b = 'granite4:3b'
const model_Granite8b = 'granite3.3:8b'
const model_Qwen8b = 'qwen3:8b'
// const model_Qwen3b    = 'qwen2.5:3b'

let primaryModelAUrl = localOllama
let primaryModelBUrl = localOllama
let judgeModelUrl = localOllama
let tiebreakerModelUrl = localOllama
let jsonRepairModelUrl = localOllama

let primaryModelA = model_Granite3b
let primaryModelB = model_Granite3b
let judgeModel = model_Granite3b
let tiebreakerModel = model_Granite3b
let jsonRepairModel = model_Granite3b

if (mode !== MODE_LOCAL_CALLS_OLLAMA) {
  primaryModelA = model_Granite3b
  primaryModelB = model_Qwen8b
  judgeModel = model_Granite8b
  tiebreakerModel = model_Granite3b
  jsonRepairModel = model_Granite3b

  if (mode === MODE_LOCAL_CALLS_MARIA) {
    primaryModelAUrl = maria14local
    primaryModelBUrl = maria24local
    judgeModelUrl = maria14local
    tiebreakerModelUrl = maria24local
    jsonRepairModelUrl = maria24local
  } else if (mode === MODE_PROXMOX_CALLS_MARIA) {
    primaryModelAUrl = maria14proxmox
    primaryModelBUrl = maria24proxmox
    judgeModelUrl = maria14proxmox
    tiebreakerModelUrl = maria24proxmox
    jsonRepairModelUrl = maria24proxmox
  }
}

const config = {
  port: 3000,
  MODE_LOCAL_CALLS_OLLAMA,
  MODE_LOCAL_CALLS_MARIA,
  MODE_PROXMOX_CALLS_MARIA,
  mode,
  dataDir,
  dbPath,
  jsonPath,
  localOllama,
  maria14local,
  maria24local,
  maria14proxmox,
  maria24proxmox,
  model_Granite3b,
  model_Granite8b,
  model_Qwen8b,
  primaryModelAUrl,
  primaryModelBUrl,
  judgeModelUrl,
  tiebreakerModelUrl,
  jsonRepairModelUrl,
  primaryModelA,
  primaryModelB,
  judgeModel,
  tiebreakerModel,
  jsonRepairModel,
  HISTORY_LIMIT: 15
}

module.exports = config
