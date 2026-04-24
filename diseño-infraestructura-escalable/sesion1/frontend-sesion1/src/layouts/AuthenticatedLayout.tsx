import { Navigate, Outlet, useLocation } from "react-router-dom";
import { getUserId } from "../api/client";
import { SessionRailPanel } from "../components/SessionRailPanel";

/**
 * Rutas tras iniciar sesión: panel lateral + contenido. El workspace ({@code /app}) ya incluye su propia barra de sesión.
 */
export function AuthenticatedLayout() {
  const location = useLocation();
  const user = getUserId().trim();
  if (!user) {
    return <Navigate to="/" replace />;
  }
  if (location.pathname === "/app") {
    return <Outlet />;
  }
  return (
    <div className="app-shell">
      <SessionRailPanel />
      <div className="app-shell__main">
        <Outlet />
      </div>
    </div>
  );
}
