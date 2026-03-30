import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";
import { getUserId, setUserId } from "../api/client";

export function UserPage() {
  const navigate = useNavigate();
  const [user, setUser] = useState(getUserId());
  const [error, setError] = useState<string | null>(null);

  function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (!user.trim()) {
      setError("Indica un identificador de usuario.");
      return;
    }
    setUserId(user.trim());
    navigate("/repo-type");
  }

  return (
    <div className="page connect-page">
      <header className="page__header">
        <h1>DocViz</h1>
        <p className="muted">Identifica tu sesión para continuar.</p>
      </header>

      <form className="card" onSubmit={onSubmit}>
        <label className="field">
          <span>Usuario</span>
          <input
            value={user}
            onChange={(e) => setUser(e.target.value)}
            placeholder="ej. miguel01"
            autoComplete="username"
            autoFocus
          />
        </label>
        {error && <p className="error">{error}</p>}
        <button type="submit" className="btn primary">
          Continuar
        </button>
      </form>
    </div>
  );
}
