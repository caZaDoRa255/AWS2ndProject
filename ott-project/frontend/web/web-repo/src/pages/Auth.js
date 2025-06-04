import { useState } from "react";
import "../style/Auth.css";


function Card({ children, className }) {
  return <div className={`card ${className}`}>{children}</div>;
}

function CardContent({ children }) {
  return <div className="card-content">{children}</div>;
}

function Button({ children, className, ...props }) {
  return (
    <button className={`btn ${className}`} {...props}>
      {children}
    </button>
  );
}

function Input({ className, ...props }) {
  return <input className={`input ${className}`} {...props} />;
}

function LoginSignup() {
  const [isLogin, setIsLogin] = useState(true);
  const toggleForm = () => setIsLogin(!isLogin);

  return (
    <div className="login-container">
      <Card className="login-card">
        <CardContent>
          <h1 className="login-title">
            {isLogin ? "로그인" : "회원가입"}
          </h1>

          <div className="form-wrapper">
            <form className="form">
              {!isLogin && <Input type="text" placeholder="Username" />}
              <Input type="email" placeholder="Email" />
              <Input type="password" placeholder="Password" />
              <Button type="submit">
                {isLogin ? "Moodly 로그인" : "Moodly 회원가입"}
              </Button>
            </form>

            <p className="form-toggle">
              {isLogin ? "Need to join us?" : "Already among us?"} {" "}
              <span className="toggle-link" onClick={toggleForm}>
                {isLogin ? "Sign up" : "Log in"}
              </span>
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

export default LoginSignup;
