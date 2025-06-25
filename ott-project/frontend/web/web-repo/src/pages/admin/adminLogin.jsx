import { useState } from "react";
import { useNavigate } from "react-router-dom";


function AdminLogin() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();

    try {
      const response = await fetch("http://localhost:8000/admin/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        credentials: "include", // 쿠키 받기 위한 설정
        body: JSON.stringify({ email, password })
      });

      if (!response.ok) {
        throw new Error("운영자 권한 없거나 정보 불일치");
      }

      const data = await response.json();
      console.log("Admin token:", data.access_token); // 디버깅용, 나중엔 지워도 돼

      navigate("/admin/dashboard");
    } catch (err) {
      alert("로그인 실패: " + err.message);
    }
  };

  return (
    <div className="admin-login-container">
      <h2>Admin Login</h2>
      <form onSubmit={handleLogin}>
        <input
          type="email"
          placeholder="Admin Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
        <input
          type="password"
          placeholder="Admin Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
        <button type="submit">Enter</button>
      </form>
    </div>
  );
}

export default AdminLogin;