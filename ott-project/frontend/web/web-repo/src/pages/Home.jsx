import { useEffect, useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import "../style/Home.css";
import backgroundImage from "../assets/프론트 배경.png";

function Home() {
  const [contents, setContents] = useState([]);
  const scrollRef = useRef(null);
  const navigate = useNavigate();
  const apiUrl = import.meta.env.VITE_API_URL;


  useEffect(() => {
    const fetchContents = async () => {
      try {
        const res = await fetch(`${apiUrl}/contents/`);
        
        const data = await res.json();
        console.log("서버에서 받은 콘텐츠:", data); // 🔥 이 줄 추가
        setContents(data.slice(0, 5));
      } catch (error) {
        console.error("콘텐츠 불러오기 실패:", error);
      }
    };

    fetchContents();
  }, []);

  const scrollLeft = () => {
    scrollRef.current?.scrollBy({ left: -300, behavior: "smooth" });
  };

  const scrollRight = () => {
    scrollRef.current?.scrollBy({ left: 300, behavior: "smooth" });
  };

  const goToDetail = (id) => {
    navigate(`/content/${id}`);
  };

  return (
    <div className="home-container">
      <h1>Moodly</h1>

      <div className="home-banner">
        <img src={backgroundImage} alt="Moodly 배경" className="banner-image" />
      </div>
      <h2 className="section-title">Moodly 인기 콘텐츠</h2>
      <div className="scroll-container">
        <button className="scroll-button left" onClick={scrollLeft}>←</button>
        <div className="content-row" ref={scrollRef}>
          {contents.map((item) => (
            <div
              key={item.id}
              className="content-box"
              onClick={() => goToDetail(item.id)}
            >
              {item.title}
            </div>
          ))}
        </div>
        <button className="scroll-button right" onClick={scrollRight}>→</button>
      </div>
    </div>
  );
}

export default Home;
