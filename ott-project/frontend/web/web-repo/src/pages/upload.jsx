import { useState } from "react";

function VideoUploader() {
  const [file, setFile] = useState(null);
  const [status, setStatus] = useState("");

  const handleChange = (e) => {
    setFile(e.target.files[0]);
  };

  const uploadFile = async () => {
    if (!file) {
      setStatus("파일을 먼저 선택해줘...");
      return;
    }

    try {
      // 1. presigned URL 요청
      const res = await fetch(`http://localhost:8000/upload/presigned-url?filename=${file.name}`);
      const { upload_url } = await res.json();

      // 2. presigned URL로 S3에 업로드
      const upload = await fetch(upload_url, {
        method: "PUT",
        headers: {
          "Content-Type": file.type,
        },
        body: file,
      });

      if (upload.ok) {
        setStatus("🌑 업로드 성공… 이제 널 기억할 거야.");
      } else {
        const error = await upload.text();
        setStatus("💀 업로드 실패: " + error);
      }
    } catch (err) {
      setStatus("⚠️ 뭔가 끔찍한 일이 일어났어: " + err.message);
    }
  };

  return (
    <div>
      <input type="file" accept="video/*" onChange={handleChange} />
      <button onClick={uploadFile}>업로드</button>
      <p>{status}</p>
    </div>
  );
}

export default VideoUploader;