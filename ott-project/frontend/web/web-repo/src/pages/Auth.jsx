import { useState } from "react";
import "../style/Auth.css";
import { useRive, useStateMachineInput, Layout, Fit, Alignment } from '@rive-app/react-canvas';
import { useNavigate } from "react-router-dom";


function Card({ children, className }) {
  return <div className={`card ${className}`}>{children}</div>;
}

function CardContent({ children }) {
  return <div className="card-content">{children}</div>;
}

function Input({ className, ...props }) {
  return <input className={`input ${className}`} {...props} />;
}

function RiveLoginButton({ onClick }) {
  const STATE_MACHINE_NAME = "State Machine 1";
  const BOOLEAN_INPUT_NAME = "Boolean 1";

  const { RiveComponent, rive } = useRive({
    src: "/rive/button.riv",
    autoplay: true,
    stateMachines: STATE_MACHINE_NAME,
    layout: new Layout({ fit: Fit.Contain, alignment: Alignment.Center }),
  });

  const booleanInput = useStateMachineInput(rive, STATE_MACHINE_NAME, BOOLEAN_INPUT_NAME);

  const handleClick = () => {
    if (booleanInput) booleanInput.value = !booleanInput.value;
    onClick(); // 버튼 누르면 로그인 함수 실행
  };

  return (
    <div style={{ width: "350px", height: "150px" }} onClick={handleClick}>
      <RiveComponent />
    </div>
  );
}

function LoginSignup() {
  const navigate = useNavigate();
  const [isLogin, setIsLogin] = useState(true);
  const toggleForm = () => setIsLogin(!isLogin);

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [msg, setMsg] = useState('');
  

  const handleLogin = async () => {
    try {
      const res = await fetch('http://localhost:8000/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.detail || '로그인 실패');
      }

      const data = await res.json();
      localStorage.setItem('access_token', data.access_token);
      setMsg('✅ 로그인 성공!');
      
      setTimeout(() => {
        navigate("/home");
      }, 1000);


    } catch (error) {
      setMsg(`❌ ${error.message}`);
    }
  };

  return (
    <div className="login-container">
      <Card className="login-card">
        <CardContent>
          <h1 className="login-title">
            {isLogin ? "로그인" : "회원가입"}
          </h1>

          <div className="form-wrapper">
            <form className="form" onSubmit={(e) => e.preventDefault()}>
              {!isLogin && <Input type="text" placeholder="Username" />}
              <Input
                type="email"
                placeholder="Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
              <Input
                type="password"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
              <RiveLoginButton onClick={handleLogin} />
            </form>

            <p className="form-toggle">
              {isLogin ? "Need to join us?" : "Already among us?"}{" "}
              <span className="toggle-link" onClick={toggleForm}>
                {isLogin ? "Sign up" : "Log in"}
              </span>
            </p>

            {msg && <p className="message">{msg}</p>}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

export default LoginSignup;