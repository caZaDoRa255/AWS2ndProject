import React, { useState, useEffect, useRef } from 'react';
import '../style/Chat.css'; // Import the new CSS file

function Chatbot() {
  const [message, setMessage] = useState('');
  const [chatHistory, setChatHistory] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const apiUrl = import.meta.env.VITE_API_URL;
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [chatHistory]);

  const handleSend = async () => {
    if (!message.trim()) return;

    const userMessage = { type: 'user', text: message };
    setChatHistory(prev => [...prev, userMessage]);
    setMessage('');
    setIsLoading(true);

    try {
      const res = await fetch(`${apiUrl}/lab_chatbot`, {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ message }),
      });

      if (!res.ok) {
        throw new Error(`HTTP error! status: ${res.status}`);
      }

      const data = await res.json();
      const modelMessage = { type: 'model', text: data.response || "No response from model." };
      setChatHistory(prev => [...prev, modelMessage]);

    } catch (error) {
      console.error('Error sending message:', error);
      const errorMessage = { type: 'model', text: `Error: ${error.message}` };
      setChatHistory(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const markdownToHtml = (text) => {
    if (!text) return '';
    let html = text;
    html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
    html = html.replace(/\n/g, '<br>');
    return html;
  };

  return (
    <div className="chat-container-gemini">
      <header className="chat-header-gemini">
        <h1>Moodly Chat</h1>
      </header>
      <div className="chat-messages-gemini">
        {chatHistory.map((msg, index) => (
          <div key={index} className={`message-gemini ${msg.type}-gemini`}>
            <div dangerouslySetInnerHTML={{ __html: markdownToHtml(msg.text) }} />
          </div>
        ))}
        {isLoading && (
          <div className="message-gemini model-gemini">
            <span>Thinking...</span>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>
      <footer className="chat-input-form-gemini">
        <input
          type="text"
          className="chat-input-gemini"
          placeholder="Enter your message..."
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          onKeyPress={handleKeyPress}
          disabled={isLoading}
        />
        <button
          className="chat-submit-button-gemini"
          onClick={handleSend}
          disabled={isLoading}
        >
          <span>&#10148;</span>
        </button>
      </footer>
    </div>
  );
}

export default Chatbot;
