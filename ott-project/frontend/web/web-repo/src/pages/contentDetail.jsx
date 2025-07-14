import { useParams, Link } from "react-router-dom";
import { useEffect, useState } from "react";
import axios from "axios";
import "../style/contentDetail.css";

function ContentDetail() {
  const { id } = useParams();
  const [content, setContent] = useState(null);
  const [comments, setComments] = useState([]);
  const [newComment, setNewComment] = useState("");
  const [videoUrl, setVideoUrl] = useState("");
  const apiUrl = import.meta.env.VITE_API_URL;

  useEffect(() => {
    // Fetch content details
    fetch(`${apiUrl}/contents/${id}`)
      .then((res) => res.json())
      .then((data) => setContent(data))
      .catch((err) => console.error("Content fetch failed:", err));

    // Fetch comments
    fetchComments();

    // Fetch video URL
    const fetchVideoUrl = async () => {
      try {
        const urlResponse = await fetch(`${apiUrl}/history/${id}/url`, {
          method: 'GET',
          credentials: "include"
        });
        if (!urlResponse.ok) throw new Error(`HTTP error! status: ${urlResponse.status}`);
        const urlData = await urlResponse.json();
        if (urlData.stream_url) {
          setVideoUrl(urlData.stream_url);
        } else {
          throw new Error("No stream_url in response data");
        }
      } catch (error) {
        console.error("Error fetching video URL:", error);
      }
    };

    fetchVideoUrl();
  }, [id, apiUrl]);

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
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
        },
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
    <div className="netflix-detail-page">
      <div
        className="hero-section"
        style={{
          backgroundImage: `url(${content.thumbnail_url || 'https://via.placeholder.com/1920x1080'})`,
        }}
      >
        <div className="hero-content-grid">
          <div className="hero-text">
            <h1 className="hero-title">{content.title}</h1>
            <p className="hero-description">{content.description}</p>
            <div className="hero-buttons">
              <Link to={`/stream/${id}`} className="play-button">
                재생
              </Link>
              <button className="like-button" onClick={handleFavorite}>
                ❤️ 찜하기
              </button>
            </div>
          </div>
          <div className="hero-video-container">
            {videoUrl ? (
              <video
                src={videoUrl}
                autoPlay
                muted
                loop
                preload="metadata"
                className="hero-video"
              >
                Your browser does not support the video tag.
              </video>
            ) : (
              <div className="video-placeholder">Loading video...</div>
            )}
          </div>
        </div>
      </div>

      <div className="content-info-section">
        <div className="content-meta">
          <span className="meta-tag">장르: {content.category}</span>
          <span className="meta-tag">연도: {content.year}</span>
        </div>
      </div>

      <section className="comments-section">
        <h2>Comments</h2>
        <div className="comment-list">
          {comments.length > 0 ? (
            comments.map((comment) => (
              <div
                key={comment.id}
                className={`comment-item ${
                  comment.subscription_id === 2
                    ? "premium"
                    : comment.subscription_id === 3
                    ? "vip"
                    : ""
                }`}
              >
                <p className="comment-author">{comment.nickname}</p>
                {comment.subscription_id === 1 && <p className="subscription-badge basic">Basic User</p>}
                {comment.subscription_id === 2 && <p className="subscription-badge standard">Standard User 🔥</p>}
                {comment.subscription_id === 3 && <p className="subscription-badge premium-badge">Premium User 💎</p>}
                <p className="comment-date">
                  {new Date(comment.date).toLocaleString()}
                </p>
                <p className="comment-text">{comment.comment}</p>
              </div>
            ))
          ) : (
            <p className="no-comments-message">
              아직 댓글이 없습니다. 첫 댓글을 남겨보세요!
            </p>
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
