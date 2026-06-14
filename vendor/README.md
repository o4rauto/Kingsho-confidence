# vendor/ — dependências vendorizadas (ZERO CDN em runtime)

Tudo aqui é **baixado e commitado** no repo. Nenhum arquivo é buscado por CDN em
tempo de execução — requisito do projeto (roda offline / vira APK e é
verificável no sandbox, onde a CDN é bloqueada). Os arquivos são carregados via
`<script type="importmap">` em `lab/models.html`:

```json
{ "imports": {
  "three": "../vendor/three.module.js",
  "three/addons/": "../vendor/addons/"
} }
```

## Three.js — r160 (MIT)

- **Origem:** pacote npm `three@0.160.0` (`npm pack three@0.160.0`).
- **Licença:** MIT — © 2010–2024 three.js authors. Ver
  <https://github.com/mrdoob/three.js/blob/r160/LICENSE>.
- **Arquivos:**
  - `three.module.js` — `build/three.module.js` do pacote.
  - `addons/` — subconjunto mínimo de `examples/jsm/` (estrutura de pastas
    preservada p/ os imports relativos funcionarem):
    - `loaders/GLTFLoader.js`
    - `utils/BufferGeometryUtils.js`
    - `postprocessing/{EffectComposer,RenderPass,ShaderPass,MaskPass,UnrealBloomPass,OutputPass,Pass}.js`
    - `shaders/{CopyShader,LuminosityHighPassShader,OutputShader}.js`
  - Fecho de dependências conferido: nenhum addon importa nada fora desta lista
    (só `three` via importmap + relativos internos).

## Modelo 3D — RobotExpressive.glb (CC0)

- **Origem:** `examples/models/gltf/RobotExpressive/RobotExpressive.glb` do
  repositório three.js (r160).
- **Autoria/Licença:** modelo por **Tomás Laulhé** (<https://www.patreon.com/quaternius>),
  modificado por **Don McCurdy** — **CC0 1.0** (domínio público). Ver o índice de
  licenças do three.js (`examples/models/...` marcado como CC0).
- **Por que este:** é **animado** (tem clipes `Idle`, `Walking`, `Dance`, etc.),
  **low-poly** (combina com o feel do jogo) e **leve** (~456 KB). Usado como CC0
  *placeholder* só p/ provar o pipeline de render (toon + bloom + turntable).
  **Não** é arte final do jogo.

> ⚠️ É **placeholder de spike**. A arte definitiva do Bastion Rush é original
> (ver regra de originalidade no `CLAUDE.md`). Modelos CC0 (Quaternius/KayKit/
> Kenney) podem ser usados como base, sempre conferindo a licença.
