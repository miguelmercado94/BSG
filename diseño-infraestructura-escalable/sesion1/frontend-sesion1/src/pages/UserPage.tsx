import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  applyAuthFromSecurityTokens,
  getDocVizRole,
  getUserId,
  loginSecurity,
  registerSecurity,
  ROLE_ADMINISTRATOR,
  ROLE_SUPPORT,
} from "../api/client";

type Mode = "login" | "register";
type RegisterRole = typeof ROLE_ADMINISTRATOR | typeof ROLE_SUPPORT;

export function UserPage() {
  const navigate = useNavigate();
  const [mode, setMode] = useState<Mode>("login");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const [loginUser, setLoginUser] = useState("");
  const [loginPassword, setLoginPassword] = useState("");

  const [regUsername, setRegUsername] = useState("");
  const [regEmail, setRegEmail] = useState("");
  const [regPassword, setRegPassword] = useState("");
  const [regPhone, setRegPhone] = useState("");
  const [regRole, setRegRole] = useState<RegisterRole>(ROLE_ADMINISTRATOR);

  const existing = getUserId().trim();

  function homeForRole(): string {
    return getDocVizRole() === ROLE_SUPPORT ? "/support/cells" : "/admin/cells";
  }

  async function onLogin(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const tokens = await loginSecurity({
        usernameOrEmail: loginUser,
        password: loginPassword,
      });
      applyAuthFromSecurityTokens(tokens);
      navigate(homeForRole());
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setLoading(false);
    }
  }

  async function onRegister(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const r = await registerSecurity({
        username: regUsername,
        email: regEmail,
        password: regPassword,
        phone: regPhone.trim() === "" ? undefined : regPhone,
        roleName: regRole,
      });
      applyAuthFromSecurityTokens({
        jwt: r.jwt,
        jwtRefresh: r.jwtRefresh,
        available: true,
        username: r.username,
      });
      navigate(homeForRole());
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="page connect-page">
      <header className="page__header">
        <h1>DocViz</h1>
        <p className="muted">
          Inicia sesión con el servicio de seguridad. El mismo nombre de usuario se envía a DocViz como{" "}
          <code className="muted">X-DocViz-User</code>.
        </p>
      </header>

      <div className="card" style={{ marginBottom: "1rem" }}>
        <div style={{ display: "flex", gap: "0.5rem", marginBottom: "1rem" }}>
          <button
            type="button"
            className={mode === "login" ? "btn primary" : "btn"}
            onClick={() => {
              setMode("login");
              setError(null);
            }}
          >
            Iniciar sesión
          </button>
          <button
            type="button"
            className={mode === "register" ? "btn primary" : "btn"}
            onClick={() => {
              setMode("register");
              setError(null);
            }}
          >
            Registrarse
          </button>
        </div>

        {mode === "login" ? (
          <form onSubmit={onLogin}>
            <label className="field">
              <span>Usuario o correo</span>
              <input
                value={loginUser}
                onChange={(ev) => setLoginUser(ev.target.value)}
                autoComplete="username"
                required
                autoFocus
              />
            </label>
            <label className="field">
              <span>Contraseña</span>
              <input
                type="password"
                value={loginPassword}
                onChange={(ev) => setLoginPassword(ev.target.value)}
                autoComplete="current-password"
                required
              />
            </label>
            {error && <p className="error">{error}</p>}
            <button type="submit" className="btn primary login-form-submit" disabled={loading}>
              {loading ? "Entrando…" : "Continuar"}
            </button>
          </form>
        ) : (
          <form onSubmit={onRegister}>
            <label className="field">
              <span>Usuario</span>
              <input
                value={regUsername}
                onChange={(ev) => setRegUsername(ev.target.value)}
                autoComplete="username"
                required
                autoFocus
              />
            </label>
            <label className="field">
              <span>Correo</span>
              <input
                type="email"
                value={regEmail}
                onChange={(ev) => setRegEmail(ev.target.value)}
                autoComplete="email"
                required
              />
            </label>
            <label className="field">
              <span>Teléfono (opcional)</span>
              <input
                value={regPhone}
                onChange={(ev) => setRegPhone(ev.target.value)}
                autoComplete="tel"
              />
            </label>
            <label className="field">
              <span>Contraseña</span>
              <input
                type="password"
                value={regPassword}
                onChange={(ev) => setRegPassword(ev.target.value)}
                autoComplete="new-password"
                required
              />
            </label>
            <fieldset className="field register-role-fieldset">
              <span className="register-role-label">Rol</span>
              <div className="register-role-options" role="radiogroup" aria-label="Rol en DocViz">
                <label className="register-role-option">
                  <input
                    type="radio"
                    name="reg-role"
                    checked={regRole === ROLE_ADMINISTRATOR}
                    onChange={() => setRegRole(ROLE_ADMINISTRATOR)}
                  />
                  <span>Administrador</span>
                </label>
                <label className="register-role-option">
                  <input
                    type="radio"
                    name="reg-role"
                    checked={regRole === ROLE_SUPPORT}
                    onChange={() => setRegRole(ROLE_SUPPORT)}
                  />
                  <span>Soporte</span>
                </label>
              </div>
            </fieldset>
            {error && <p className="error">{error}</p>}
            <button type="submit" className="btn primary register-form-submit" disabled={loading}>
              {loading ? "Creando cuenta…" : "Crear cuenta y entrar"}
            </button>
          </form>
        )}
      </div>

      {existing ? (
        <p className="muted">
          Sesión local: <strong>{existing}</strong>. Al iniciar sesión de nuevo se sustituye.
        </p>
      ) : null}
    </div>
  );
}
