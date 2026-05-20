// Booking screen — checkout-style flow
const SERVICES = [
  { id: "panel", title: "Panel Upgrade", desc: "100A → 200A service upgrade with permit", price: 1450, dur: "6-8 hrs", popular: true },
  { id: "rewire", title: "Partial Rewiring", desc: "Room-level rewire, up to 4 circuits", price: 890, dur: "4-5 hrs" },
  { id: "smart", title: "Smart Home Wiring", desc: "Consultation + first-room install", price: 620, dur: "3-4 hrs" },
  { id: "ev", title: "EV Charger Install", desc: "Level-2 charger, dedicated circuit", price: 780, dur: "3-4 hrs" },
];

const ScreenBooking = ({ onNav, onConfirm }) => {
  const [selected, setSelected] = React.useState("panel");
  const [date, setDate] = React.useState(14);
  const [time, setTime] = React.useState("2:30 PM");
  const [address, setAddress] = React.useState("124 Atlantic Ave");
  const [notes, setNotes] = React.useState("");
  const [payment, setPayment] = React.useState("card");

  const svc = SERVICES.find(s => s.id === selected);
  const fee = 25;
  const tax = Math.round(svc.price * 0.08);

  const days = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
  const labels = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun","Mon","Tue","Wed","Thu","Fri","Sat","Sun"];
  const times = ["9:00 AM", "11:00 AM", "2:30 PM", "4:30 PM", "6:00 PM"];

  return (
    <div className="frame" style={{ minHeight: 2259 }}>
      <TopBarLogged active="specialists" onNav={onNav} />

      <div style={{ padding: "24px 110px 0", fontSize: 14, color: "var(--text-muted)" }}>
        <span style={{ cursor: "pointer" }} onClick={() => onNav?.("specialists")}>Specialists</span>
        <span style={{ margin: "0 8px" }}>›</span>
        <span style={{ cursor: "pointer" }} onClick={() => onNav?.("person")}>Electricians</span>
        <span style={{ margin: "0 8px" }}>›</span>
        <span style={{ color: "var(--text)" }}>Marcus V.</span>
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
                backgroundImage: "url(assets/marcus.jpg)",
                backgroundSize: "cover", backgroundPosition: "center",
              }} />
              <div style={{
                position: "absolute", right: -8, bottom: -8,
                padding: "4px 10px",
                borderRadius: 999,
                background: "var(--accent)", color: "#000",
                fontSize: 10, fontWeight: 700,
              }}>Verified</div>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <h2 style={{ margin: 0, fontSize: 24, fontWeight: 700 }}>Marcus Vane</h2>
                <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="var(--accent)"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
                  <span style={{ fontWeight: 700, fontSize: 14 }}>4.98</span>
                  <span style={{ fontSize: 12, color: "var(--text-muted)" }}>(842)</span>
                </div>
              </div>
              <div style={{ color: "var(--text-muted)", fontSize: 16, marginTop: 4 }}>Certified Senior Electrical Specialist</div>
              <div style={{ display: "flex", gap: 8, marginTop: 12 }}>
                {["Quick Response", "Licensed"].map((t) => (
                  <span key={t} className="chip">{t}</span>
                ))}
              </div>
            </div>
          </section>

          {/* 1. Service */}
          <section>
            <h3 style={{ fontSize: 13, fontWeight: 700, letterSpacing: "1.4px", color: "var(--text-3)", textTransform: "uppercase", margin: "0 0 20px" }}>
              <span style={{ color: "var(--accent)" }}>01.</span> Select Service
            </h3>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
              {SERVICES.map((s) => (
                <button
                  key={s.id}
                  onClick={() => setSelected(s.id)}
                  className="btn"
                  style={{
                    padding: 20,
                    textAlign: "left",
                    background: selected === s.id ? "rgba(255,255,0,0.08)" : "rgba(255,255,255,0.02)",
                    border: selected === s.id ? "1px solid var(--accent)" : "1px solid var(--border-2)",
                    borderRadius: 16,
                    display: "flex", flexDirection: "column", gap: 6,
                    fontFamily: "inherit",
                    position: "relative",
                  }}>
                  {s.popular && (
                    <span style={{
                      position: "absolute", top: 14, right: 14,
                      fontSize: 10, color: "var(--accent)", fontWeight: 700, letterSpacing: "0.5px",
                    }}>★ POPULAR</span>
                  )}
                  <div style={{ fontSize: 16, fontWeight: 700, color: "var(--text)" }}>{s.title}</div>
                  <div style={{ fontSize: 13, color: "var(--text-muted)", fontWeight: 400 }}>{s.desc}</div>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 12 }}>
                    <span style={{ fontSize: 20, fontWeight: 700, color: "var(--text)" }}>${s.price}</span>
                    <span style={{ fontSize: 12, color: "var(--text-muted)" }}>· {s.dur}</span>
                  </div>
                </button>
              ))}
            </div>
          </section>

          {/* 2. Date */}
          <section>
            <h3 style={{ fontSize: 13, fontWeight: 700, letterSpacing: "1.4px", color: "var(--text-3)", textTransform: "uppercase", margin: "0 0 20px" }}>
              <span style={{ color: "var(--accent)" }}>02.</span> Choose Date & Time
            </h3>

            <div style={{
              background: "rgba(255,255,255,0.02)",
              border: "1px solid var(--border-2)",
              borderRadius: 20,
              padding: 24,
            }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
                <div style={{ fontSize: 16, fontWeight: 700 }}>March 2026</div>
                <div style={{ display: "flex", gap: 8 }}>
                  <button className="btn" style={{ width: 32, height: 32, borderRadius: "50%", background: "var(--bg-2)", color: "var(--text)", display: "grid", placeItems: "center" }}>‹</button>
                  <button className="btn" style={{ width: 32, height: 32, borderRadius: "50%", background: "var(--bg-2)", color: "var(--text)", display: "grid", placeItems: "center" }}>›</button>
                </div>
              </div>

              <div style={{
                display: "grid", gridTemplateColumns: "repeat(7, 1fr)",
                gap: 8,
              }}>
                {days.map((d, i) => (
                  <button
                    key={d}
                    onClick={() => setDate(d)}
                    className="btn"
                    style={{
                      aspectRatio: "1",
                      borderRadius: 12,
                      background: date === d ? "var(--accent)" : "transparent",
                      color: date === d ? "#000" : "var(--text)",
                      border: date === d ? "none" : "1px solid var(--border-2)",
                      display: "flex", flexDirection: "column",
                      alignItems: "center", justifyContent: "center",
                      gap: 2,
                    }}
                  >
                    <span style={{ fontSize: 10, opacity: 0.7 }}>{labels[i]}</span>
                    <span style={{ fontSize: 16, fontWeight: 700 }}>{d}</span>
                  </button>
                ))}
              </div>

              <div style={{ marginTop: 24, paddingTop: 24, borderTop: "1px solid var(--border-2)" }}>
                <div style={{ fontSize: 13, color: "var(--text-muted)", marginBottom: 12 }}>Available times for March {date}</div>
                <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                  {times.map((t) => (
                    <button
                      key={t}
                      onClick={() => setTime(t)}
                      className="btn"
                      style={{
                        padding: "10px 20px",
                        borderRadius: 999,
                        background: time === t ? "var(--accent)" : "transparent",
                        color: time === t ? "#000" : "var(--text)",
                        border: time === t ? "none" : "1px solid var(--border-2)",
                        fontWeight: time === t ? 700 : 500,
                        fontSize: 13,
                      }}>{t}</button>
                  ))}
                </div>
              </div>
            </div>
          </section>

          {/* 3. Address */}
          <section>
            <h3 style={{ fontSize: 13, fontWeight: 700, letterSpacing: "1.4px", color: "var(--text-3)", textTransform: "uppercase", margin: "0 0 20px" }}>
              <span style={{ color: "var(--accent)" }}>03.</span> Service Address
            </h3>
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              <input
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                style={{
                  width: "100%",
                  padding: "16px 20px",
                  background: "rgba(255,255,255,0.02)",
                  border: "1px solid var(--border-2)",
                  borderRadius: 16,
                  color: "var(--text)", fontFamily: "inherit", fontSize: 15,
                }}
              />
              <div style={{
                height: 180,
                borderRadius: 16,
                background: "url(assets/booking-bg.jpg) center / cover",
                border: "1px solid var(--border-2)",
                position: "relative",
                overflow: "hidden",
              }}>
                <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to top, rgba(0,0,0,0.5), transparent 60%)" }} />
                <div style={{
                  position: "absolute", left: "50%", top: "45%",
                  transform: "translate(-50%, -50%)",
                  width: 32, height: 32, borderRadius: "50%",
                  background: "var(--accent)",
                  boxShadow: "0 0 0 8px rgba(255,255,0,0.25)",
                  display: "grid", placeItems: "center",
                  color: "#000", fontWeight: 700, fontSize: 14,
                }}>📍</div>
                <div style={{ position: "absolute", bottom: 16, left: 16, fontSize: 13, fontWeight: 500 }}>
                  {address}, Brooklyn, NY 11217
                </div>
              </div>
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Unit # or access notes (optional)"
                rows={2}
                style={{
                  width: "100%",
                  padding: "14px 20px",
                  background: "rgba(255,255,255,0.02)",
                  border: "1px solid var(--border-2)",
                  borderRadius: 16,
                  color: "var(--text)", fontFamily: "inherit", fontSize: 14,
                  resize: "none",
                }}
              />
            </div>
          </section>

          {/* 4. Payment */}
          <section>
            <h3 style={{ fontSize: 13, fontWeight: 700, letterSpacing: "1.4px", color: "var(--text-3)", textTransform: "uppercase", margin: "0 0 20px" }}>
              <span style={{ color: "var(--accent)" }}>04.</span> Payment Method
            </h3>
            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              {[
                { k: "card", l: "Visa ending in 4242", sub: "Expires 08/28", icon: "💳" },
                { k: "apple", l: "Apple Pay", sub: "Quick & secure", icon: "" },
                { k: "add",  l: "+ Add new payment method", sub: null, icon: null },
              ].map((p) => (
                <button
                  key={p.k}
                  onClick={() => p.k !== "add" && setPayment(p.k)}
                  className="btn"
                  style={{
                    padding: "14px 20px",
                    background: payment === p.k ? "rgba(255,255,0,0.08)" : "rgba(255,255,255,0.02)",
                    border: payment === p.k ? "1px solid var(--accent)" : "1px solid var(--border-2)",
                    borderRadius: 16,
                    display: "flex", justifyContent: "space-between", alignItems: "center",
                    fontFamily: "inherit",
                    textAlign: "left",
                  }}>
                  <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
                    {p.icon && <span style={{ fontSize: 24 }}>{p.icon}</span>}
                    <div>
                      <div style={{ fontWeight: 700, fontSize: 14, color: p.k === "add" ? "var(--accent)" : "var(--text)" }}>{p.l}</div>
                      {p.sub && <div style={{ fontSize: 12, color: "var(--text-muted)" }}>{p.sub}</div>}
                    </div>
                  </div>
                  {payment === p.k && p.k !== "add" && (
                    <span style={{ width: 18, height: 18, borderRadius: "50%", background: "var(--accent)", display: "grid", placeItems: "center" }}>
                      <svg width="10" height="8" viewBox="0 0 10 8"><path d="M1 4l3 3 5-6" stroke="#000" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
                    </span>
                  )}
                </button>
              ))}
            </div>
          </section>
        </div>

        {/* RIGHT — sticky summary */}
        <aside>
          <div style={{
            position: "sticky", top: 100,
            background: "var(--bg-1)",
            border: "1px solid var(--border-2)",
            borderRadius: 24,
            padding: 28,
          }}>
            <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: "1.4px", color: "var(--text-3)", textTransform: "uppercase", marginBottom: 20 }}>Booking Summary</div>

            <div style={{ display: "flex", flexDirection: "column", gap: 16, paddingBottom: 20, borderBottom: "1px dashed var(--border-2)" }}>
              <SummaryRow icon="🛠" label="Service" value={svc.title} />
              <SummaryRow icon="📅" label="Date" value={`March ${date}, 2026 · ${time}`} />
              <SummaryRow icon="📍" label="Address" value={address} />
              <SummaryRow icon="⏱" label="Duration" value={svc.dur} />
            </div>

            <div style={{ padding: "20px 0", display: "flex", flexDirection: "column", gap: 10, borderBottom: "1px dashed var(--border-2)" }}>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 14, color: "var(--text-2)" }}>
                <span>{svc.title}</span><span>${svc.price}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 14, color: "var(--text-2)" }}>
                <span>Service fee</span><span>${fee}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 14, color: "var(--text-2)" }}>
                <span>Estimated tax</span><span>${tax}</span>
              </div>
            </div>

            <div style={{ padding: "20px 0", display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
              <span style={{ fontSize: 14, fontWeight: 700, letterSpacing: "0.5px" }}>TOTAL</span>
              <div style={{ textAlign: "right" }}>
                <div style={{ fontSize: 32, fontWeight: 700, letterSpacing: "-1px", color: "var(--accent)" }}>${svc.price + fee + tax}</div>
                <div style={{ fontSize: 11, color: "var(--text-muted)" }}>Charged after completion</div>
              </div>
            </div>

            <button onClick={onConfirm} className="btn btn-primary" style={{ width: "100%" }}>
              Confirm Booking
            </button>
            <div style={{ textAlign: "center", fontSize: 11, color: "var(--text-muted)", marginTop: 12, lineHeight: 1.5 }}>
              By booking you agree to our Terms<br/>Cancel free up to 2 hours before
            </div>
          </div>
        </aside>
      </main>

      <FooterBar />
    </div>
  );
};

const SummaryRow = ({ icon, label, value }) => (
  <div style={{ display: "flex", gap: 12, alignItems: "flex-start" }}>
    <span style={{ width: 20, textAlign: "center" }}>{icon}</span>
    <div style={{ flex: 1 }}>
      <div style={{ fontSize: 11, color: "var(--text-muted)", letterSpacing: "0.5px", textTransform: "uppercase" }}>{label}</div>
      <div style={{ fontSize: 14, fontWeight: 500, color: "var(--text)", marginTop: 2 }}>{value}</div>
    </div>
  </div>
);

Object.assign(window, { ScreenBooking });
