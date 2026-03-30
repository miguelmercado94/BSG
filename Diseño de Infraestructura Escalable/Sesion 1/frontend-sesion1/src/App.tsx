import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { UserPage } from "./pages/UserPage";
import { RepoTypePage } from "./pages/RepoTypePage";
import { ConnectRepoPage } from "./pages/ConnectRepoPage";
import { WorkspacePage } from "./pages/WorkspacePage";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<UserPage />} />
        <Route path="/repo-type" element={<RepoTypePage />} />
        <Route path="/connect" element={<ConnectRepoPage />} />
        <Route path="/app" element={<WorkspacePage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
