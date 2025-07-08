import { useRef, useState, useEffect } from "react";
import { useParams } from "react-router-dom";
import "../style/stream.css";

function VideoPlayer() {
  const { videoId } = useParams(); // Get videoId from URL
  const videoRef = useRef(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [volume, setVolume] = useState(1);
  const [progress, setProgress] = useState(0);
  const [videoUrl, setVideoUrl] = useState("");
  const apiUrl = import.meta.env.VITE_API_URL;

  useEffect(() => {
    const video = videoRef.current;
    if (video) video.volume = volume;
  }, [volume]);

  useEffect(() => {
    const fetchVideoUrl = async () => {
      if (!videoId) {
        console.log("No video ID in URL");
        return;
      }
      try {
        const response = await fetch(`${apiUrl}/history/${videoId}/url`, {
          method: 'Get',
          credentials: "include" // ⚠️ 쿠키 포함 필수!
        });
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data = await response.json();
        if (data.stream_url) {
          setVideoUrl(data.stream_url);
        } else {
          throw new Error("No stream_url in response data");
        }
      } catch (error) {
        console.error("Error fetching video URL:", error);
      }
    };

    fetchVideoUrl();
  }, [apiUrl, videoId]); // Add videoId to dependency array

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

      {videoUrl ? (
        <video
          ref={videoRef}
          src={videoUrl}
          controls={false}
          preload="auto"
          width="800"
          onTimeUpdate={handleTimeUpdate}
          autoPlay
        >
          죄송합니다. 사용자의 브라우저는 video 태그를 지원하지 않습니다.
        </video>
      ) : (
        <p>Loading video for ID: {videoId}...</p>
      )}

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
