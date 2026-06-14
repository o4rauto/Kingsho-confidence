// canvas-engine.js — MOTOR PRÓPRIO em Canvas 2D puro (sem Three/WebGL).
// Esquema novo: pega a ILUSTRAÇÃO da ficha e simula 3D no canvas —
//   1) recorta o personagem do fundo (flood-fill por HSL + maior componente);
//   2) gera um campo de ALTURA (distance-transform/inflate) → volume;
//   3) sombreia pixel a pixel (normal a partir da altura + luz Lambert + rim + AO),
//      mantendo a arte como cor. Dá "modelo 3D simulado" rodando no nosso canvas.
//
// API:  const p = await CanvasChar.process(imgURL, crop);
//       CanvasChar.shade(p, opts) -> ImageData   (recalcula com a luz atual)

export const CanvasChar = {
  // ── carrega a ficha, recorta a figura e calcula cor+altura ──
  async process(url, crop) {
    const img = new Image();
    img.src = url; await img.decode();
    const sc = crop.scale || 3, W = Math.round(crop.w * sc), H = Math.round(crop.h * sc);
    const cv = document.createElement('canvas'); cv.width = W; cv.height = H;
    const g = cv.getContext('2d', { willReadFrequently: true });
    g.imageSmoothingEnabled = true;
    g.drawImage(img, crop.x, crop.y, crop.w, crop.h, 0, 0, W, H);
    const id = g.getImageData(0, 0, W, H), d = id.data;

    // 1) remover fundo: neve/céu (sat baixa & lum média/alta) ou vinheta (lum muito baixa)
    const isBg = (i) => {
      const r = d[i]/255, gg = d[i+1]/255, bb = d[i+2]/255;
      const mx = Math.max(r,gg,bb), mn = Math.min(r,gg,bb), l = (mx+mn)/2;
      const s = mx === mn ? 0 : (mx-mn)/(1-Math.abs(2*l-1) || 1);
      return (s < 0.34 && l > 0.40) || (s < 0.30 && l < 0.16);
    };
    const vis = new Uint8Array(W*H), st = [];
    for (let x=0;x<W;x++){ st.push(x, x+(H-1)*W); }
    for (let y=0;y<H;y++){ st.push(y*W, y*W+W-1); }
    while (st.length) {
      const k = st.pop(); if (vis[k]) continue;
      const x = k%W, y = (k/W)|0; if (!isBg(k*4)) continue; vis[k] = 1;
      if (x+1<W) st.push(k+1); if (x>0) st.push(k-1); if (y+1<H) st.push(k+W); if (y>0) st.push(k-W);
    }
    const inside = new Uint8Array(W*H);
    for (let k=0;k<W*H;k++) inside[k] = vis[k] ? 0 : 1;

    // 2) manter só o maior componente conectado (tira detritos)
    { const lbl = new Int32Array(W*H); let best=0, bestSize=0, cur=0;
      for (let k0=0;k0<W*H;k0++) {
        if (inside[k0] && !lbl[k0]) {
          cur++; let size=0; const stk=[k0]; lbl[k0]=cur;
          while (stk.length) { const k=stk.pop(); size++; const x=k%W, y=(k/W)|0;
            if (x>0&&inside[k-1]&&!lbl[k-1]){lbl[k-1]=cur;stk.push(k-1);}
            if (x<W-1&&inside[k+1]&&!lbl[k+1]){lbl[k+1]=cur;stk.push(k+1);}
            if (y>0&&inside[k-W]&&!lbl[k-W]){lbl[k-W]=cur;stk.push(k-W);}
            if (y<H-1&&inside[k+W]&&!lbl[k+W]){lbl[k+W]=cur;stk.push(k+W);} }
          if (size>bestSize){bestSize=size;best=cur;}
        }
      }
      for (let k=0;k<W*H;k++) if (inside[k] && lbl[k]!==best) inside[k]=0;
    }

    // 3) altura por distance-transform (chamfer) + perfil de domo
    const INF=1e9, dist=new Float32Array(W*H);
    for (let k=0;k<W*H;k++) dist[k]=inside[k]?INF:0;
    const a=1,b=1.414;
    for (let y=0;y<H;y++) for (let x=0;x<W;x++){ const k=y*W+x; if(!inside[k])continue; let m=dist[k];
      if(x>0)m=Math.min(m,dist[k-1]+a); if(y>0)m=Math.min(m,dist[k-W]+a);
      if(x>0&&y>0)m=Math.min(m,dist[k-W-1]+b); if(x<W-1&&y>0)m=Math.min(m,dist[k-W+1]+b); dist[k]=m; }
    for (let y=H-1;y>=0;y--) for (let x=W-1;x>=0;x--){ const k=y*W+x; if(!inside[k])continue; let m=dist[k];
      if(x<W-1)m=Math.min(m,dist[k+1]+a); if(y<H-1)m=Math.min(m,dist[k+W]+a);
      if(x<W-1&&y<H-1)m=Math.min(m,dist[k+W+1]+b); if(x>0&&y<H-1)m=Math.min(m,dist[k+W-1]+b); dist[k]=m; }
    let mx=0; for (let k=0;k<W*H;k++) if(dist[k]<INF&&dist[k]>mx)mx=dist[k];
    const height=new Float32Array(W*H);
    for (let k=0;k<W*H;k++) height[k]= inside[k] ? Math.sqrt(Math.min(1, dist[k]/(mx*0.6))) : 0;

    // cor base (RGB) com alfa do recorte (erode 1px p/ tirar franja)
    const color=new Uint8ClampedArray(W*H*4);
    for (let k=0;k<W*H;k++){ color[k*4]=d[k*4]; color[k*4+1]=d[k*4+1]; color[k*4+2]=d[k*4+2]; color[k*4+3]=inside[k]?255:0; }
    for (let y=1;y<H-1;y++) for (let x=1;x<W-1;x++){ const k=y*W+x;
      if(inside[k] && (!inside[k-1]||!inside[k+1]||!inside[k-W]||!inside[k+W])) color[k*4+3]=130; }

    return { W, H, color, height, inside };
  },

  // ── sombreia pixel a pixel: normal(altura) · luz + rim + AO ──
  shade(p, opts={}) {
    const { W, H, color, height, inside } = p;
    const depth = opts.depth ?? 26;          // "relevo" em px virtuais
    const amb = opts.ambient ?? 0.42;        // luz ambiente
    const la = opts.lightAngle ?? -0.6;      // direção da luz (rad, no plano da tela)
    const lz = opts.lightZ ?? 0.7;
    const Lx0 = Math.cos(la), Ly0 = Math.sin(la);
    let Ln = Math.hypot(Lx0, Ly0, lz); const Lx=Lx0/Ln, Ly=Ly0/Ln, Lz=lz/Ln;
    const rimC = opts.rim ?? [110,150,255]; const rimK = opts.rimK ?? 0.5;
    const out = new ImageData(W, H), o = out.data;
    for (let y=0;y<H;y++) for (let x=0;x<W;x++){
      const k=y*W+x; if(!inside[k]){ o[k*4+3]=0; continue; }
      const hl = x>0?height[k-1]:height[k], hr = x<W-1?height[k+1]:height[k];
      const hu = y>0?height[k-W]:height[k], hd = y<H-1?height[k+W]:height[k];
      const nx = -(hr-hl)*depth, ny = -(hd-hu)*depth, nz = 1;
      const inv = 1/Math.hypot(nx,ny,nz); const Nx=nx*inv, Ny=ny*inv, Nz=nz*inv;
      let diff = Nx*Lx + Ny*Ly + Nz*Lz; if(diff<0)diff=0;
      const ao = 0.55 + 0.45*height[k];            // baixadas mais escuras
      const sh = (amb + (1-amb)*diff) * ao;
      const rim = Math.pow(1-Nz, 3) * rimK;
      o[k*4]   = Math.min(255, color[k*4]  *sh + rimC[0]*rim);
      o[k*4+1] = Math.min(255, color[k*4+1]*sh + rimC[1]*rim);
      o[k*4+2] = Math.min(255, color[k*4+2]*sh + rimC[2]*rim);
      o[k*4+3] = color[k*4+3];
    }
    return out;
  },
};
