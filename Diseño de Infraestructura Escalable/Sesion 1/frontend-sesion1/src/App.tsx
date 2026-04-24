import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthenticatedLayout } from "./layouts/AuthenticatedLayout";
import { UserPage } from "./pages/UserPage";
import { RepoTypePage } from "./pages/RepoTypePage";
import { ConnectRepoPage } from "./pages/ConnectRepoPage";
import { WorkspacePage } from "./pages/WorkspacePage";
import { TaskNotebookPage } from "./pages/TaskNotebookPage";
import { AdminCellsListPage } from "./pages/AdminCellsListPage";
import { AdminCellEditorPage } from "./pages/AdminCellEditorPage";
import { SupportCellsPage } from "./pages/SupportCellsPage";
import { SupportCellTasksPage } from "./pages/SupportCellTasksPage";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<UserPage />} />
        <Route element={<AuthenticatedLayout />}>
          <Route path="/repo-type" element={<RepoTypePage />} />
          <Route path="/connect" element={<ConnectRepoPage />} />
          <Route path="/tasks" element={<TaskNotebookPage />} />
          <Route path="/admin/cells" element={<AdminCellsListPage />} />
          <Route path="/admin/cells/new" element={<AdminCellEditorPage />} />
          <Route path="/admin/cells/:cellId/edit" element={<AdminCellEditorPage />} />
          <Route path="/support/cells" element={<SupportCellsPage />} />
          <Route path="/support/cells/:cellId/tasks" element={<SupportCellTasksPage />} />
          <Route path="/app" element={<WorkspacePage />} />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
