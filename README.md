# 🖥️ Conky Cyberpunk HUD v3.0

HUD neon para Conky 1.19.6 — otimizado para **1360x768, Zorin OS / GNOME 46, Intel Atom 2 cores**.

![stack](https://img.shields.io/badge/conky-1.19.6-00E5FF) ![font](https://img.shields.io/badge/font-Hack_Nerd_Font-FF4DF2) ![os](https://img.shields.io/badge/os-Zorin_GNOME46-3DF083)

## ✨ O que exibe

- 🕒 Relógio `HH:MM:SS` + data pt-BR
- 💻 SYSTEM: kernel, uptime, load avg
- 🔥 CPU Atom 2 cores + temp `coretemp` (hwmon) + barras
- 🧠 RAM 7.6GB + SWAP 11GB
- 💾 DISK `/` + `/home` com barras
- 📡 REDE WiFi USB (auto-detecção de interface) + IP, down/up, graphs
- 🔝 TOP 3 CPU + TOP 3 MEM
- ₿ BITCOIN via CoinGecko com cache + fallback

## 🚀 Instalação

```bash
git clone https://github.com/Regimarcilio/conky-hud.git ~/PROJETOS/conky-hud
cd ~/PROJETOS/conky-hud
./install.sh
```

Ou manual:

```bash
mkdir -p ~/.config/conky/scripts ~/.cache/conky
cp conky.conf ~/.config/conky/conky.conf
cp scripts/* ~/.config/conky/scripts/
chmod +x ~/.config/conky/scripts/*.sh
~/.config/conky/scripts/start-conky.sh
```

## 📁 Estrutura

```
conky-hud/
├── conky.conf              # HUD principal (top_right 320px)
├── scripts/
│   ├── btc.sh              # BTC CoinGecko + cache 120s + fallback
│   └── start-conky.sh      # Wrapper: auto-detecta iface e gera /tmp/conky.generated.conf
├── autostart/
│   └── conky.desktop       # Autostart GNOME (usa start-conky.sh)
├── install.sh              # Instalador
└── docs/                   # Plano de entrega, benchmarks
```

## 🎨 Paleta

| Uso | Hex |
|---|---|
| Texto base | `#E6EDF3` |
| Secundário | `#8B949E` |
| Cyan rede/header | `#00E5FF` |
| Magenta títulos | `#FF4DF2` |
| Verde ok | `#3DF083` |
| Amarelo BTC/data | `#FFD60A` |
| Laranja temp | `#FF9E3D` |
| Vermelho crítico | `#FF4760` |

## 🔧 Requisitos

- `conky-all`, `curl`, `lm-sensors`, fonte `Hack Nerd Font`
- Interface WiFi detectada via `ip route` (sem config fixa)

## 📝 Créditos

Gerado com squad Opencode: **planmaster + stylemaster + opsmaster + qamaster** (04/10/2026).
