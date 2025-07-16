import { useEffect, useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import "../style/Home.css";
import backgroundImage from "../assets/프론트 배경.png";

function Home() {
  const [contents, setContents] = useState([]);
  const scrollRefs = useRef([]);
  const navigate = useNavigate();
  const apiUrl = import.meta.env.VITE_API_URL;

  useEffect(() => {
    const fetchContents = async () => {
      console.log('🔍 콘텐츠 API 연결 확인...');
      console.log('API URL:', apiUrl);
      
      try {
        const res = await fetch(`${apiUrl}/contents/`);
        const data = await res.json();
        console.log("서버에서 받은 콘텐츠:", data);
        setContents(data);
      } catch (error) {
        console.error("콘텐츠 불러오기 실패:", error);
      }
    };

    fetchContents();
  }, [apiUrl]);

  const chunkArray = (arr, size) => {
    const chunkedArr = [];
    for (let i = 0; i < arr.length; i += size) {
      chunkedArr.push(arr.slice(i, i + size));
    }
    return chunkedArr;
  };

  const contentRows = chunkArray(contents, 4);
  const rowTitles = ["Moodly 인기 콘텐츠", "지금 뜨는 콘텐츠", "새로 올라온 콘텐츠"];

  const scrollLeft = (index) => {
    scrollRefs.current[index]?.scrollBy({ left: -300, behavior: "smooth" });
  };

  const scrollRight = (index) => {
    scrollRefs.current[index]?.scrollBy({ left: 300, behavior: "smooth" });
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

      {contentRows.map((row, index) => (
        <div key={index} className="content-section">
          <h2 className="section-title">{rowTitles[index] || '추천 콘텐츠'}</h2>
          <div className="scroll-container">
            <button className="scroll-button left" onClick={() => scrollLeft(index)}>
              ←
            </button>
            <div className="content-row" ref={(el) => (scrollRefs.current[index] = el)}>
              {row.map((item) => (
                <div
                  key={item.id}
                  className="content-box"
                  onClick={() => goToDetail(item.id)}
                >
                  <img
                    src={`${import.meta.env.VITE_CLOUDFRONT_URL}/thumbnails/${
                      item.id
                    }.png`}
                    alt={item.title}
                  />
                  <div className="content-title">{item.title}</div>
                </div>
              ))}
            </div>
            <button className="scroll-button right" onClick={() => scrollRight(index)}>
              →
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}

export default Home;