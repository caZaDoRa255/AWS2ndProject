

import { useState } from "react";
import { useNavigate } from "react-router-dom";

// src/components/BulkContentUploader.jsx


const Dashboard = () => {
  const [jsonInput, setJsonInput] = useState(`[
]`);
  const apiUrl = import.meta.env.VITE_API_URL;

  const handleSubmit = async () => {
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
      <button onClick={handleSubmit}>📤 업로드</button>
    </div>
  );
};

export default Dashboard;