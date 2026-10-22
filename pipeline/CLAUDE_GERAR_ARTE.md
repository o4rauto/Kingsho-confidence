# Gerar as artes com o SEU ChatGPT (de graça, sem API)

Funciona com a sua conta normal do ChatGPT (site chatgpt.com ou o app), sem
chave e sem crédito extra. Um assistente no terminal faz a parte chata.

## Uma vez só (no terminal do Kali)

```bash
cd ~/bastion-rush
git pull origin claude/bastion-rush-overhaul-oejz56
sudo apt install -y xclip python3-pil      # copiar o prompt sozinho + converter imagens
```

## Para gerar

1. Abra o ChatGPT no navegador, numa conversa nova.
2. No terminal:
   ```bash
   cd ~/bastion-rush
   python3 pipeline/tools/chatgpt_helper.py
   ```
3. Repita para cada imagem:
   - o terminal mostra **PROMPT COPIADO!**;
   - no ChatGPT, aperte **Ctrl+V** e **Enter**;
   - quando a imagem aparecer, clique em **baixar** (seta para baixo);
   - o terminal mostra **OK! salvo em ...** e já copia o próximo prompt.

Comandos úteis durante o processo:
- Digite `s` + Enter para pular uma imagem que ficou feia.
- Digite `q` + Enter para parar. Na próxima vez, ele continua de onde parou.
- Rode `python3 pipeline/tools/chatgpt_helper.py --list` para ver o que falta.

A ordem começa pelo que mais aparece no jogo: logo, fundo do menu, os 10 reinos,
os retratos e as bênçãos. Se o ChatGPT avisar que bateu o limite de imagens do
dia, pare com `q` e continue amanhã.

## Mandar para o GitHub (para eu ajustar o resto)

```bash
cd ~/bastion-rush
git add godot/assets/art
git commit -m "Arte do ChatGPT"
git push
```

Depois volte aqui e diga **"as artes estão no GitHub"**.

> Dá para pedir isso a um Claude Code rodando no seu PC (`claude` dentro da
> pasta): ele roda o assistente e faz o commit. Mas colar no ChatGPT e clicar
> em baixar continua sendo com você, porque o ChatGPT não deixa programas
> controlarem a conta pelo terminal.
