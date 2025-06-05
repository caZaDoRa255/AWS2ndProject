import { useState } from "react";
import "../style/Auth.css";
import { useRive, useStateMachineInput, Layout, Fit, Alignment } from '@rive-app/react-canvas';

function Card({ children, className }) {
  return <div className={`card ${className}`}>{children}</div>;
}

function CardContent({ children }) {
  return <div className="card-content">{children}</div>;
}

function Input({ className, ...props }) {
  return <input className={`input ${className}`} {...props} />;
}

function RiveLoginButton() {
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
    if (booleanInput) {
      booleanInput.value = !booleanInput.value;
    }
  };

  return (
    <div style={{ width: "350px", height: "150px" }} onClick={handleClick}>

      <RiveComponent />
    </div>
  );
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
              <RiveLoginButton />
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
