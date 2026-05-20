// Chat screen — 3-column: contacts / thread / details
const CONTACTS = [
  { id: 1, name: "Alex Rivera", role: "HVAC Specialist", last: "En route to your location", time: "10:45 AM", avatar: window.__resources["alex_rivera_jpg"], online: true, active: true, unread: 0 },
  { id: 2, name: "Sarah Chen", role: "Senior Electrician", last: "Got it — see you at 2pm", time: "9:12 AM", avatar: window.__resources["sarah_chen_jpg"], online: false, unread: 2 },
  { id: 3, name: "Ethan Park", role: "Master Plumber", last: "I can swing by tomorrow", time: "Yesterday", avatar: window.__resources["contact_1_jpg"], online: true, unread: 0 },
  { id: 4, name: "Sophia Lane", role: "Cleaning Lead", last: "Thanks! Review posted ✓", time: "Mon", avatar: window.__resources["contact_2_jpg"], online: false, unread: 0 },
  { id: 5, name: "Noah Hartwell", role: "Electrician", last: "Quote attached — $320 all in", time: "Mar 10", avatar: window.__resources["contact_3_jpg"], online: false, unread: 1 },
  { id: 6, name: "Marcus Vane", role: "Electrical Specialist", last: "Booking confirmed for Wed", time: "Mar 8", avatar: window.__resources["marcus_jpg"], online: true, unread: 0 },
];

const MESSAGES = [
  { from: "them", text: "Hey Julianne — I'm about 10 minutes out. Parking on Atlantic or should I use the driveway?", time: "10:32 AM" },
  { from: "me", text: "Driveway is clear, you can pull right in. Side door is unlocked.", time: "10:34 AM" },
  { from: "them", text: "Perfect. I'll take a quick look at the unit and give you a full diagnostic before we touch anything.", time: "10:35 AM" },
  { from: "me", text: "Sounds good. Just so you know — the thermostat has been cycling on and off every 20 min or so since Friday.", time: "10:38 AM" },
  { from: "them", text: "Noted. That usually points to either a filter clog or a sensor issue. I brought spares for both. 🔧", time: "10:41 AM" },
  { from: "them", text: "En route to your location", time: "10:45 AM", status: true },
];

const ScreenChat = ({ onNav }) => {
  const [active, setActive] = React.useState(1);
  const [tab, setTab] = React.useState("all");
  const [input, setInput] = React.useState("");
  const [messages, setMessages] = React.useState(MESSAGES);

  const contact = CONTACTS.find(c => c.id === active);

  const send = () => {
    if (!input.trim()) return;
    setMessages([...messages, { from: "me", text: input.trim(), time: "now" }]);
    setInput("");
  };

  return (
    <div className="frame" style={{ minHeight: 1024, height: 1024 }}>
      <TopBarLogged active="messages" onNav={onNav} />

      <div style={{ display: "grid", gridTemplateColumns: "384px 1fr 320px", height: 943 }}>
        {/* LEFT — contacts */}
        <aside style={{
          background: "var(--bg-2)",
          borderRight: "1px solid var(--border)",
          display: "flex", flexDirection: "column",
        }}>
          <div style={{ padding: 16, borderBottom: "1px solid var(--border-2)" }}>
            <div style={{
              position: "relative",
              background: "var(--bg-4)",
              borderRadius: 999,
              padding: "12px 16px 12px 40px",
              marginBottom: 16,
            }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.4)" strokeWidth="2" style={{ position: "absolute", left: 14, top: "50%", transform: "translateY(-50%)" }}>
                <circle cx="11" cy="11" r="8" />
                <line x1="21" y1="21" x2="16.65" y2="16.65" />
              </svg>
              <input
                placeholder="Search specialists..."
                style={{
                  background: "transparent", border: "none", outline: "none",
                  color: "var(--text)", fontFamily: "inherit", fontSize: 14,
                  width: "100%",
                }}
              />
            </div>
            <div style={{ display: "flex", gap: 8 }}>
              {[
                { k: "all", l: "All" },
                { k: "ongoing", l: "Ongoing" },
                { k: "completed", l: "Completed" },
                { k: "quotes", l: "Quotes" },
              ].map((t) => (
                <button
                  key={t.k}
                  onClick={() => setTab(t.k)}
                  className="btn"
                  style={{
                    padding: "6px 14px", fontSize: 12,
                    borderRadius: 999,
                    background: tab === t.k ? "var(--accent)" : "var(--bg-4)",
                    color: tab === t.k ? "#000" : "var(--text-2)",
                    fontWeight: tab === t.k ? 700 : 500,
                  }}>{t.l}</button>
              ))}
            </div>
          </div>

          <div className="scroll-col" style={{ flex: 1 }}>
            {CONTACTS.map((c) => (
              <button
                key={c.id}
                onClick={() => setActive(c.id)}
                className="btn"
                style={{
                  width: "100%",
                  padding: "16px",
                  background: active === c.id ? "rgba(255,255,0,0.1)" : "transparent",
                  border: active === c.id ? "1px solid var(--accent)" : "1px solid transparent",
                  borderLeft: "none", borderRight: "none",
                  borderRadius: 0,
                  display: "flex", gap: 14, alignItems: "center",
                  fontFamily: "inherit", textAlign: "left",
                }}>
                <div style={{ position: "relative", width: 48, height: 48, flexShrink: 0 }}>
                  <div style={{
                    width: 48, height: 48, borderRadius: "50%",
                    backgroundImage: `url(${c.avatar})`,
                    backgroundSize: "cover",
                  }} />
                  <div style={{
                    position: "absolute", right: 0, bottom: 0,
                    width: 14, height: 14, borderRadius: "50%",
                    background: c.online ? "#22c55e" : "rgba(255,255,255,0.2)",
                    border: "2px solid var(--bg-2)",
                  }} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 2 }}>
                    <span style={{ fontSize: 14, fontWeight: 700, color: "var(--text)" }}>{c.name}</span>
                    <span style={{ fontSize: 10, color: active === c.id ? "var(--accent)" : "var(--text-3)", fontWeight: 700 }}>{c.time}</span>
                  </div>
                  <div style={{ fontSize: 12, color: "var(--text-3)", marginBottom: 4 }}>{c.role}</div>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                    <span style={{
                      fontSize: 12, color: "var(--text-2)",
                      whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
                      maxWidth: 220, fontWeight: c.unread > 0 ? 700 : 500,
                    }}>{c.last}</span>
                    {c.unread > 0 && (
                      <span style={{
                        minWidth: 18, height: 18, padding: "0 6px",
                        borderRadius: 999,
                        background: "var(--accent)", color: "#000",
                        fontSize: 10, fontWeight: 700,
                        display: "grid", placeItems: "center",
                      }}>{c.unread}</span>
                    )}
                  </div>
                </div>
              </button>
            ))}
          </div>
        </aside>

        {/* MIDDLE — thread */}
        <section style={{
          display: "flex", flexDirection: "column",
          background: "var(--bg-0)",
          backgroundImage: "radial-gradient(circle at 20% 20%, rgba(255,255,0,0.03), transparent 50%)",
        }}>
          {/* header */}
          <div style={{
            padding: "16px 24px",
            borderBottom: "1px solid var(--border)",
            display: "flex", justifyContent: "space-between", alignItems: "center",
          }}>
            <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
              <div style={{
                width: 44, height: 44, borderRadius: "50%",
                backgroundImage: `url(${contact.avatar})`,
                backgroundSize: "cover",
              }} />
              <div>
                <div style={{ fontSize: 15, fontWeight: 700 }}>{contact.name}</div>
                <div style={{ fontSize: 12, color: "#22c55e", display: "flex", alignItems: "center", gap: 6 }}>
                  <span style={{ width: 6, height: 6, borderRadius: "50%", background: "#22c55e" }} />
                  {contact.online ? "Online · typing..." : "Offline"}
                </div>
              </div>
            </div>
            <div style={{ display: "flex", gap: 8 }}>
              <IconBtn>📞</IconBtn>
              <IconBtn>📹</IconBtn>
              <IconBtn>⋯</IconBtn>
            </div>
          </div>

          {/* booking banner */}
          <div style={{
            margin: "16px 24px 0",
            padding: "14px 20px",
            background: "rgba(255,255,0,0.08)",
            border: "1px solid rgba(255,255,0,0.3)",
            borderRadius: 16,
            display: "flex", justifyContent: "space-between", alignItems: "center",
          }}>
            <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
              <div style={{
                width: 36, height: 36, borderRadius: 12,
                background: "var(--accent)",
                display: "grid", placeItems: "center",
                fontSize: 18,
              }}>🛠</div>
              <div>
                <div style={{ fontSize: 13, fontWeight: 700 }}>Active Booking · HVAC Diagnostic</div>
                <div style={{ fontSize: 12, color: "var(--text-2)" }}>Today 10:45 AM · ETA 8 min · $95/hr</div>
              </div>
            </div>
            <button className="btn" style={{ padding: "8px 16px", background: "var(--accent)", color: "#000", fontSize: 12 }}>Track →</button>
          </div>

          {/* messages */}
          <div className="scroll-col" style={{
            flex: 1,
            padding: "20px 24px",
            display: "flex", flexDirection: "column", gap: 12,
          }}>
            {messages.map((m, i) => {
              if (m.status) {
                return (
                  <div key={i} style={{ alignSelf: "center", display: "flex", alignItems: "center", gap: 8, fontSize: 11, color: "var(--text-3)", letterSpacing: "0.5px", margin: "8px 0" }}>
                    <span style={{ flex: 1, height: 1, background: "var(--border-2)", width: 60 }} />
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" strokeWidth="2"><circle cx="12" cy="10" r="3"/><path d="M12 2a8 8 0 018 8c0 6-8 12-8 12S4 16 4 10a8 8 0 018-8z"/></svg>
                    {m.text} · {m.time}
                    <span style={{ flex: 1, height: 1, background: "var(--border-2)", width: 60 }} />
                  </div>
                );
              }
              const mine = m.from === "me";
              return (
                <div key={i} style={{
                  alignSelf: mine ? "flex-end" : "flex-start",
                  maxWidth: "70%",
                  display: "flex", flexDirection: "column",
                  gap: 4,
                }}>
                  <div style={{
                    padding: "12px 16px",
                    background: mine ? "var(--accent)" : "var(--bg-2)",
                    color: mine ? "#000" : "var(--text)",
                    borderRadius: mine ? "20px 20px 4px 20px" : "20px 20px 20px 4px",
                    fontSize: 14, lineHeight: 1.4,
                  }}>{m.text}</div>
                  <div style={{
                    fontSize: 10,
                    color: "var(--text-3)",
                    alignSelf: mine ? "flex-end" : "flex-start",
                    padding: "0 4px",
                  }}>{m.time}{mine && " · Seen"}</div>
                </div>
              );
            })}
          </div>

          {/* composer */}
          <div style={{ padding: 16, borderTop: "1px solid var(--border)" }}>
            <div style={{
              display: "flex", gap: 8, alignItems: "center",
              background: "var(--bg-2)",
              borderRadius: 999,
              padding: "6px 6px 6px 20px",
            }}>
              <IconBtn small>📎</IconBtn>
              <input
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && send()}
                placeholder="Type your message..."
                style={{
                  flex: 1,
                  background: "transparent", border: "none", outline: "none",
                  color: "var(--text)", fontFamily: "inherit", fontSize: 14,
                  padding: "8px 0",
                }}
              />
              <IconBtn small>😊</IconBtn>
              <button
                onClick={send}
                className="btn"
                style={{
                  width: 44, height: 44, borderRadius: "50%",
                  background: "var(--accent)", color: "#000",
                  display: "grid", placeItems: "center",
                }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="#000"><path d="M2 21l21-9L2 3v7l15 2-15 2v7z"/></svg>
              </button>
            </div>
          </div>
        </section>

        {/* RIGHT — details */}
        <aside style={{
          background: "var(--bg-2)",
          borderLeft: "1px solid var(--border)",
          padding: 24,
          display: "flex", flexDirection: "column", gap: 24,
        }}>
          <div style={{ textAlign: "center" }}>
            <div style={{
              width: 80, height: 80, borderRadius: "50%",
              backgroundImage: `url(${contact.avatar})`,
              backgroundSize: "cover",
              margin: "0 auto 12px",
              border: "3px solid var(--accent)",
            }} />
            <div style={{ fontSize: 18, fontWeight: 700 }}>{contact.name}</div>
            <div style={{ fontSize: 13, color: "var(--text-3)", marginBottom: 8 }}>{contact.role}</div>
            <div style={{ display: "flex", gap: 4, justifyContent: "center", alignItems: "center", fontSize: 13 }}>
              <svg width="12" height="12" viewBox="0 0 24 24" fill="var(--accent)"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
              <span style={{ fontWeight: 700 }}>4.87</span>
              <span style={{ color: "var(--text-3)" }}>· 312 reviews</span>
            </div>
          </div>

          <div style={{
            padding: 16,
            background: "rgba(255,255,255,0.03)",
            borderRadius: 12,
            display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 8, textAlign: "center",
          }}>
            {[{ v: "98%", l: "On-Time" }, { v: "312", l: "Jobs" }, { v: "8y", l: "Exp" }].map((s) => (
              <div key={s.l}>
                <div style={{ fontSize: 18, fontWeight: 700 }}>{s.v}</div>
                <div style={{ fontSize: 10, color: "var(--text-3)", letterSpacing: "0.5px" }}>{s.l}</div>
              </div>
            ))}
          </div>

          <div>
            <div style={{ fontSize: 11, fontWeight: 700, color: "var(--text-3)", letterSpacing: "1.2px", marginBottom: 12 }}>SHARED FILES (3)</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              {[
                { n: "HVAC-diagnostic.pdf", s: "184 KB" },
                { n: "quote-march-14.pdf", s: "92 KB" },
                { n: "unit-photo.jpg", s: "2.1 MB" },
              ].map((f) => (
                <div key={f.n} style={{
                  display: "flex", gap: 10, alignItems: "center",
                  padding: 10, borderRadius: 10,
                  background: "rgba(255,255,255,0.03)",
                  cursor: "pointer",
                }}>
                  <div style={{ width: 32, height: 32, borderRadius: 8, background: "rgba(255,255,0,0.1)", display: "grid", placeItems: "center", fontSize: 14 }}>📄</div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 12, fontWeight: 500, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{f.n}</div>
                    <div style={{ fontSize: 10, color: "var(--text-3)" }}>{f.s}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <button className="btn btn-ghost" style={{ width: "100%", padding: "12px" }}>View Full Profile</button>
        </aside>
      </div>
    </div>
  );
};

const IconBtn = ({ children, small }) => (
  <button className="btn" style={{
    width: small ? 32 : 36,
    height: small ? 32 : 36,
    borderRadius: "50%",
    background: "var(--bg-2)",
    color: "var(--text)",
    display: "grid", placeItems: "center",
    fontSize: 14,
  }}>{children}</button>
);

Object.assign(window, { ScreenChat });
