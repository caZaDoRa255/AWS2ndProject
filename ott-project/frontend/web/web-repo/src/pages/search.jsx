import { useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import "../style/search.css";
import { useNavigate } from "react-router-dom";

function Search() {
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(true);
  const location = useLocation();
  const navigate = useNavigate();
  // URL 쿼리에서 keyword 추출
  const query = new URLSearchParams(location.search);
  const keyword = query.get('keyword');

  useEffect(() => {
    
    const fetchResults = async () => {
      try {
        const response = await fetch(`http://localhost:8000/contents/search?keyword=${encodeURIComponent(keyword)}`);
        if (!response.ok) {
          throw new Error('검색 실패');
        }
        const data = await response.json();
        setResults(data);
      } catch (error) {
        console.error('검색 중 오류 발생:', error);
        setResults([]);
      } finally {
        setLoading(false);
      }
    };

    if (keyword) {
      fetchResults();
    } else {
      setLoading(false);
    }
  }, [keyword]);

  return (
    <div className="search-results">
      <h2>🔍 "{keyword}"에 대한 검색 결과</h2>
      {loading ? (
        <p>검색 중...</p>
      ) : results.length > 0 ? (
            <ul className="search-result-list">
                {results.map((item, index) => (
                    <li 
                    key={index} 
                    className="search-result-item"
                    onClick={() => navigate(`/content/${item.id}`)}
                    style={{ cursor: "pointer" }}
                    >
                    <div className="content-info">
                        <div className="title">{item.title}</div>
                        <div className="meta">
                        {item.category} · {item.year}
                        </div>
                    </div>
                    </li>
                ))}
                </ul>
      ) : (
        <p>검색 결과가 없습니다.</p>
      )}
    </div>
  );
}

export default Search;