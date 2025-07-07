import { useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import axios from "axios";
import "../style/contentDetail.css";

function ContentDetail() {
  const { id } = useParams();
  const [content, setContent] = useState(null);
  const [comments, setComments] = useState([]);
  const [newComment, setNewComment] = useState("");
  const apiUrl = import.meta.env.VITE_API_URL;

  useEffect(() => {
    fetch(`${apiUrl}/contents/${id}`)
      .then(res => res.json())
      .then(data => setContent(data))
      .catch(err => console.error("불러오기 실패:", err));

    fetchComments();
  }, [id]);

  const fetchComments = async () => {
    try {
      const res = await axios.get(`${apiUrl}/comments/content/${id}`, {
        withCredentials: true,
      });
      setComments(res.data);
    } catch (err) {
      console.error("댓글 불러오기 실패:", err);
    }
  };

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

  const handleCommentSubmit = async (e) => {
    e.preventDefault();
    if (!newComment.trim()) return;

    try {
      const subInfo = await axios.get(`${apiUrl}/subscribe/me`, {
        withCredentials: true,
      });
      const subscription_id = subInfo.data.id;

      const res = await axios.post(
        `${apiUrl}/comments/`,
        {
          comment: newComment,
          content_id: id,
          nickname: "바비",
          subscription_id,
        },
        { withCredentials: true, credentials: "include" }
      );

      if (!res.data) {
        throw new Error("댓글 추가 실패");
      }

      setNewComment("");
      fetchComments(); // Refresh comments
    } catch (err) {
      console.error("댓글 추가 실패:", err);
      alert("댓글 추가 실패: " + (err.response?.data?.detail || err.message));
    }
  };

  if (!content) return <div className="loading-text">로딩 중...</div>;

  return (
    <div className="detail-page">
      <h1>{content.title}</h1>
      <p><strong>설명:</strong> {content.description}</p>
      <p><strong>카테고리:</strong> {content.category}</p>
      <p><strong>연도:</strong> {content.year}</p>

      <button className="like-button" onClick={handleFavorite}>
        ❤️ 찜하기
      </button>

      <section className="comments-section">
        <h2>Comments</h2>
        <div className="comment-list">
          {comments.length > 0 ? (
            comments.map((comment) => (
              <div 
                key={comment.id} 
                className={`comment-item ${comment.subscription_id === 2 ? 'premium' : comment.subscription_id === 3 ? 'vip' : ''}`}
              >
                <p className="comment-author">{comment.nickname}</p>
                <p className="comment-date">{new Date(comment.date).toLocaleString()}</p>
                <p className="comment-text">{comment.comment}</p>
              </div>
            ))
          ) : (
            <p className="no-comments-message">아직 댓글이 없습니다. 첫 댓글을 남겨보세요!</p>
          )}
        </div>
        <form className="comment-form" onSubmit={handleCommentSubmit}>
          <textarea
            placeholder="댓글을 남겨주세요..."
            value={newComment}
            onChange={(e) => setNewComment(e.target.value)}
          ></textarea>
          <button type="submit">댓글 작성</button>
        </form>
      </section>
    </div>
  );
}

export default ContentDetail;
