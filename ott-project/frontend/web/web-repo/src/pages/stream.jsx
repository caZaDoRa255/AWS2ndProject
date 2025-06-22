import { useRef, useState, useEffect } from "react";
import "../style/stream.css";

function VideoPlayer() {
  const videoRef = useRef(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [volume, setVolume] = useState(1);
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const video = videoRef.current;
    if (video) video.volume = volume;
  }, [volume]);

  const togglePlay = () => {
    const video = videoRef.current;
    if (!video) return;
    if (video.paused) {
      video.play();
      setIsPlaying(true);
    } else {
      video.pause();
      setIsPlaying(false);
    }
  };

  const handleProgressChange = (e) => {
    const video = videoRef.current;
    if (!video) return;
    const newTime = (e.target.value / 100) * video.duration;
    video.currentTime = newTime;
    setProgress(e.target.value);
  };

  const handleTimeUpdate = () => {
    const video = videoRef.current;
    if (!video) return;
    const percent = (video.currentTime / video.duration) * 100;
    setProgress(percent);
  };

  const skip = (seconds) => {
    const video = videoRef.current;
    if (!video) return;
    video.currentTime += seconds;
  };

  const toggleFullscreen = () => {
    const video = videoRef.current;
    if (!video) return;
    if (document.fullscreenElement) {
      document.exitFullscreen();
    } else {
      video.requestFullscreen();
    }
  };

  return (
    <div className="video-container">
      <h1 className="stream-title">🎬 Moodly Video Stream</h1>

      <video
        ref={videoRef}
        src="/videos/Popeye_forPresident_512kb.mp4"
        controls={false}
        preload="auto"
        width="800"
        onTimeUpdate={handleTimeUpdate}
      >
        죄송합니다. 사용자의 브라우저는 video 태그를 지원하지 않습니다.
      </video>

      <div className="video-controls">
        <input
          type="range"
          min="0"
          max="100"
          value={progress}
          onChange={handleProgressChange}
          className="progress-slider"
        />

        <button onClick={() => skip(-10)}>⏪ 10s</button>
        <button onClick={togglePlay}>{isPlaying ? "⏸️" : "▶️"}</button>
        <button onClick={() => skip(10)}>⏩ 10s</button>

        <input
          type="range"
          min="0"
          max="1"
          step="0.05"
          value={volume}
          onChange={(e) => setVolume(parseFloat(e.target.value))}
          className="volume-slider"
        />

        <button onClick={toggleFullscreen}>⛶</button>
      </div>
    </div>
  );
}

export default VideoPlayer;
