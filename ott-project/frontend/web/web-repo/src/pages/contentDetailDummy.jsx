import "../style/contentDetail.css";

function ContentDetail() {
  return (
    <div className="content-detail-container">
      <div className="content-info">
        <img src="/images/파괴로고.png" alt="Title Logo" className="title-logo" />
        <p className="info-line">🔞 2024 • 2시간 2분 • 액션 • 성장</p>
        <p className="description">
          40여 년간 감정 없이 바퀴벌레 같은 인간들을 방역해 온 60대 킬러 조각.
          그리고 평생 조각을 쫓은...
          <span className="more">더보기</span>
        </p>
        <div className="rating-box">
          <span className="star">★</span>
          <span className="rating">3.2</span>
          <span className="label">평균 별점</span>
        </div>

        <div className="button-row">
          <button className="buy-btn">📺 구매하기</button>
          <button className="gift-btn">🎁 선물하기</button>
        </div>

        <div className="action-row">
          <div className="action-item">+ 찜하기</div>
          <div className="action-item">★ 평가하기</div>
          <div className="action-item">🗨 왓챠파티</div>
          <div className="action-item">⋯ 더보기</div>
        </div>
      </div>

      <div className="content-thumbnail">
        <img src="/images/파괴장면.png" alt="Thumbnail" />
        <button className="preview-btn">미리보기 &gt;</button>
      </div>
    </div>
  );
}

export default ContentDetail;