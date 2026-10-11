# Coordenação entre as duas sessões do Claude

Duas sessões trabalham na branch `claude/bastion-rush-overhaul-oejz56`:

- **LOCAL** — roda no PC do desenvolvedor (Kali). Vantagem: baixa as imagens do
  Canva em resolução cheia, roda o Godot (headless + print com display), e importa
  as artes de verdade pro jogo.
- **CLOUD** — roda na nuvem (claude.ai). Vantagem: ... (a sessão CLOUD preenche).

## Regra de ouro
Nunca as duas mexem na branch ao mesmo tempo. Antes de editar:
1. `git pull origin claude/bastion-rush-overhaul-oejz56`
2. Leia este arquivo.
3. Se a outra sessão tem um **LOCK** ativo na mesma área, espere (ou pegue outra área).
4. Declare seu LOCK aqui, commite SÓ este arquivo, dê push, aí comece a trabalhar.
5. Ao terminar o lote, faça push do trabalho e libere o LOCK (mova pra "Concluído").

Sempre que push der conflito neste arquivo: `git pull --no-rebase`, junte as duas
seções à mão (mantenha as duas), e push de novo.

---

## LOCK ativo
*(quem está editando o quê agora)*

- **[LOCAL] 🔒 ATIVO (desde 2026-10-11)** — fechando o **Reino 1 (Portão Partido)**:
  redesenho no estilo padrão + animações de `warden, troop_militia, troop_bowmen,
  wisp, husk, ravager, the_maw`. Arquivos sob lock (NÃO mexer, CLOUD):
  `pipeline/canva_art.json`, `godot/assets/art/portraits/{warden,husk,ravager,wisp,
  troop_militia,troop_bowmen,the_maw}.png`, `godot/assets/art/anims/{esses ids}/`.
  Motivo de ser minha faixa: só a sessão LOCAL baixa Canva em alta resolução e roda
  o Godot. CLOUD: fique à vontade para pegar outra fase/reino; declare sua área abaixo.

- **[CLOUD]** — _(preencha: o que está fazendo, quais arquivos/pastas)_

## Concluído
*(histórico curto do que cada sessão já entregou e deu push)*

---

## Mural (recados livres)
- **[LOCAL] 2026-10-11:** Criei este arquivo. Ambiente pronto aqui (clone, Godot 4.3,
  Pillow, conector Canva). Estou **parado** aguardando: (a) a CLOUD declarar a área
  dela e (b) o desenvolvedor confirmar que é minha vez de pegar o Reino 1.
