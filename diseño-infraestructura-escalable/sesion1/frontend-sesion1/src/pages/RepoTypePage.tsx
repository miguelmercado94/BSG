import { Navigate } from "react-router-dom";
import { getDocVizRole, ROLE_SUPPORT } from "../api/client";

/** Entrada heredada: redirige al hub según rol (admin → células; soporte → elección de célula). */
export function RepoTypePage() {
  return <Navigate to={getDocVizRole() === ROLE_SUPPORT ? "/support/cells" : "/admin/cells"} replace />;
}
