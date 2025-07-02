import React, { useState } from 'react';

function Chatbot() {
  const [message, setMessage] = useState('');
  const [response, setResponse] = useState(null);
  const apiUrl = import.meta.env.VITE_API_URL;


  const handleSend = async () => {
    try {
      const res = await fetch(`${apiUrl}/chatbot`, {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ message }),
      });

      const data = await res.json();
      setResponse(data); // 서버 응답 저장
    } catch (error) {
      console.error('오류 발생:', error);
      setResponse({ error: '서버 오류' });
    }
  };

  const markdownToHtml = (text) => {
    if (!text) return '';

    let html = text;
    html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
    html = html.replace(/\n/g, '<br>');

    const lines = html.split('<br>');
    let inList = false;
    let converted = [];

    for (let line of lines) {
      if (/^\d+\.\s/.test(line)) {
        if (!inList) {
          converted.push('<ol>');
          inList = true;
        }
        const item = line.replace(/^\d+\.\s/, '');
        converted.push(`<li>${item}</li>`);
      } else {
        if (inList) {
          converted.push('</ol>');
          inList = false;
        }
        converted.push(`<p>${line}</p>`);
      }
    }

    if (inList) converted.push('</ol>');

    return converted.join('');
  };
  //이게 아마 마크다운 --> html로 바꾸는 자바스크립트.

  return (
    <div style={{ padding: '2rem' }}>
      <h1>Chatbot</h1>
      <input
        type="text"
        placeholder="메시지를 입력하세요"
        value={message}
        onChange={(e) => setMessage(e.target.value)}
        style={{ width: '300px', marginRight: '1rem' }}
      />
      <button onClick={handleSend}>보내기</button>

      <div
        style={{
           marginTop: '2rem',
           backgroundColor: '#f5f5f5',
           padding: '1rem',
           borderRadius: '4px',
           color: 'black' // ✅ 여기에 추가
        }}
      >
        <strong>응답:</strong>
        <div
          dangerouslySetInnerHTML={{
            __html: response?.reply ? markdownToHtml(response.reply) : '응답 없음',
          }}
        />
      </div>
    </div>
  );
}

export default Chatbot;