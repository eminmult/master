// Landing / Home screen — hero + popular services + how it works + why trust
const SERVICE_CATS = [
  { icon: "⚡", title: "Electrician", desc: "Panel upgrades, wiring, lighting, and smart home installs.", popular: true },
  { icon: "🔧", title: "Plumber", desc: "Leak detection, pipe repairs, and full installations." },
  { icon: "🛠", title: "Handyman", desc: "General mounting, furniture assembly & home maintenance." },
  { icon: "❄️", title: "HVAC", desc: "AC repair, furnace maintenance & air quality checks." },
  { icon: "✨", title: "Cleaning", desc: "Deep cleaning, move-out & regular home sanitization." },
  { icon: "🌿", title: "Landscaping", desc: "Lawn care, garden design & tree trimming services." },
  { icon: "🎨", title: "Painting", desc: "Interior/Exterior painting and wallpapering experts." },
  { icon: "🏠", title: "Roofing", desc: "Roof repairs, inspections, and gutter cleaning." },
];

const STEPS = [
  { n: "1", title: "Describe Issue", desc: "Tell us your problem or\nbrowse our services." },
  { n: "2", title: "Instantly Book", desc: "Choose a time slot that fits\nyour busy schedule." },
  { n: "3", title: "Expert Arrives", desc: "A verified pro arrives at your\ndoor on time." },
  { n: "4", title: "Secure Pay", desc: "Pay safely via the app once\nwork is completed." },
];

const TRUST_ITEMS = [
  { icon: "🏆", title: "Vetted Professionals", desc: "Every specialist is background-checked, licensed, and insured. Only the top 5% of applicants make the cut." },
  { icon: "💰", title: "Transparent Pricing", desc: "No hidden fees or surprise costs. See the fixed rate or estimated quote before you hit book." },
  { icon: "⏰", title: "24/7 Premium Support", desc: "Our dedicated concierge team is available around the clock to assist with any request or emergency." },
  { icon: "🛡", title: "Safety Guaranteed", desc: "Your home is protected by our $1M Service Guarantee on every single booking." },
];

const ScreenHome = ({ onNav }) => {
  const [query, setQuery] = React.useState("");
  return (
    <div className="frame" style={{ minHeight: 3120 }}>
      <TopBarPublic active="services" />

      {/* HERO */}
      <section style={{
        padding: "60px 112px 80px",
        display: "flex", flexDirection: "column",
        alignItems: "center", gap: 24,
        position: "relative",
      }}>
        <div style={{
          position: "absolute", inset: 0, pointerEvents: "none",
          overflow: "hidden",
        }}>
          <div className="glow-bg glow-yellow-1" style={{ top: 40, right: 120 }} />
          <div className="glow-bg glow-yellow-2" style={{ top: 280, left: 80 }} />
        </div>

        <div style={{
          padding: "5px 18px",
          borderRadius: 999,
          background: "rgba(255,255,0,0.1)",
          border: "1px solid rgba(255,255,0,0.2)",
          display: "flex", gap: 10, alignItems: "center",
          fontFamily: "Public Sans", fontWeight: 700,
          fontSize: 12, letterSpacing: "1.2px",
          color: "var(--accent)",
          position: "relative",
          zIndex: 1,
        }}>
          <span style={{
            position: "relative",
            width: 8, height: 8, borderRadius: "50%",
            background: "var(--accent)",
            boxShadow: "0 0 0 4px rgba(255,255,0,0.25)",
          }} />
          AVAILABLE 24/7 FOR EMERGENCIES
        </div>

        <h1 className="pub" style={{
          fontSize: 72, lineHeight: 1,
          textAlign: "center", margin: "8px 0 0",
          fontWeight: 700, letterSpacing: "-2px",
          maxWidth: 1100,
          position: "relative", zIndex: 1,
        }}>Professional Home<br/>Services, Just a <span style={{ color: "var(--accent)" }}>Click</span> Away</h1>

        <p style={{
          fontSize: 18, color: "var(--text-slate)",
          textAlign: "center", maxWidth: 680,
          margin: "4px 0 0", lineHeight: 1.6,
          position: "relative", zIndex: 1,
        }}>From emergency repairs to renovation projects, our vetted experts deliver premium service to your doorstep.</p>

        {/* Search */}
        <div style={{
          marginTop: 24,
          width: 1024,
          background: "#18181b",
          border: "1px solid #27272a",
          borderRadius: 16,
          padding: 12,
          display: "flex", gap: 8,
          boxShadow: "0 25px 50px -12px rgba(0,0,0,0.5)",
          position: "relative", zIndex: 1,
        }} className="hero-search">
          <div style={{
            flex: 1,
            background: "rgba(39,39,42,0.5)",
            border: "1px solid rgba(255,255,255,0.05)",
            borderRadius: 12,
            padding: "0 16px",
            display: "flex", gap: 12, alignItems: "center",
          }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" strokeWidth="2">
              <circle cx="11" cy="11" r="8" />
              <line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="What do you need help with today?"
              style={{
                flex: 1, background: "transparent", border: "none", outline: "none",
                color: "var(--text)", fontFamily: "inherit", fontSize: 16,
                padding: "20px 0",
              }}
            />
          </div>
          <div style={{
            width: 280,
            background: "rgba(39,39,42,0.5)",
            border: "1px solid rgba(255,255,255,0.05)",
            borderRadius: 12,
            padding: "0 16px",
            display: "flex", gap: 12, alignItems: "center",
          }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" strokeWidth="2">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" />
              <circle cx="12" cy="10" r="3" />
            </svg>
            <span style={{ color: "var(--text-2)", fontSize: 15, fontWeight: 500 }}>Brooklyn, NY</span>
          </div>
          <button
            onClick={() => onNav?.("specialists")}
            className="btn btn-primary"
            style={{ padding: "0 32px", height: 60, fontSize: 15, borderRadius: 12 }}
          >Find Experts →</button>
        </div>

        {/* Trust indicators */}
        <div style={{
          marginTop: 24, display: "flex", gap: 48,
          fontSize: 13, color: "var(--text-muted)",
          position: "relative", zIndex: 1,
        }}>
          {[
            ["⭐ 4.9/5", "from 50k+ reviews"],
            ["🛡", "Licensed & Insured Pros"],
            ["⚡", "Avg response < 30 min"],
          ].map(([i, t]) => (
            <div key={t} style={{ display: "flex", gap: 8, alignItems: "center" }}>
              <span style={{ fontWeight: 700, color: "var(--text)" }}>{i}</span>{t}
            </div>
          ))}
        </div>
      </section>

      {/* POPULAR SERVICES */}
      <section style={{ padding: "96px 112px", background: "var(--bg-0)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginBottom: 48 }}>
          <div>
            <h2 className="pub" style={{ fontSize: 36, fontWeight: 700, margin: 0, letterSpacing: "-0.5px" }}>Popular Services</h2>
            <p style={{ fontSize: 16, color: "var(--text-slate)", margin: "8px 0 0" }}>Trusted by over 50,000 homeowners this month alone.</p>
          </div>
          <a className="pub" style={{ color: "var(--accent)", fontWeight: 700, display: "flex", gap: 6, alignItems: "center", cursor: "pointer" }}>
            See all <span>→</span>
          </a>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
          {SERVICE_CATS.map((s) => (
            <div key={s.title} style={{
              padding: "28px 24px",
              background: "var(--bg-1)",
              border: "1px solid var(--border-2)",
              borderRadius: 16,
              cursor: "pointer",
              transition: "all 200ms",
              position: "relative",
              minHeight: 220,
              display: "flex", flexDirection: "column",
            }}
              onMouseEnter={(e) => {
                e.currentTarget.style.borderColor = "var(--accent)";
                e.currentTarget.style.transform = "translateY(-4px)";
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.borderColor = "var(--border-2)";
                e.currentTarget.style.transform = "";
              }}
            >
              {s.popular && (
                <span style={{
                  position: "absolute", top: 16, right: 16,
                  fontSize: 10, fontWeight: 700, letterSpacing: "1px",
                  color: "var(--accent)",
                }}>★ POPULAR</span>
              )}
              <div style={{
                width: 52, height: 52, borderRadius: 14,
                background: "rgba(255,255,0,0.1)",
                display: "grid", placeItems: "center",
                fontSize: 26,
                marginBottom: 20,
              }}>{s.icon}</div>
              <h3 className="pub" style={{ fontSize: 18, fontWeight: 700, margin: 0 }}>{s.title}</h3>
              <p style={{ fontSize: 13, color: "var(--text-slate)", margin: "6px 0 0", lineHeight: 1.5, whiteSpace: "pre-line" }}>{s.desc}</p>
              <div style={{ marginTop: "auto", paddingTop: 16, color: "var(--accent)", fontSize: 13, fontWeight: 700, display: "flex", gap: 6, alignItems: "center" }}>
                Book now <span>→</span>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* HOW IT WORKS */}
      <section style={{ padding: "0 112px 96px" }}>
        <div style={{
          background: "#09090b",
          border: "1px solid #18181b",
          borderRadius: 12,
          padding: "96px 64px",
        }}>
          <div style={{ textAlign: "center", marginBottom: 64 }}>
            <h2 className="pub" style={{ fontSize: 48, fontWeight: 700, margin: 0, letterSpacing: "-1px" }}>Simple 4-Step Booking</h2>
            <p style={{ fontSize: 18, color: "var(--text-slate)", margin: "16px auto 0", maxWidth: 640, lineHeight: 1.6 }}>Get your home project started in under 60 seconds. Efficient, transparent, and completely stress-free.</p>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 48, position: "relative" }}>
            <div style={{
              position: "absolute", top: 32, left: "10%", right: "10%",
              borderTop: "1px dashed #3f3f46",
            }} />
            {STEPS.map((s) => (
              <div key={s.n} style={{ textAlign: "center", position: "relative" }}>
                <div style={{
                  width: 64, height: 64, borderRadius: "50%",
                  background: "#09090b",
                  border: "2px solid var(--accent)",
                  display: "grid", placeItems: "center",
                  fontFamily: "Public Sans", fontSize: 24, fontWeight: 700,
                  color: "var(--accent)",
                  margin: "0 auto 20px",
                  position: "relative",
                }}>{s.n}</div>
                <h3 className="pub" style={{ fontSize: 20, fontWeight: 700, margin: 0 }}>{s.title}</h3>
                <p style={{ fontSize: 14, color: "var(--text-slate)", margin: "8px 0 0", lineHeight: 1.6, whiteSpace: "pre-line" }}>{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* WHY TRUST */}
      <section style={{ padding: "0 112px 96px", background: "var(--bg-0)" }}>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 64, alignItems: "center" }}>
          {/* left */}
          <div>
            <h2 className="pub" style={{ fontSize: 48, fontWeight: 700, margin: 0, letterSpacing: "-1px", lineHeight: 1.05 }}>Why Thousands Trust<br/><span style={{ color: "var(--accent)" }}>Handyman</span></h2>
            <div style={{ display: "flex", flexDirection: "column", gap: 28, marginTop: 40 }}>
              {TRUST_ITEMS.map((t) => (
                <div key={t.title} style={{ display: "flex", gap: 20 }}>
                  <div style={{
                    width: 48, height: 48, borderRadius: 14,
                    background: "rgba(255,255,0,0.1)",
                    display: "grid", placeItems: "center",
                    fontSize: 22,
                    flexShrink: 0,
                  }}>{t.icon}</div>
                  <div>
                    <h4 className="pub" style={{ fontSize: 18, fontWeight: 700, margin: 0 }}>{t.title}</h4>
                    <p style={{ fontSize: 14, color: "var(--text-slate)", margin: "6px 0 0", lineHeight: 1.6 }}>{t.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* right — image collage */}
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
            <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
              <div style={{
                height: 256, borderRadius: 16,
                background: "url(" + window.__resources["pro_1_png"] + ") center / cover",
                boxShadow: "0 25px 50px -12px rgba(0,0,0,0.5)",
              }} />
              <div style={{
                height: 192, borderRadius: 16,
                background: "var(--accent)",
                padding: 24,
                display: "flex", flexDirection: "column", justifyContent: "flex-end",
              }}>
                <div className="pub" style={{ fontSize: 36, fontWeight: 700, color: "#000", lineHeight: 1 }}>99%</div>
                <div style={{ fontSize: 14, fontWeight: 700, color: "#000", marginTop: 8 }}>Customer Satisfaction</div>
              </div>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 16, paddingTop: 32 }}>
              <div style={{
                height: 192, borderRadius: 16,
                background: "#27272a",
                padding: 24,
                display: "flex", flexDirection: "column", justifyContent: "flex-end",
              }}>
                <div className="pub" style={{ fontSize: 36, fontWeight: 700, color: "#fff", lineHeight: 1 }}>4.9/5</div>
                <div style={{ fontSize: 14, fontWeight: 700, color: "var(--text-slate)", marginTop: 8 }}>App Store Rating</div>
              </div>
              <div style={{
                height: 256, borderRadius: 16,
                background: "url(" + window.__resources["pro_2_png"] + ") center / cover",
                boxShadow: "0 25px 50px -12px rgba(0,0,0,0.5)",
              }} />
            </div>
          </div>
        </div>
      </section>

      <FooterBar />
    </div>
  );
};

Object.assign(window, { ScreenHome });
