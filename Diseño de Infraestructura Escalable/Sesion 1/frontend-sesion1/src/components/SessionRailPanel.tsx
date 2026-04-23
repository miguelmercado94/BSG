import { useCallback, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  getDocVizRole,
  getUserId,
  logoutSession,
  ROLE_ADMINISTRATOR,
  ROLE_SUPPORT,
} from "../api/client";
import { clearGitConnectRequest } from "../lib/docvizGitSession";

function roleLabel(): string {
  const r = getDocVizRole();
  if (r === ROLE_SUPPORT) return "Soporte";
  if (r === ROLE_ADMINISTRATOR) return "Administrador";
  return r || "—";
}

/**
 * Barra lateral izquierda colapsable: usuario DocViz y cierre de sesión.
 * Misma apariencia que en el workspace; estado abierto/cerrado en {@code localStorage docviz_session_panel_open}.
 */
export function SessionRailPanel() {
  const navigate = useNavigate();
  const [open, setOpen] = useState(() => {
    try {
      return localStorage.getItem("docviz_session_panel_open") !== "0";
    } catch {
      return true;
    }
  });
  const [logoutLoading, setLogoutLoading] = useState(false);
  const [logoutErr, setLogoutErr] = useState<string | null>(null);

  const persistOpen = useCallback((next: boolean) => {
    setOpen(next);
    try {
      localStorage.setItem("docviz_session_panel_open", next ? "1" : "0");
    } catch {
      /* ignore */
    }
  }, []);

  async function onLogout() {
    setLogoutErr(null);
    setLogoutLoading(true);
    try {
      await logoutSession();
      clearGitConnectRequest();
      navigate("/", { replace: true });
    } catch (e) {
      setLogoutErr(e instanceof Error ? e.message : String(e));
    } finally {
      setLogoutLoading(false);
    }
  }

  const user = getUserId().trim() || "—";

  return (
    <aside
      className={
        "workspace__session-rail" +
        (open ? " workspace__session-rail--open" : " workspace__session-rail--collapsed")
      }
      aria-label="Sesión"
    >
      <div
        className={
          "workspace__session-rail-toolbar" + (!open ? " workspace__session-rail-toolbar--collapsed" : "")
        }
      >
        <button
          type="button"
          className="workspace__session-rail-toggle"
          onClick={() => persistOpen(!open)}
          aria-expanded={open}
          title={open ? "Ocultar panel lateral" : "Mostrar panel lateral"}
        >
          {open ? (
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>
              <path
                d="M9 5H6.5A1.5 1.5 0 0 0 5 6.5v11A1.5 1.5 0 0 0 6.5 19H9"
                stroke="currentColor"
                strokeWidth="1.75"
                strokeLinecap="round"
              />
              <path
                d="M14 10l-3 2 3 2M11 12h8"
                stroke="currentColor"
                strokeWidth="1.75"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          ) : (
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>
              <path
                d="M9 5H6.5A1.5 1.5 0 0 0 5 6.5v11A1.5 1.5 0 0 0 6.5 19H9"
                stroke="currentColor"
                strokeWidth="1.75"
                strokeLinecap="round"
              />
              <path
                d="M13 10l3 2-3 2M16 12H8"
                stroke="currentColor"
                strokeWidth="1.75"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          )}
        </button>
      </div>

      {open && (
        <div className="workspace__session-rail-body">
          <div className="workspace__session-rail-user session-rail-panel__identity">
            <span className="workspace__header-user">{user.toUpperCase()}</span>
            <span className="workspace__header-session-hint muted session-rail-panel__role">
              {roleLabel().toUpperCase()}
            </span>
          </div>
        </div>
      )}

      {open && (
        <footer className="workspace__session-rail-footer">
          {logoutErr && (
            <p className="error small workspace__session-rail-footer-err" role="alert">
              {logoutErr}
            </p>
          )}
          <button
            type="button"
            className="workspace__session-rail-logout-link"
            onClick={() => void onLogout()}
            disabled={logoutLoading}
            aria-busy={logoutLoading}
          >
            {logoutLoading ? "Cerrando…" : "CERRAR SESION"}
          </button>
        </footer>
      )}
    </aside>
  );
}
