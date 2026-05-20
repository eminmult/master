// Desktop Login screen
const ScreenLogin = ({ onContinue }) => {
  const [phone, setPhone] = React.useState("");

  return (
    <div className="frame" style={{ minHeight: 1024 }}>
      <TopBarPublic />

      {/* glow bg */}
      <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
        <div className="glow-bg glow-yellow-1" />
        <div className="glow-bg glow-yellow-2" />
      </div>

      <main style={{
        minHeight: "calc(1024px - 80px - 111px)",
        display: "flex", alignItems: "center", justifyContent: "center",
        padding: "80px 16px",
        position: "relative",
      }}>
        <div style={{
          width: 440,
          borderRadius: 48,
          background: "rgba(24,24,27,0.5)",
          border: "1px solid #27272a",
          backdropFilter: "blur(24px)",
          padding: 40,
          boxShadow: "0 25px 50px -12px rgba(0,0,0,0.25)",
        }} className="login-card">
          <h1 style={{
            margin: 0,
            fontSize: 36,
            fontWeight: 700,
            letterSpacing: "-0.5px",
            textAlign: "center",
            lineHeight: 1.1,
          }}>Find your home<br/>expert</h1>
          <p style={{
            textAlign: "center",
            fontSize: 14,
            color: "#a1a1aa",
            lineHeight: 1.5,
            marginTop: 12,
            marginBottom: 32,
          }}>Enter your phone number to get started with<br/>premium care.</p>

          <div className="label" style={{ marginBottom: 8 }}>Phone Number</div>
          <div className="phone-field">
            <div className="cc">
              <span style={{ fontSize: 14 }}>🇺🇸 +1</span>
              <svg width="10" height="6" viewBox="0 0 10 6"><path d="M1 1l4 4 4-4" stroke="currentColor" strokeWidth="1.5" fill="none" strokeLinecap="round"/></svg>
            </div>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value.replace(/[^0-9-]/g, "").slice(0, 12))}
              placeholder="000-000-0000"
            />
          </div>

          <button
            className="btn btn-primary"
            style={{ width: "100%", marginTop: 24, height: 56 }}
            onClick={onContinue}
          >Continue</button>

          <div className="or-divider">OR</div>

          <button className="btn btn-ghost" style={{
            width: "100%", height: 58,
            display: "flex", alignItems: "center", justifyContent: "center", gap: 12,
          }}>
            <svg width="18" height="14" viewBox="0 0 24 18" fill="currentColor">
              <path d="M22 3H2a2 2 0 00-2 2v8a2 2 0 002 2h20a2 2 0 002-2V5a2 2 0 00-2-2zM2 5l10 6 10-6v8H2V5z"/>
            </svg>
            Continue with Email
          </button>

          <div style={{ textAlign: "center", marginTop: 24 }}>
            <a style={{ color: "#a1a1aa", fontSize: 14, cursor: "pointer" }}>Continue as Guest</a>
          </div>
        </div>
      </main>

      <div style={{
        padding: "32px 0",
        textAlign: "center",
        borderTop: "1px solid var(--border-2)",
        position: "relative",
      }}>
        <div style={{ display: "flex", gap: 24, justifyContent: "center", marginBottom: 8 }}>
          {["Privacy Policy", "Terms of Service", "Help Center"].map((x) => (
            <a key={x} style={{ color: "#a1a1aa", fontSize: 12, cursor: "pointer" }}>{x}</a>
          ))}
        </div>
        <div style={{ fontSize: 10, color: "#3f3f46", letterSpacing: "2px" }}>© 2026 LUXEHOME PREMIUM SERVICES</div>
      </div>
    </div>
  );
};

// Desktop SMS verification
const ScreenSMS = ({ onVerify }) => {
  const [code, setCode] = React.useState(["", "", "", ""]);
  const [resend, setResend] = React.useState(55);
  const refs = [React.useRef(), React.useRef(), React.useRef(), React.useRef()];

  React.useEffect(() => {
    if (resend <= 0) return;
    const t = setTimeout(() => setResend((r) => r - 1), 1000);
    return () => clearTimeout(t);
  }, [resend]);

  const update = (i, v) => {
    const d = v.replace(/[^0-9]/g, "").slice(-1);
    const nc = [...code]; nc[i] = d; setCode(nc);
    if (d && i < 3) refs[i+1].current?.focus();
  };

  const filled = code.every(c => c);

  return (
    <div className="frame" style={{ minHeight: 1024 }}>
      <TopBarPublic />

      <div style={{ position: "absolute", inset: 0, pointerEvents: "none", overflow: "hidden" }}>
        <div style={{
          position: "absolute", left: 0, top: 0, width: 1280, height: 1024,
          background: "radial-gradient(circle at 30% 30%, rgba(255,255,0,0.04) 0%, transparent 60%)",
        }} />
        <div style={{
          position: "absolute", left: 0, bottom: 0, width: 1440, height: 280,
          background: "linear-gradient(to top, rgba(255,255,0,0.05) 0%, transparent 100%)",
        }} />
      </div>

      <main style={{
        minHeight: "calc(1024px - 80px)",
        display: "flex", alignItems: "center", justifyContent: "center",
        padding: "119px 24px",
        position: "relative",
      }}>
        <div style={{ width: 448, display: "flex", flexDirection: "column", gap: 48 }}>
          <div style={{
            borderRadius: 48,
            background: "#121212",
            border: "1px solid #2a2a1a",
            boxShadow: "0 25px 50px -12px rgba(0,0,0,0.5)",
            padding: 48,
            position: "relative",
            overflow: "hidden",
          }}>
            <div style={{
              position: "absolute", top: -95, right: -95,
              width: 192, height: 192,
              borderRadius: "50%",
              background: "rgba(255,255,0,0.05)",
              filter: "blur(20px)",
            }} />

            {/* phone icon bubble */}
            <div style={{
              width: 64, height: 64, borderRadius: "50%",
              background: "rgba(255,255,0,0.1)",
              display: "grid", placeItems: "center",
              margin: "0 auto",
            }}>
              <svg width="22" height="28" viewBox="0 0 18 28" fill="var(--accent)">
                <rect x="1" y="1" width="16" height="26" rx="3" stroke="var(--accent)" strokeWidth="2" fill="none"/>
                <circle cx="9" cy="23" r="1.2" fill="var(--accent)"/>
              </svg>
            </div>

            <h2 style={{
              textAlign: "center", marginTop: 32,
              fontSize: 30, fontWeight: 700, letterSpacing: "-0.75px",
              color: "#f1f5f9", margin: "32px 0 12px",
            }}>Verify your number</h2>
            <p style={{
              textAlign: "center", fontSize: 14, color: "#94a3b8",
              margin: 0, lineHeight: 1.6,
            }}>We've sent a 4-digit code to<br/>+1 (•••) •••-••88</p>

            {/* inputs */}
            <div style={{ display: "flex", gap: 16, justifyContent: "center", marginTop: 32 }}>
              {code.map((d, i) => (
                <input
                  key={i}
                  ref={refs[i]}
                  value={d}
                  onChange={(e) => update(i, e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Backspace" && !code[i] && i > 0) refs[i-1].current?.focus();
                  }}
                  maxLength={1}
                  style={{
                    width: 68, height: 80,
                    borderRadius: 16,
                    background: d ? "rgba(255,255,0,0.1)" : "rgba(255,255,255,0.03)",
                    border: d ? "1px solid var(--accent)" : "1px solid #2a2a1a",
                    color: "var(--text)",
                    fontFamily: "inherit",
                    fontSize: 32,
                    fontWeight: 700,
                    textAlign: "center",
                    outline: "none",
                    transition: "all 160ms",
                  }}
                />
              ))}
            </div>

            <div style={{
              marginTop: 24, textAlign: "center",
              fontSize: 14, color: "#94a3b8",
            }}>
              Didn't receive the code?{" "}
              <span style={{ color: "var(--accent)", fontWeight: 500, cursor: resend > 0 ? "default" : "pointer" }}>
                {resend > 0 ? `Resend in 00:${String(resend).padStart(2,"0")}` : "Resend now"}
              </span>
            </div>

            <button
              className="btn btn-primary"
              disabled={!filled}
              onClick={() => filled && onVerify?.()}
              style={{
                width: "100%", height: 56, marginTop: 32,
                opacity: filled ? 1 : 0.5,
                display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
              }}
            >
              Verify & Continue
              <svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor">
                <path d="M12.175 9H0V7h12.175L6.575 1.4 8 0l8 8-8 8-1.425-1.4L12.175 9z"/>
              </svg>
            </button>

            <div style={{ textAlign: "center", marginTop: 24 }}>
              <a style={{ color: "#64748b", fontSize: 14, cursor: "pointer" }}>Use a different phone number</a>
            </div>
          </div>

          {/* security footer */}
          <div style={{ opacity: 0.6, display: "flex", flexDirection: "column", alignItems: "center", gap: 16 }}>
            <div style={{
              padding: "6px 16px",
              borderRadius: 999,
              background: "rgba(255,255,255,0.05)",
              border: "1px solid #2a2a1a",
              display: "flex", alignItems: "center", gap: 8,
              fontSize: 12, color: "#f1f5f9", letterSpacing: "1.2px", fontWeight: 500,
            }}>
              <svg width="12" height="15" viewBox="0 0 12 15" fill="var(--accent)">
                <path d="M6 0L0 2v5c0 4 2.5 7 6 8 3.5-1 6-4 6-8V2L6 0z"/>
              </svg>
              SECURE ENCRYPTED CONNECTION
            </div>
            <div style={{ display: "flex", gap: 24, fontSize: 12, color: "#64748b" }}>
              <span>Privacy Policy</span><span>Terms of Service</span><span>Help Center</span>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};

Object.assign(window, { ScreenLogin, ScreenSMS });
