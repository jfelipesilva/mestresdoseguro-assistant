---
name: historico-whatsapp
description: "Grava historico fiel das conversas WhatsApp em markdown (somente mensagens reais)"
metadata:
  {
    "openclaw":
      {
        "emoji": "📜",
        "events": ["message:received", "message:transcribed", "message:sent"],
      },
  }
---

# Historico WhatsApp Hook

Captura automaticamente todas as mensagens do WhatsApp no nivel do gateway e grava em arquivos markdown organizados por corretor/mes.

## O que faz

- **message:received / message:transcribed**: Grava mensagem do corretor (texto ou transcricao de audio)
- **message:sent**: Grava resposta do assistente

Somente mensagens do canal `whatsapp` sao processadas.

## Estrutura de pastas

```
historico-conversas/
  {nome-corretor-slug}/
    conversas/{YYYY-MM}.md
  _desconhecidos/
    {numero-telefone}/
      conversas/{YYYY-MM}.md
```

## Formato do markdown

```markdown
# Conversa com {Nome} — {Mes}/{Ano}
**Corretor:** {Nome} | **WhatsApp:** {Numero}

---

## {DD}/{MM}/{AAAA}

**[HH:MM:SS] {Nome}:**
{mensagem do corretor}

**[HH:MM:SS] Assistente:**
{resposta do assistente}
```

## Resolucao de contatos

Consulta o banco de dados `assistente_cotacoes` para mapear telefone → corretor.
Numeros nao cadastrados vao para `_desconhecidos/{telefone}/`.
