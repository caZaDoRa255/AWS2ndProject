import { useParams } from "react-router-dom";
import { useEffect, useState } from "react";

function ContentDetail() {
  const { id } = useParams();
  const [content, setContent] = useState(null);

  useEffect(() => {
    fetch(`http://localhost:8000/contents/${id}`)
      .then(res => res.json())
      .then(data => setContent(data))
      .catch(err => console.error("불러오기 실패:", err));
  }, [id]);

  if (!content) return <div>로딩 중...</div>;

  return (
    <div className="detail-page">
      <h1>{content.title}</h1>
      <p><strong>설명:</strong> {content.description}</p>
      <p><strong>카테고리:</strong> {content.category}</p>
      <p><strong>연도:</strong> {content.year}</p>
      {/* 여기다 이미지, 버튼, 평점 등 추가 */}
      <button
          className="like-button"
          onClick={() => alert(`id ${content.id}번 찜함`)}
        >
          ❤️ 찜하기
        </button>
    </div>
  );
}

export default ContentDetail;
