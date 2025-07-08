import { useState } from "react";
import { useNavigate } from "react-router-dom";

const Dashboard = () => {
  // State for JSON content
  const [jsonInput, setJsonInput] = useState(`[]`);

  // State for subscription product
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [price, setPrice] = useState("");
  const [durationDays, setDurationDays] = useState("");

  // State for video download
  const [downloadVideoId, setDownloadVideoId] = useState("");
  const [youtubeUrl, setYoutubeUrl] = useState("");
  const [title, setTitle] = useState("");

  // State for video upload
  const [uploadVideoId, setUploadVideoId] = useState("");

  const apiUrl = import.meta.env.VITE_API_URL;

  const handleContentSubmit = async () => {
    let contents;
    try {
      contents = JSON.parse(jsonInput);
    } catch (err) {
      alert("JSON 파싱 에러: " + err.message);
      return;
    }

    try {
      const response = await fetch(`${apiUrl}/admin/content/bulk`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify(contents),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.detail || "요청 실패");
      }

      const result = await response.json();
      console.log("✅ 콘텐츠 업로드 성공:", result);
      alert("콘텐츠 업로드 성공!");
    } catch (err) {
      console.error("❌ 오류:", err.message);
      alert("업로드 실패: " + err.message);
    }
  };

  const handleSubscriptionSubmit = async () => {
    try {
      const response = await fetch(`${apiUrl}/admin/subscription`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          name,
          description,
          price: parseFloat(price),
          duration_days: parseInt(durationDays),
        }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.detail || "구독 상품 추가 실패");
      }

      const result = await response.json();
      console.log("✅ 구독 상품 추가 성공:", result);
      alert("구독 상품 추가 성공!");
      setName("");
      setDescription("");
      setPrice("");
      setDurationDays("");
    } catch (err) {
      console.error("❌ 오류:", err.message);
      alert("구��� 상품 추가 실패: " + err.message);
    }
  };

  const handleVideoDownloadSubmit = async () => {
    if (!downloadVideoId || !youtubeUrl || !title) {
      alert("모든 필드를 입력해주세요.");
      return;
    }

    const formData = new FormData();
    formData.append("video_id", downloadVideoId);
    formData.append("youtube_url", youtubeUrl);
    formData.append("title", title);

    try {
      const response = await fetch(`${apiUrl}/admin/videos/download`, {
        method: "POST",
        credentials: "include",
        body: formData,
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.detail || "영상 다운로드 실패");
      }

      const result = await response.json();
      console.log("✅ 영상 다운로드 성공:", result);
      alert("영상 다운로드 성공!");
      setDownloadVideoId("");
      setYoutubeUrl("");
      setTitle("");
    } catch (err) {
      console.error("❌ 오류:", err.message);
      alert("영상 다운로드 실패: " + err.message);
    }
  };

  const handleVideoUploadSubmit = async () => {
    if (!uploadVideoId) {
      alert("업로드할 Video ID를 입력해주세요.");
      return;
    }

    const formData = new FormData();
    formData.append("video_id", uploadVideoId);

    try {
      const response = await fetch(`${apiUrl}/admin/videos/upload`, {
        method: "POST",
        credentials: "include",
        body: formData,
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.detail || "영상 업로드 실패");
      }

      const result = await response.json();
      console.log("✅ 영상 업로드 성공:", result);
      alert(`Video ID ${uploadVideoId} 업로드 성공!`);
      setUploadVideoId("");
    } catch (err) {
      console.error("❌ 오류:", err.message);
      alert("영상 업로드 실패: " + err.message);
    }
  };


  return (
    <div>
      <h2>📥 JSON 콘텐츠 입력</h2>
      <textarea
        rows={10}
        cols={80}
        value={jsonInput}
        onChange={(e) => setJsonInput(e.target.value)}
        placeholder="여기에 JSON 형식으로 콘텐츠를 입력하세요"
      />
      <br />
      <button onClick={handleContentSubmit}>📤 콘텐츠 업로드</button>

      <h2 style={{ marginTop: "40px" }}>➕ 구독 상품 추가</h2>
      <div>
        <label>상품명:</label>
        <input type="text" value={name} onChange={(e) => setName(e.target.value)} />
      </div>
      <div>
        <label>설명:</label>
        <input type="text" value={description} onChange={(e) => setDescription(e.target.value)} />
      </div>
      <div>
        <label>가격:</label>
        <input type="number" value={price} onChange={(e) => setPrice(e.target.value)} />
      </div>
      <div>
        <label>기간 (일):</label>
        <input type="number" value={durationDays} onChange={(e) => setDurationDays(e.target.value)} />
      </div>
      <button onClick={handleSubscriptionSubmit}>➕ 구독 상품 추가</button>

      <h2 style={{ marginTop: "40px" }}>📹 영상 다운로드 (YouTube)</h2>
      <div>
        <label>Video ID:</label>
        <input type="number" value={downloadVideoId} onChange={(e) => setDownloadVideoId(e.target.value)} />
      </div>
      <div>
        <label>YouTube URL:</label>
        <input type="text" value={youtubeUrl} onChange={(e) => setYoutubeUrl(e.target.value)} />
      </div>
      <div>
        <label>Title:</label>
        <input type="text" value={title} onChange={(e) => setTitle(e.target.value)} />
      </div>
      <button onClick={handleVideoDownloadSubmit}>📤 영상 다운로드</button>

      <h2 style={{ marginTop: "40px" }}>📹 영상 업로드</h2>
      <div>
        <label>Video ID:</label>
        <input type="number" value={uploadVideoId} onChange={(e) => setUploadVideoId(e.target.value)} />
      </div>
      <button onClick={handleVideoUploadSubmit}>📤 영상 업로드</button>
    </div>
  );
};

export default Dashboard;
