import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import "../style/Me.css";

function Me() {
  const [user, setUser] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const res = await fetch("http://localhost:8000/auth/me/get", {
          method: "GET",
          credentials: "include",
        });

        if (!res.ok) {
          throw new Error("유저 정보 불러오기 실패");
        }

        const data = await res.json();
        setUser(data);
      } catch (err) {
        console.error("프로필 로딩 실패:", err);
        navigate("/auth");
      }
    };

    fetchProfile();
  }, []);

  const handleDeleteUser = async () => {
    if (!window.confirm("정말 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.")) {
      return;
    }

    try {
      const res = await fetch("http://localhost:8000/auth/me/delete", {
        method: "DELETE",
        credentials: "include", // 쿠키 자동 포함
      });

      if (!res.ok) {
        const error = await res.json();
        throw new Error(error.detail || "삭제 실패");
      }

      alert("계정이 삭제되었습니다.");
      navigate("/"); // 홈이나 로그인 페이지로 리디렉션
    } catch (err) {
      console.error("삭제 실패:", err);
      alert("❌ 계정 삭제 중 오류 발생");
    }
  };

  if (!user) {
    return <p>로딩 중...</p>;
  }

  return (
    <div>
      {!user.subscription || user.subscription.name === "없음" ? (
        <div className="subscribe-prompt">
          <p>
            아직 가입이 안되어 있군요... Moodly의 영화, 시리즈와 서비스를 단 <strong>7000₩</strong>에 누리세요!
          </p>
          <button onClick={() => navigate("/Sub")}>구독하러 가기</button>
        </div>
      ) : null}

      <div className="page-container">
        <h1>My Page</h1>
        <p><strong>ID:</strong> {user.id}</p>
        <p><strong>Nickname:</strong> {user.nickname}</p>
        <p><strong>Language:</strong> {user.language || "미지정"}</p>
        <p><strong>Subscription:</strong> {user.subscription.name}</p>
        <p><strong>Expires At:</strong> {user.subscription.expires_at || "-"}</p>

        <button
          onClick={handleDeleteUser}
          style={{ marginTop: "20px", background: "red", color: "white", padding: "10px", borderRadius: "5px" }}
        >
          🔥 계정 삭제하기
        </button>
      </div>
    </div>
  );
}

export default Me;