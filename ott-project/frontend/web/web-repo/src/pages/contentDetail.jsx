import { useParams } from "react-router-dom";
import { useEffect, useState } from "react";

function ContentDetail() {
  const { id } = useParams();
  const [content, setContent] = useState(null);
  const apiUrl = import.meta.env.VITE_API_URL;

  useEffect(() => {
    fetch(`${apiUrl}/contents/${id}`)
      .then(res => res.json())
      .then(data => setContent(data))
      .catch(err => console.error("불러오기 실패:", err));
  }, [id]);

  const handleFavorite = async () => {
    try {
      const res = await fetch(`${apiUrl}/favorites/${id}`, {
        method: "POST",
        credentials: "include", // 쿠키 포함 (인증용)
        headers: {
          "Content-Type": "application/json"
        }
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.detail || "찜하기 실패");
      }

      alert("❤️ 찜 완료!");
    } catch (err) {
      console.error("찜 실패:", err);
      alert("❌ 에러 발생");
    }
  };

  if (!content) return <div>로딩 중...</div>;

  return (
    <div className="detail-page">
      <h1>{content.title}</h1>
      <p><strong>설명:</strong> {content.description}</p>
      <p><strong>카테고리:</strong> {content.category}</p>
      <p><strong>연도:</strong> {content.year}</p>

      <button className="like-button" onClick={handleFavorite}>
        ❤️ 찜하기
      </button>
    </div>
  );
}

export default ContentDetail;