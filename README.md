# 🖥️ Conky HUD — DOSSIÊ KRAFT 1974 v3.3.1 (padrão atual)

> Modelo em uso: papel de arquivo, âmbar de válvula, zero neon, compacto.
> Troque via `~/.config/conky/scripts/theme-switch.sh [kraft|neon|paper|stealth|nord|sage]`.
> Instalação limpa em outra máquina: `git clone … && ./install.sh` (copia conf, PNGs, blocos, cluster, scripts, autostart).

# 🖥️ Conky HUD v3.1 — 3 temas + botões (histórico)

HUD para Conky 1.19.6 — otimizado para **1360x768, Zorin OS / GNOME 46, Intel Atom 2 cores**.

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
mkdir -p ~/.config/conky/scripts ~/.config/conky/themes ~/.cache/conky
cp conky.conf ~/.config/conky/conky.conf
cp themes/*.conf ~/.config/conky/themes/
cp scripts/* ~/.config/conky/scripts/
chmod +x ~/.config/conky/scripts/*.sh ~/.config/conky/scripts/*.py
~/.config/conky/scripts/start-hud.sh
```

## 🎨 Temas (botõezinhos abaixo do HUD)

Mini-bar GTK com 3 botões (`Neon`/`Paper`/`Stealth`), fixa em `top_right` abaixo do HUD.
Troca manual: `~/.config/conky/scripts/theme-switch.sh [neon|paper|stealth]`

| Tema | Para | Base | Destaque | Ícones |
|---|---|---|---|---|
| **Neon** (padrão) | Wallpaper escuro | `#E6EDF3` | cyan `#00E5FF` + magenta `#FF4DF2` | neon 󰌘 󰍛 󰘚 󰋊 󰖩 |
| **Paper** | Wallpaper claro | `#1C2532` sobre claro | azul `#005EC4` + roxo `#7C2191` | mesmos, sem neon |
| **Stealth Dark** | Wallpaper quase-preto | gelo `#C2CAD4` | âmbar `#FFB000` (único) | táticos         |

## 📁 Estrutura

```
conky-hud/
├── conky.conf              # Tema padrão (neon, top_right 320px)
├── themes/
│   ├── neon.conf           # Neon p/ wallpaper escuro
│   ├── paper.conf          # Claro p/ wallpaper claro
│   └── stealth.conf        # Dark tático + ícones custom
├── scripts/
│   ├── btc.sh              # BTC CoinGecko + cache 120s + fallback
│   ├── start-conky.sh      # Wrapper: auto-detecta iface e gera /tmp/conky.generated.conf
│   ├── theme-switch.sh     # Troca neon|paper|stealth + recarrega
│   ├── theme-bar.py        # Mini-bar GTK 3 botões (320x36, top_right)
│   └── start-hud.sh        # Sobe conky + theme-bar
├── autostart/
│   └── conky.desktop       # Autostart GNOME (usa start-hud.sh)
├── install.sh              # Instalador
└── docs/                   # Plano de entrega, benchmarks
```

## 🎨 Paleta Neon (padrão)

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
