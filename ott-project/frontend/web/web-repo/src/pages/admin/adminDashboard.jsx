

import { useState } from "react";
import { useNavigate } from "react-router-dom";

// src/components/BulkContentUploader.jsx


const Dashboard = () => {
  const [jsonInput, setJsonInput] = useState(`[
]`);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [price, setPrice] = useState("");
  const [durationDays, setDurationDays] = useState("");
  const apiUrl = import.meta.env.VITE_API_URL;

  const handleContentSubmit = async () => {
    let contents;
    try {
      contents = JSON.parse(jsonInput); // 문자열 → JS 객체
    } catch (err) {
      alert("JSON 파싱 에러: " + err.message);
      return;
    }

    try {
      const response = await fetch(`${apiUrl}/admin/content/bulk`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        credentials: "include", // access_token 쿠키 전송
        body: JSON.stringify(contents)
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.detail || "요청 실패");
      }

      const result = await response.json();
      console.log("✅ 업로드 성공:", result);
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
        headers: {
          "Content-Type": "application/json",
        },
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
      // Clear form fields
      setName("");
      setDescription("");
      setPrice("");
      setDurationDays("");
    } catch (err) {
      console.error("❌ 오류:", err.message);
      alert("구독 상품 추가 실패: " + err.message);
    }
  };

  return (
    <div>
      <h2>📥 JSON 콘텐츠 입력</h2>
      <textarea
        rows={20}
        cols={80}
        value={jsonInput}
        onChange={(e) => setJsonInput(e.target.value)}
        placeholder="여기에 JSON 형식으로 콘텐츠를 입력하세요"
      />
      <br />
      <button onClick={handleContentSubmit}>📤 업로드</button>

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
    </div>
  );
};

export default Dashboard;