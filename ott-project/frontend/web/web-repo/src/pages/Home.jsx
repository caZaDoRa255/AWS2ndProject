import { useEffect, useState, useRef } from "react";
import "../style/Home.css";

function Home() {
  const [contents, setContents] = useState([]);
  const [selectedIndex, setSelectedIndex] = useState(null);
  const scrollRef = useRef(null);

  useEffect(() => {
    const fetchContents = async () => {
      try {
        const res = await fetch("http://localhost:8000/contents/");
        const data = await res.json();
        setContents(data.slice(0, 10));
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

  const handleBoxClick = (index) => {
    setSelectedIndex(index === selectedIndex ? null : index);
  };

  const handleLike = (title) => {
    alert(`'${title}' 찜 완료!`);
  };

  return (
    <div className="home-container">
      <h1>Moodly</h1>
      <div className="scroll-container">
        <button className="scroll-button left" onClick={scrollLeft}>←</button>
        <div className="content-row" ref={scrollRef}>
          {contents.map((item, index) => (
            <div
              key={index}
              className="content-box"
              onClick={() => handleBoxClick(index)}
            >
              {item.title}

              {selectedIndex === index && (
                <div className="dropdown-detail" onClick={(e) => e.stopPropagation()}>
                  <p><strong>ID:</strong> {item.id}</p>
                  <p><strong>Category:</strong> {item.category}</p>
                  <p><strong>Year:</strong> {item.year}</p>
                  <p><strong>Description:</strong> {item.description}</p>
                  <button
                    className="like-button"
                    onClick={(e) => {
                      e.stopPropagation();
                      handleLike(item.title);
                    }}
                  >
                    ❤️ 찜하기
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
        <button className="scroll-button right" onClick={scrollRight}>→</button>
      </div>
    </div>
  );
}

export default Home;