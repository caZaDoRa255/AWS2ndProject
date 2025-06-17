import { useEffect, useState } from "react";

function Me() {
  const [user, setUser] = useState(null);

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const res = await fetch("http://localhost:8000/auth/me?user_id=1");
        const data = await res.json();
        setUser(data);
      } catch (err) {
        console.error("프로필 로딩 실패:", err);
      }
    };

    fetchProfile();
  }, []);

  if (!user) return <div>Loading...</div>;

  return (
    <div className="page-container">
      <h1>My Page</h1>
      <p><strong>ID:</strong> {user.id}</p>
      <p><strong>Nickname:</strong> {user.nickname}</p>
      <p><strong>Language:</strong> {user.language}</p>
      <p><strong>Subscription:</strong> {user.subscription?.name}</p>
      <p><strong>Expires At:</strong> {user.subscription?.expires_at}</p>
    </div>
  );
}

export default Me;