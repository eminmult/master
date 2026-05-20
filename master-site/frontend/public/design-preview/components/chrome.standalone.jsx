// Shared chrome for Handyman desktop screens
// Defines: Logo, TopBarPublic, TopBarLogged, Footer, StarRow, Icon (lightweight), exported to window.

const Logo = ({ size = 24 }) => (
  <div className="logo" style={{ fontSize: size }}>
    <div className="logo-mark" style={{ width: size * 1.33, height: size * 1.42 }}>
      <svg width={size * 0.8} height={size * 0.92} viewBox="0 0 19 22">
        <path d="M 8.175 16.625 L 12.875 10.9 L 9.125 10.9 L 9.75 5.95 L 5.55 12 L 8.85 12 L 8.175 16.625 M 4.5 21.9 L 5.5 14.9 L 0 14.9 L 10.325 0 L 13.4 0 L 12.4 8 L 19.075 8 L 7.55 21.9 L 4.5 21.9" />
      </svg>
    </div>
    <span>Handyman</span>
  </div>
);

const TopBarPublic = ({ active }) => (
  <header className="topbar">
    <Logo />
    <nav className="nav">
      <a className={active === "services" ? "active" : ""}>Services</a>
      <a className={active === "how" ? "active" : ""}>How it Works</a>
      <a className={active === "pros" ? "active" : ""}>For Pros</a>
      <a>Login</a>
      <a className="cta">Book a Service</a>
    </nav>
  </header>
);

const TopBarLogged = ({ active = "specialists", onNav, user }) => (
  <header className="topbar">
    <div style={{ display: "flex", gap: 48, alignItems: "center" }}>
      <Logo />
      <nav className="nav" style={{ gap: 28 }}>
        <a className={active === "specialists" ? "active" : ""} onClick={() => onNav?.("specialists")}>Specialists</a>
        <a className={active === "messages" ? "active" : ""} onClick={() => onNav?.("chat")}>Messages</a>
        <a className={active === "requests" ? "active" : ""}>My Requests</a>
      </nav>
    </div>
    <div className="nav-right">
      <div className="bell">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9" />
          <path d="M13.73 21a2 2 0 0 1-3.46 0" />
        </svg>
        <span className="dot" />
      </div>
      <div className="profile-chip">
        <div style={{ textAlign: "right" }}>
          <div className="name">{user?.name || "Julianne Moore"}</div>
          <div className="role">{user?.role || "Member"}</div>
        </div>
        <div className="avatar" style={{ backgroundImage: `url(${user?.avatar || window.__resources["julianne_jpg"]})` }} />
      </div>
    </div>
  </header>
);

const StarRow = ({ rating = 5, size = 14, color = "var(--accent)" }) => (
  <div style={{ display: "inline-flex", gap: 2 }}>
    {[0,1,2,3,4].map((i) => (
      <svg key={i} width={size} height={size} viewBox="0 0 24 24" fill={i < Math.round(rating) ? color : "rgba(255,255,255,0.15)"}>
        <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
      </svg>
    ))}
  </div>
);

const FooterBar = () => (
  <footer style={{
    background: "var(--bg-3, #09090b)",
    borderTop: "1px solid var(--border-2)",
    padding: "96px 142px 48px",
    color: "var(--text-2)",
  }}>
    <div style={{ display: "grid", gridTemplateColumns: "1.3fr 1fr 1fr 1fr", gap: 48 }}>
      <div>
        <Logo />
        <p style={{ fontSize: 14, color: "var(--text-3)", lineHeight: 1.6, marginTop: 16, maxWidth: 260 }}>
          Premium on-demand home services. Verified specialists, transparent pricing.
        </p>
      </div>
      {[
        { h: "Services", items: ["Electrical", "Plumbing", "HVAC", "Cleaning"] },
        { h: "Company", items: ["About", "Careers", "Press", "Contact"] },
        { h: "Support", items: ["Help Center", "Trust & Safety", "Terms", "Privacy"] },
      ].map((col, i) => (
        <div key={i}>
          <div style={{
            fontSize: 12, letterSpacing: "1.2px", fontWeight: 700,
            color: "var(--text)", textTransform: "uppercase", marginBottom: 20,
          }}>{col.h}</div>
          {col.items.map((it) => (
            <div key={it} style={{ fontSize: 14, marginBottom: 10, color: "var(--text-3)", cursor: "pointer" }}>{it}</div>
          ))}
        </div>
      ))}
    </div>
    <div style={{
      display: "flex", justifyContent: "space-between",
      marginTop: 64, paddingTop: 32, borderTop: "1px solid var(--border-2)",
      fontSize: 12, color: "var(--text-3)", letterSpacing: "1px",
    }}>
      <div>© 2026 HANDYMAN PREMIUM SERVICES</div>
      <div style={{ display: "flex", gap: 24 }}>
        <span>Terms of Service</span>
        <span>Privacy Policy</span>
        <span>Help Center</span>
      </div>
    </div>
  </footer>
);

Object.assign(window, { Logo, TopBarPublic, TopBarLogged, StarRow, FooterBar });
