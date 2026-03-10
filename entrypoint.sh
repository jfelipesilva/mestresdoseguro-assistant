#!/bin/sh
set -e

CONFIG="/root/.openclaw/openclaw.json"
GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-mestresdoseguro2026}"

# Inicializar config a partir do seed apenas se nao existir ou estiver vazio
if [ ! -s "$CONFIG" ]; then
  echo "[entrypoint] Config nao encontrado, inicializando a partir do seed..."
  cp /app/openclaw.json.seed "$CONFIG"
fi

# Configurar gateway para modo headless
openclaw config set gateway.mode local 2>/dev/null || true
openclaw config set gateway.port 18790 2>/dev/null || true

# Configurar auth profiles para agentes
python3 -c "
import json, os

CONFIG = '$CONFIG'
TOKEN = os.environ.get('ANTHROPIC_API_KEY', '')

if not TOKEN:
    print('AVISO: ANTHROPIC_API_KEY nao definida no .env')

# Config: Control UI origins + remote token
with open(CONFIG) as f:
    data = json.load(f)
gw = data.setdefault('gateway', {})
cui = gw.setdefault('controlUi', {})
cui['allowedOrigins'] = ['http://localhost:9090', 'http://localhost:18790', 'http://127.0.0.1:9090', 'http://127.0.0.1:18790']
gw.setdefault('remote', {})['token'] = '$GATEWAY_TOKEN'
with open(CONFIG, 'w') as f:
    json.dump(data, f, indent=2)

# Auth profiles: setup-token para main
profile = {
    'profiles': {
        'anthropic:setup-token': {
            'type': 'token',
            'provider': 'anthropic',
            'token': TOKEN
        }
    },
    'order': ['anthropic:setup-token']
}

for agent in ['main']:
    d = f'/root/.openclaw/agents/{agent}/agent'
    os.makedirs(d, exist_ok=True)
    with open(f'{d}/auth-profiles.json', 'w') as f:
        json.dump(profile, f, indent=2)

os.makedirs('/root/.openclaw/credentials', exist_ok=True)
with open('/root/.openclaw/credentials/auth-profiles.json', 'w') as f:
    json.dump(profile, f, indent=2)

print('Config + auth profiles OK')
"

# Aplicar correcoes automaticas do doctor
openclaw doctor --fix 2>/dev/null || true

# Iniciar gateway em foreground
exec openclaw gateway run --bind lan --auth token --token "$GATEWAY_TOKEN" --port 18790
