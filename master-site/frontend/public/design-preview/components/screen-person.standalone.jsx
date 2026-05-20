// Person page — specialist detail
const PORTFOLIO_IMAGES = [
  window.__resources["portfolio_1_png"],
  window.__resources["portfolio_2_png"],
  window.__resources["portfolio_3_png"],
  window.__resources["portfolio_4_png"],
];

const REVIEWS = [
  { name: "Jennifer K.", date: "2 weeks ago", rating: 5, text: "Marcus completely rewired our 1920s brownstone. Immaculate work, transparent pricing, and he explained every decision. The kind of craftsperson you keep for life.", avatar: window.__resources["reviewer_1_jpg"], verified: true },
  { name: "David T.", date: "1 month ago", rating: 5, text: "Emergency panel replacement on a Sunday. Marcus was there in 40 minutes and had power restored within three hours. Professional, clean, communicative.", avatar: window.__resources["contact_1_jpg"], verified: true },
  { name: "Priya S.", date: "2 months ago", rating: 4, text: "Solid work on a whole-home smart-lighting install. A small scheduling hiccup early on, but the result is exactly what we wanted. Would book again.", avatar: window.__resources["contact_2_jpg"], verified: true },
];

const ScreenPerson = ({ onNav, onBook }) => {
  const [tab, setTab] = React.useState("reviews");
  const [lightbox, setLightbox] = React.useState(null);

  return (
    <div className="frame" style={{ minHeight: 2200 }}>
      <TopBarLogged active="specialists" onNav={onNav} />

      {/* breadcrumb */}
      <div style={{ padding: "24px 110px 0", fontSize: 14, color: "var(--text-muted)" }}>
        <span style={{ cursor: "pointer" }} onClick={() => onNav?.("specialists")}>Specialists</span>
        <span style={{ margin: "0 8px" }}>›</span>
        <span>Electricians</span>
        <span style={{ margin: "0 8px" }}>›</span>
        <span style={{ color: "var(--text)" }}>Marcus Vane</span>
      </div>

      <main style={{ padding: "32px 110px 80px", display: "grid", gridTemplateColumns: "1fr 400px", gap: 32 }}>
        {/* LEFT */}
        <div style={{ display: "flex", flexDirection: "column", gap: 40 }}>
          {/* Specialist summary */}
          <section style={{
            display: "flex", gap: 32, alignItems: "center",
            paddingBottom: 40, borderBottom: "1px solid var(--border-2)",
          }}>
            <div style={{ position: "relative", width: 96, height: 96, flexShrink: 0 }}>
              <div style={{
                width: 96, height: 96, borderRadius: 24,
                backgroundImage: "url(" + window.__resources["marcus_jpg"] + ")",
                backgroundSize: "cover", backgroundPosition: "center",
                boxShadow: "0 25px 50px -12px rgba(0,0,0,0.25)",
              }} />
              <div style={{
                position: "absolute", right: -8, bottom: -8,
                padding: "4px 10px",
                borderRadius: 999,
                background: "var(--accent)",
                color: "#000",
                fontSize: 10, fontWeight: 700,
                letterSpacing: "0.5px",
              }}>Verified</div>
            </div>

            <div style={{ flex: 1 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "start" }}>
                <h1 style={{ margin: 0, fontSize: 28, fontWeight: 700, color: "#f1f5f9" }}>Marcus Vane</h1>
                <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="var(--accent)">
                    <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                  </svg>
                  <span style={{ fontWeight: 700, fontSize: 14 }}>4.98</span>
                  <span style={{ color: "var(--text-muted)", fontSize: 12 }}>(842 reviews)</span>
                </div>
              </div>
              <div style={{ color: "var(--text-muted)", fontSize: 16, marginTop: 4 }}>Certified Senior Electrical Specialist</div>
              <div style={{ display: "flex", gap: 8, marginTop: 16 }}>
                {["Quick Response", "Licensed & Insured", "10+ Years"].map((t) => (
                  <span key={t} className="chip" style={{ fontSize: 12 }}>{t}</span>
                ))}
              </div>
            </div>
          </section>

          {/* Stat grid */}
          <section style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
            {[
              { v: "842", l: "Reviews", a: "var(--accent)" },
              { v: "98%", l: "On-Time Rate", a: "#fff" },
              { v: "< 15m", l: "Response", a: "#fff" },
              { v: "10yr", l: "Experience", a: "#fff" },
            ].map((s) => (
              <div key={s.l} style={{
                background: "rgba(255,255,255,0.02)",
                border: "1px solid var(--border-2)",
                borderRadius: 16,
                padding: 20,
              }}>
                <div style={{ fontSize: 32, fontWeight: 700, color: s.a, letterSpacing: "-0.5px" }}>{s.v}</div>
                <div style={{ fontSize: 12, color: "var(--text-muted)", letterSpacing: "0.5px", marginTop: 4 }}>{s.l}</div>
              </div>
            ))}
          </section>

          {/* About */}
          <section>
            <h2 style={{ fontSize: 14, fontWeight: 700, letterSpacing: "1.4px", color: "var(--text-3)", textTransform: "uppercase", margin: "0 0 16px" }}>About</h2>
            <p style={{ fontSize: 15, color: "var(--text-2)", lineHeight: 1.7, margin: 0 }}>
              Master electrician with a focus on heritage wiring, panel upgrades, and whole-home smart systems. I treat every job like it's my own house — clean routing, labeled runs, honest pricing. Licensed in three states; primary service area is Brooklyn and lower Manhattan.
            </p>
          </section>

          {/* Specialties */}
          <section>
            <h2 style={{ fontSize: 14, fontWeight: 700, letterSpacing: "1.4px", color: "var(--text-3)", textTransform: "uppercase", margin: "0 0 16px" }}>Specialties</h2>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12 }}>
              {[
                "Panel Upgrades", "EV Charger Install", "Smart Home Wiring",
                "Heritage Rewiring", "Emergency Service", "Lighting Design",
              ].map((s) => (
                <div key={s} style={{
                  padding: "14px 16px",
                  background: "rgba(255,255,255,0.03)",
                  border: "1px solid var(--border-2)",
                  borderRadius: 12,
                  display: "flex", gap: 10, alignItems: "center",
                  fontSize: 14,
                }}>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="var(--accent)"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/></svg>
                  {s}
                </div>
              ))}
            </div>
          </section>

          {/* Tabs: Portfolio / Reviews / Credentials */}
          <section>
            <div style={{
              display: "flex", gap: 4,
              padding: 4,
              background: "var(--bg-2)",
              borderRadius: 999,
              width: "fit-content",
              marginBottom: 24,
            }}>
              {[
                { k: "portfolio", l: "Portfolio" },
                { k: "reviews", l: "Reviews (842)" },
                { k: "credentials", l: "Credentials" },
              ].map((t) => (
                <button
                  key={t.k}
                  onClick={() => setTab(t.k)}
                  className="btn"
                  style={{
                    padding: "10px 20px",
                    background: tab === t.k ? "var(--accent)" : "transparent",
                    color: tab === t.k ? "#000" : "var(--text-2)",
                    fontSize: 14,
                    fontWeight: tab === t.k ? 700 : 500,
                  }}
                >{t.l}</button>
              ))}
            </div>

            {tab === "portfolio" && (
              <div style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: 16 }}>
                {PORTFOLIO_IMAGES.map((img, i) => (
                  <div
                    key={i}
                    onClick={() => setLightbox(img)}
                    style={{
                      position: "relative",
                      aspectRatio: "4/3",
                      borderRadius: 16,
                      backgroundImage: `url(${img})`,
                      backgroundSize: "cover",
                      backgroundPosition: "center",
                      cursor: "pointer",
                      overflow: "hidden",
                    }}>
                    <div style={{
                      position: "absolute", inset: 0,
                      background: "linear-gradient(to top, rgba(0,0,0,0.6), transparent 50%)",
                    }} />
                    <div style={{ position: "absolute", bottom: 16, left: 16, fontSize: 14, fontWeight: 700 }}>Project {i+1}</div>
                  </div>
                ))}
              </div>
            )}

            {tab === "reviews" && (
              <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
                {REVIEWS.map((r, i) => (
                  <div key={i} style={{
                    padding: 24,
                    background: "rgba(255,255,255,0.02)",
                    border: "1px solid var(--border-2)",
                    borderRadius: 16,
                  }}>
                    <div style={{ display: "flex", gap: 16, marginBottom: 12 }}>
                      <div style={{
                        width: 44, height: 44,
                        borderRadius: "50%",
                        backgroundImage: `url(${r.avatar})`,
                        backgroundSize: "cover",
                      }} />
                      <div style={{ flex: 1 }}>
                        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                          <div>
                            <div style={{ fontWeight: 700, fontSize: 14, display: "flex", alignItems: "center", gap: 8 }}>
                              {r.name}
                              {r.verified && (
                                <span style={{ fontSize: 10, color: "var(--accent)", letterSpacing: "0.5px" }}>✓ VERIFIED</span>
                              )}
                            </div>
                            <div style={{ fontSize: 12, color: "var(--text-muted)" }}>{r.date}</div>
                          </div>
                          <StarRow rating={r.rating} size={12} />
                        </div>
                      </div>
                    </div>
                    <p style={{ margin: 0, color: "var(--text-2)", fontSize: 14, lineHeight: 1.6 }}>{r.text}</p>
                  </div>
                ))}
                <button className="btn btn-ghost" style={{ alignSelf: "center", padding: "12px 28px" }}>Show all 842 reviews</button>
              </div>
            )}

            {tab === "credentials" && (
              <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                {[
                  { t: "NYC Master Electrician License", d: "Valid through Jun 2028 · #E-42198" },
                  { t: "OSHA 30-Hour Safety Certification", d: "Valid through Mar 2027" },
                  { t: "$2M Liability Insurance", d: "Continuously verified by Handyman" },
                  { t: "Background Check Cleared", d: "Last run Jan 2026" },
                ].map((c) => (
                  <div key={c.t} style={{
                    padding: "18px 20px",
                    background: "rgba(255,255,255,0.02)",
                    border: "1px solid var(--border-2)",
                    borderRadius: 12,
                    display: "flex", gap: 14, alignItems: "center",
                  }}>
                    <div style={{
                      width: 40, height: 40,
                      borderRadius: 12,
                      background: "rgba(255,255,0,0.1)",
                      display: "grid", placeItems: "center",
                    }}>
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" strokeWidth="2">
                        <path d="M12 2L4 5v6c0 5 3.5 9 8 11 4.5-2 8-6 8-11V5l-8-3z" />
                        <path d="M9 12l2 2 4-4" />
                      </svg>
                    </div>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: 14 }}>{c.t}</div>
                      <div style={{ fontSize: 12, color: "var(--text-muted)" }}>{c.d}</div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </section>
        </div>

        {/* RIGHT — sticky booking card */}
        <aside>
          <div style={{
            position: "sticky", top: 100,
            background: "var(--bg-1)",
            border: "1px solid var(--border-2)",
            borderRadius: 24,
            padding: 28,
            boxShadow: "0 25px 50px -12px rgba(0,0,0,0.3)",
          }}>
            <div style={{ display: "flex", alignItems: "baseline", gap: 6, marginBottom: 4 }}>
              <div style={{ fontSize: 40, fontWeight: 700, letterSpacing: "-1px" }}>$180</div>
              <div style={{ color: "var(--text-muted)", fontSize: 14 }}>/ hour</div>
            </div>
            <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 20 }}>+ materials at cost · 1hr minimum</div>

            <div style={{
              display: "flex", alignItems: "center", gap: 8,
              padding: "10px 14px",
              background: "rgba(34,197,94,0.1)",
              border: "1px solid rgba(34,197,94,0.3)",
              borderRadius: 999,
              fontSize: 13, fontWeight: 500,
              marginBottom: 20,
            }}>
              <span style={{ width: 8, height: 8, borderRadius: "50%", background: "#22c55e", boxShadow: "0 0 8px #22c55e" }} />
              Available today · next slot 2:30 PM
            </div>

            <button className="btn btn-primary" onClick={onBook} style={{ width: "100%", marginBottom: 12 }}>Book Marcus</button>
            <button className="btn btn-ghost" style={{ width: "100%", marginBottom: 24 }}>Message First</button>

            <div style={{ borderTop: "1px solid var(--border-2)", paddingTop: 20, display: "flex", flexDirection: "column", gap: 12, fontSize: 13, color: "var(--text-2)" }}>
              {[
                ["💳", "Pay only after completion"],
                ["🔒", "100% satisfaction guarantee"],
                ["⚡", "Typically responds < 15 min"],
              ].map(([i, t]) => (
                <div key={t} style={{ display: "flex", gap: 10, alignItems: "center" }}>
                  <span style={{ width: 20, textAlign: "center" }}>{i}</span>{t}
                </div>
              ))}
            </div>
          </div>
        </aside>
      </main>

      <FooterBar />

      {lightbox && (
        <div
          onClick={() => setLightbox(null)}
          style={{
            position: "fixed", inset: 0,
            background: "rgba(0,0,0,0.92)", backdropFilter: "blur(8px)",
            display: "grid", placeItems: "center", zIndex: 100,
            cursor: "zoom-out",
          }}>
          <img src={lightbox} style={{ maxWidth: "80%", maxHeight: "80%", borderRadius: 16 }} />
        </div>
      )}
    </div>
  );
};

Object.assign(window, { ScreenPerson });
