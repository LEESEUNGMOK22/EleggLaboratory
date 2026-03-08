export function applyPortraitRender(portraitEl, faceEl, stateEl, visual) {
  if (!portraitEl || !faceEl) return;

  portraitEl.classList.remove(
    "emphasis-soft", "emphasis-strong",
    "frame-focus-soft", "frame-focus-strong", "frame-gold", "frame-blood", "frame-shadow",
    "overlay-rain", "overlay-shadow", "overlay-blood", "overlay-rose",
    "symbol-arcane", "symbol-divine",
    "expr-soft", "expr-guarded", "expr-grim"
  );

  const expr = visual.expression || "neutral_face";
  if (expr.includes("soft")) portraitEl.classList.add("expr-soft");
  if (expr.includes("guard") || expr.includes("watch")) portraitEl.classList.add("expr-guarded");
  if (expr.includes("grim") || expr.includes("pain")) portraitEl.classList.add("expr-grim");

  for (const ov of visual.overlays || []) {
    if (ov.includes("rain")) portraitEl.classList.add("overlay-rain");
    if (ov.includes("shadow") || ov.includes("whisper")) portraitEl.classList.add("overlay-shadow");
    if (ov.includes("blood")) portraitEl.classList.add("overlay-blood");
    if (ov.includes("rose")) portraitEl.classList.add("overlay-rose");
  }

  for (const s of visual.ambientSymbols || []) {
    if (s.includes("arcane")) portraitEl.classList.add("symbol-arcane");
    if (s.includes("divine") || s.includes("halo") || s.includes("gold")) portraitEl.classList.add("symbol-divine");
  }

  if ((visual.frameStyle || "").includes("gilded") || (visual.frameStyle || "").includes("victory") || (visual.lighting || "").includes("gold")) {
    portraitEl.classList.add("frame-gold");
  }
  if ((visual.frameStyle || "").includes("shadow") || (visual.lighting || "").includes("ashen")) {
    portraitEl.classList.add("frame-shadow");
  }

  faceEl.textContent = expressionLabel(expr);

  if (stateEl) {
    stateEl.innerHTML = "";
    (visual.tags || []).slice(0, 8).forEach((tag) => {
      const s = document.createElement("span");
      s.textContent = tag;
      stateEl.appendChild(s);
    });
  }
}

function expressionLabel(expr) {
  if (expr.includes("pain")) return "긴장";
  if (expr.includes("soft")) return "완화";
  if (expr.includes("watch") || expr.includes("guard")) return "경계";
  if (expr.includes("wavering")) return "흔들림";
  if (expr.includes("confident") || expr.includes("resolved")) return "결의";
  return "평정";
}
