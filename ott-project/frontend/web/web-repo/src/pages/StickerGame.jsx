import React, { useState, useRef, useEffect } from 'react';
import '../style/StickerGame.css';

const StickerGame = () => {
  const stickerImages = [
    '/image/stickers/1.png',
    '/image/stickers/2.png',
    '/image/stickers/3.png',
    '/image/stickers/4.png',
    '/image/stickers/5.png',
    '/image/stickers/6.png',
  ];

  const [stickers, setStickies] = useState([]);
  const [draggingSticker, setDraggingSticker] = useState(null);
  const [offset, setOffset] = useState({ x: 0, y: 0 });
  const boxRef = useRef(null);

  const handleDragStart = (e, stickerId) => {
    const sticker = stickers.find(s => s.id === stickerId);
    if (sticker) {
      setDraggingSticker(stickerId);
      setOffset({
        x: e.clientX - sticker.x,
        y: e.clientY - sticker.y,
      });
    }
  };

  const handleDragOver = (e) => {
    e.preventDefault();
  };

  const handleDrop = (e) => {
    e.preventDefault();
    if (draggingSticker === null) return;

    const boxRect = boxRef.current.getBoundingClientRect();
    const newX = e.clientX - boxRect.left - offset.x;
    const newY = e.clientY - boxRect.top - offset.y;

    setStickies(prevStickies =>
      prevStickies.map(sticker =>
        sticker.id === draggingSticker
          ? { ...sticker, x: newX, y: newY }
          : sticker
      )
    );
    setDraggingSticker(null);
  };

  const addStickerToBox = (imageSrc) => {
    if (!boxRef.current) return; // Ensure boxRef is available

    const boxRect = boxRef.current.getBoundingClientRect();
    const stickerWidth = 300; // As defined in CSS
    const stickerHeight = 300; // As defined in CSS

    const centerX = (boxRect.width / 2) - (stickerWidth / 2);
    const centerY = (boxRect.height / 2) - (stickerHeight / 2);

    const newSticker = {
      id: Date.now(),
      image: imageSrc,
      x: centerX,
      y: centerY,
    };
    setStickies(prevStickies => [...prevStickies, newSticker]);
  };

  return (
    <div className="sticker-game-container">
      <h1 className="game-title">Sticker Minigame</h1>
      <div className="sticker-palette">
        {stickerImages.map((image, index) => (
          <img
            key={index}
            src={image}
            alt={`Sticker ${index + 1}`}
            className="palette-sticker"
            onClick={() => addStickerToBox(image)}
          />
        ))}
      </div>
      <div
        className="sticker-box"
        ref={boxRef}
        onDragOver={handleDragOver}
        onDrop={handleDrop}
      >
        {stickers.map(sticker => (
          <img
            key={sticker.id}
            src={sticker.image}
            alt="Placed Sticker"
            className="placed-sticker"
            style={{ left: sticker.x, top: sticker.y }}
            onMouseDown={(e) => handleDragStart(e, sticker.id)}
            draggable="true"
          />
        ))}
      </div>
    </div>
  );
};

export default StickerGame;