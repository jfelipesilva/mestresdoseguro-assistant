/**
 * Hook: historico-whatsapp
 *
 * Grava historico fiel das conversas WhatsApp em markdown.
 * Captura SOMENTE mensagens reais trocadas no WhatsApp —
 * sem pensamento de agentes, sem comunicacao inter-agentes.
 *
 * Eventos:
 *   message:received    → mensagem de texto do corretor
 *   message:transcribed → audio do corretor (transcricao real)
 *   message:sent         → resposta do assistente ao corretor
 */

import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";

// ---------------------------------------------------------------------------
// Tipos
// ---------------------------------------------------------------------------

interface Corretor {
  nome: string;
  telefone: string;
}

interface HookEvent {
  type: string;
  action: string;
  sessionKey: string;
  timestamp: Date;
  context: Record<string, any>;
}

// ---------------------------------------------------------------------------
// Constantes
// ---------------------------------------------------------------------------

const HISTORICO_BASE = path.join(os.homedir(), ".openclaw", "historico-conversas");

// Cache de corretores (recarrega a cada 5 minutos)
// TODO: implementar consulta ao banco assistente_cotacoes para resolver corretores
let corretoresCache: Corretor[] = [];
let corretoresCacheTime = 0;
const CACHE_TTL_MS = 5 * 60 * 1000;

// Dedup para mensagens recebidas
const processedReceived = new Map<string, number>();
const DEDUP_TTL_MS = 60_000;

// ---------------------------------------------------------------------------
// Verificacoes de sessao
// ---------------------------------------------------------------------------

function isSubagentSession(sessionKey: string): boolean {
  return sessionKey.includes(":subagent:");
}

// ---------------------------------------------------------------------------
// Utilidades
// ---------------------------------------------------------------------------

function slugify(texto: string): string {
  return texto
    .toLowerCase()
    .trim()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^\w\s-]/g, "")
    .replace(/[\s_]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
}

function normalizeTelefone(tel: string): string {
  return tel.replace(/[\s\-()]/g, "");
}

function isMediaPlaceholder(content: string): boolean {
  return content.startsWith("<media:") || content.startsWith("[media:") || content === "";
}

function buscarCorretor(telefone: string): Corretor | null {
  const normalizado = normalizeTelefone(telefone);

  for (const c of corretoresCache) {
    if (normalizeTelefone(c.telefone) === normalizado) {
      return c;
    }
  }

  const semPlus = normalizado.replace(/^\+/, "");
  for (const c of corretoresCache) {
    const cNorm = normalizeTelefone(c.telefone).replace(/^\+/, "");
    if (cNorm === semPlus || cNorm.endsWith(semPlus) || semPlus.endsWith(cNorm)) {
      return c;
    }
  }

  return null;
}

// ---------------------------------------------------------------------------
// Resolucao de caminho e escrita
// ---------------------------------------------------------------------------

interface InfoConversa {
  nome: string;
  telefone: string;
  pastaBase: string;
}

function resolverInfo(telefone: string, corretor: Corretor | null): InfoConversa {
  if (corretor) {
    const slugPessoa = slugify(corretor.nome);
    return {
      nome: corretor.nome,
      telefone: corretor.telefone,
      pastaBase: path.join(HISTORICO_BASE, slugPessoa, "conversas"),
    };
  }

  const telLimpo = normalizeTelefone(telefone).replace(/^\+/, "");
  return {
    nome: telefone,
    telefone,
    pastaBase: path.join(HISTORICO_BASE, "_desconhecidos", telLimpo, "conversas"),
  };
}

function criarCabecalho(info: InfoConversa, agora: Date): string {
  const meses = [
    "Janeiro", "Fevereiro", "Marco", "Abril", "Maio", "Junho",
    "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro",
  ];
  const mesNome = meses[agora.getMonth()];
  const ano = agora.getFullYear();

  return (
    `# Conversa com ${info.nome} — ${mesNome}/${ano}\n` +
    `**Corretor:** ${info.nome} | **WhatsApp:** ${info.telefone}\n\n` +
    `---\n\n`
  );
}

async function appendMensagem(
  info: InfoConversa,
  remetente: string,
  mensagem: string,
  agora: Date,
): Promise<void> {
  await fs.mkdir(info.pastaBase, { recursive: true });

  const mesAno = `${agora.getFullYear()}-${String(agora.getMonth() + 1).padStart(2, "0")}`;
  const arquivo = path.join(info.pastaBase, `${mesAno}.md`);

  const timestamp = [
    String(agora.getHours()).padStart(2, "0"),
    String(agora.getMinutes()).padStart(2, "0"),
    String(agora.getSeconds()).padStart(2, "0"),
  ].join(":");

  const diaFormatado = [
    String(agora.getDate()).padStart(2, "0"),
    String(agora.getMonth() + 1).padStart(2, "0"),
    String(agora.getFullYear()),
  ].join("/");

  let conteudoExistente = "";
  try {
    conteudoExistente = await fs.readFile(arquivo, "utf-8");
  } catch {
    await fs.writeFile(arquivo, criarCabecalho(info, agora), "utf-8");
    conteudoExistente = await fs.readFile(arquivo, "utf-8");
  }

  const marcadorDia = `## ${diaFormatado}`;
  let bloco = "";

  if (!conteudoExistente.includes(marcadorDia)) {
    bloco += `\n${marcadorDia}\n\n`;
  }

  bloco += `**[${timestamp}] ${remetente}:**\n${mensagem}\n\n`;

  await fs.appendFile(arquivo, bloco, "utf-8");
}

// ---------------------------------------------------------------------------
// Dedup helpers
// ---------------------------------------------------------------------------

function dedupKey(telefone: string, messageId?: string): string {
  return `${normalizeTelefone(telefone)}:${messageId || ""}`;
}

function isDuplicate(key: string): boolean {
  const ts = processedReceived.get(key);
  if (ts && Date.now() - ts < DEDUP_TTL_MS) return true;
  return false;
}

function markProcessed(key: string): void {
  processedReceived.set(key, Date.now());
  if (processedReceived.size > 500) {
    const now = Date.now();
    for (const [k, v] of processedReceived) {
      if (now - v > DEDUP_TTL_MS) processedReceived.delete(k);
    }
  }
}

// ---------------------------------------------------------------------------
// Handler principal
// ---------------------------------------------------------------------------

const historicoWhatsapp = async (event: HookEvent): Promise<void> => {
  if (event.type !== "message") return;

  const ctx = event.context;
  const channel = ctx.channelId;

  if (channel !== "whatsapp") return;

  if (isSubagentSession(event.sessionKey)) return;

  const agora = event.timestamp instanceof Date ? event.timestamp : new Date();

  try {
    if (event.action === "received") {
      const telefone = ctx.from;
      if (!telefone) return;

      const content = ctx.content || ctx.body || "";
      if (isMediaPlaceholder(content)) return;

      const key = dedupKey(telefone, ctx.messageId);
      if (isDuplicate(key)) return;
      markProcessed(key);

      const corretor = buscarCorretor(telefone);
      const info = resolverInfo(telefone, corretor);

      await appendMensagem(info, info.nome, content, agora);

    } else if (event.action === "transcribed") {
      const telefone = ctx.from;
      if (!telefone) return;

      const transcript = ctx.transcript || ctx.bodyForAgent || ctx.body || "";
      if (!transcript || isMediaPlaceholder(transcript)) return;

      const key = dedupKey(telefone, ctx.messageId);
      if (isDuplicate(key)) return;
      markProcessed(key);

      const corretor = buscarCorretor(telefone);
      const info = resolverInfo(telefone, corretor);

      await appendMensagem(info, info.nome, `[Audio] ${transcript}`, agora);

    } else if (event.action === "sent") {
      const telefone = ctx.to;
      if (!telefone) return;

      const content = ctx.content;
      if (!content || ctx.success === false) return;

      const corretor = buscarCorretor(telefone);
      const info = resolverInfo(telefone, corretor);

      await appendMensagem(info, "Assistente", content, agora);
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`[historico-whatsapp] Erro: ${msg}`);
  }
};

export default historicoWhatsapp;
