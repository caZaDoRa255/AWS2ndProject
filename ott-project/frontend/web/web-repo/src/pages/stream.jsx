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
  const [continueFrom, setContinueFrom] = useState(null);
  const apiUrl = import.meta.env.VITE_API_URL;

  useEffect(() => {
    const video = videoRef.current;
    if (video) video.volume = volume;
  }, [volume]);

  useEffect(() => {
    const fetchVideoAndContinueData = async () => {
      if (!videoId) {
        console.log("No video ID in URL");
        return;
      }

      // 1. Fetch Video URL
      try {
        const urlResponse = await fetch(`${apiUrl}/history/${videoId}/url`, {
          method: 'Get',
          credentials: "include"
        });
        if (!urlResponse.ok) throw new Error(`HTTP error! status: ${urlResponse.status}`);
        const urlData = await urlResponse.json();
        if (urlData.stream_url) {
          setVideoUrl(urlData.stream_url);
        } else {
          throw new Error("No stream_url in response data");
        }
      } catch (error) {
        console.error("Error fetching video URL:", error);
        return;
      }

      // 2. Fetch Continue Time
      try {
        const continueResponse = await fetch(`${apiUrl}/history/continue?videoID=${videoId}`, {
          method: 'GET',
          credentials: 'include',
        });
        if (!continueResponse.ok) throw new Error(`HTTP error! status: ${continueResponse.status}`);
        const continueData = await continueResponse.json();
        const historyItem = continueData.find(item => item.content_id == videoId);
        
        if (historyItem && historyItem.progress) {
          const progressPercentage = historyItem.progress;
          const video = videoRef.current;
          if (video) {
            const onMetadataLoaded = () => {
              const duration = video.duration;
              const startTimeInSeconds = Math.round((progressPercentage / 100) * duration);

              if (window.confirm(`Continue watching from ${startTimeInSeconds} seconds?`)) {
                video.currentTime = startTimeInSeconds;
                setContinueFrom(startTimeInSeconds);
              }
              video.removeEventListener('loadedmetadata', onMetadataLoaded);
            };
            video.addEventListener('loadedmetadata', onMetadataLoaded);
          }
        }
      } catch (error) {
        console.error("Error fetching continue time:", error);
      }
    };

    fetchVideoAndContinueData();
  }, [apiUrl, videoId]);

  const lastProgressSent = useRef(null);
  const lastTimeUpdateSent = useRef(0);

  useEffect(() => {
    const video = videoRef.current;
    const sendFinalProgress = () => {
      if (!video || !video.duration) return;
      const progressInPercentage = Math.round((video.currentTime / video.duration) * 100);
      if (progressInPercentage !== lastProgressSent.current) {
        const url = `${apiUrl}/history/${videoId}?progress=${progressInPercentage}`;
        navigator.sendBeacon(url);
      }
    };
    window.addEventListener('beforeunload', sendFinalProgress);
    return () => {
      sendFinalProgress();
      window.removeEventListener('beforeunload', sendFinalProgress);
    };
  }, [apiUrl, videoId]);

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
    if (!video || !video.duration) return;

    const percent = (video.currentTime / video.duration) * 100;
    setProgress(percent);

    const now = Date.now();
    if (now - lastTimeUpdateSent.current > 5000) { // Send every 5 seconds
      const progressInPercentage = Math.round(percent);
      lastProgressSent.current = progressInPercentage;
      
      fetch(`${apiUrl}/history/${videoId}?progress=${progressInPercentage}`, {
        method: 'POST',
        credentials: 'include',
      }).catch(error => console.error('Error sending progress:', error));
      
      lastTimeUpdateSent.current = now;
    }
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

      {continueFrom && (
        <p className="continue-from-text">
          Continuing from {Math.round(continueFrom)} seconds.
        </p>
      )}

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
