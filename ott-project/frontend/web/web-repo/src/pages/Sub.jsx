import { useState } from "react";
import { useNavigate } from "react-router-dom";
import "../style/Sub.css";

const plans = [
    {
      name: "베이직",
      resolution: "1080p (Full HD)",
      price: "₩7,000",
      devices: "TV, 컴퓨터, 스마트폰, 태블릿",
      quality: "좋음",
      streams: 2,
      downloads: 2,
      ads: "생각보다 적은 광고",
      chat: "10회 가능"
    },
    {
      name: "스탠다드",
      resolution: "1080p (Full HD)",
      price: "₩13,500",
      devices: "TV, 컴퓨터, 스마트폰, 태블릿",
      quality: "좋음",
      streams: 2,
      downloads: 2,
      ads: "무광고",
      chat: "30회 가능"
    },
    {
      name: "프리미엄",
      resolution: "4K (UHD) + HDR",
      price: "₩17,000",
      devices: "TV, 컴퓨터, 스마트폰, 태블릿",
      quality: "가장 좋음",
      streams: 4,
      downloads: 6,
      ads: "무광고",
      chat: "무제한"
    },
  ];
  
  function Sub() {
    const [selected, setSelected] = useState(null);
    const navigate = useNavigate();
    const apiUrl = import.meta.env.VITE_API_URL;
  
    const handleSelect = (index) => {
      setSelected(index);
    };
  
    const handleNext = async () => {
      if (selected === null) {
        alert("플랜을 선택하세요.");
        return;
      }
      
      const plan_id = selected + 1;

      try {
        const response = await fetch(`${apiUrl}/subscribe/${plan_id}`, {
            method: 'POST',
            credentials: 'include',
        });

        if (response.ok) {
            alert(`'${plans[selected].name}' 플랜 구독이 완료되었습니다.`);
            navigate('/');
        } else {
            const errorData = await response.json();
            alert(`구독에 실패했습니다: ${errorData.detail}`);
        }
      } catch (error) {
        console.error('구독 요청 실패:', error);
        alert('구독 중 오류가 발생했습니다.');
      }
    };
  
    return (
      <div className="sub-container">
        <h2 className="sub-title">원하는 멤버십을 선택하세요.</h2>
        <div className="plan-wrapper">
          {plans.map((plan, index) => (
            <div
              key={index}
              className={`plan-card ${selected === index ? "selected" : ""}`}
              onClick={() => handleSelect(index)}
            >
              <div className="plan-name">{plan.name}</div>
              <div className="plan-price">{plan.price}</div>
              <div className="plan-detail"><strong>화질:</strong> {plan.quality}</div>
              <div className="plan-detail"><strong>해상도:</strong> {plan.resolution}</div>
              <div className="plan-detail"><strong>지원 디바이스:</strong> {plan.devices}</div>
              <div className="plan-detail"><strong>동시접속:</strong> {plan.streams}명</div>
              <div className="plan-detail"><strong>저장 기기 수:</strong> {plan.downloads}</div>
              <div className="plan-detail"><strong>광고:</strong> {plan.ads}</div>
              <div className ="plan-detail"><strong>Cozyly: </strong>{plan.chat}</div>
            </div>
          ))}
        </div>
        <button className="next-button" onClick={handleNext}>다음</button>
      </div>
    );
  }
  
  export default Sub;