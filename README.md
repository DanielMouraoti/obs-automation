# OBS Automation (Linux) — obs_start.sh

Script em Bash para iniciar o **OBS Studio** no Linux escolhendo (ou informando via parâmetros) **Perfil**, **Coleção de Cenas** e **Cena**, com opção de **reiniciar/encerrar** o OBS se já estiver em execução.

## Conteúdo do repositório

- `script/obs_start.sh` — script principal
- `linux/live.png` — imagem/ícone (opcional)

## Requisitos

- Linux + Bash
- OBS Studio instalado e acessível pelo comando `obs`
- (Opcional) Permissão de `sudo` para criar/alterar `/etc/profile.d/obs_start_path.sh` (caso o PATH precise ser ajustado)

## Instalação

```bash
git clone git@github.com:DanielMouraoti/obs-automation.git
cd obs-automation
chmod +x script/obs_start.sh
