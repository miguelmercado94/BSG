/**
 * UUID v4. En HTTP sobre el ALB (origen no seguro distinto de localhost)
 * `crypto.randomUUID` suele no existir; usamos `getRandomValues` como respaldo.
 */
export function randomUuid(): string {
  const c = globalThis.crypto;
  if (c !== undefined && typeof c.randomUUID === "function") {
    return c.randomUUID();
  }
  if (c !== undefined && typeof c.getRandomValues === "function") {
    const b = new Uint8Array(16);
    c.getRandomValues(b);
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    const h = [...b].map((x) => x.toString(16).padStart(2, "0")).join("");
    return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20)}`;
  }
  return `fb-${Date.now()}-${Math.random().toString(36).slice(2, 11)}`;
}
