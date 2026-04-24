import { Navigate } from "react-router-dom";
import { getDocVizRole, ROLE_SUPPORT } from "../api/client";

/** Antigua entrada “cuaderno”; el soporte va a `/support/cells`, el admin a gestión de células. */
export function TaskNotebookPage() {
  return <Navigate to={getDocVizRole() === ROLE_SUPPORT ? "/support/cells" : "/admin/cells"} replace />;
}
