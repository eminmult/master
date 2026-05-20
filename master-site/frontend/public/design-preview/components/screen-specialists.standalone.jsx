// Specialists list screen — filter sidebar + grid
const SPECIALISTS = [
  { id: 1, name: "Marcus Vane",    title: "Principal Systems Architect", rating: 4.98, reviews: 842, price: 180, avatar: window.__resources["marcus_jpg"], tags: ["Strategy", "Blockchain"], available: "Today", response: "Quick" },
  { id: 2, name: "Alex Rivera",    title: "HVAC Specialist",            rating: 4.87, reviews: 312, price: 95, avatar: window.__resources["alex_rivera_jpg"], tags: ["HVAC", "Climate"], available: "Today", response: "< 15 min" },
  { id: 3, name: "Sarah Chen",     title: "Senior Electrician",          rating: 4.92, reviews: 521, price: 110, avatar: window.__resources["sarah_chen_jpg"], tags: ["Wiring", "Panels"], available: "Tomorrow", response: "Quick" },
  { id: 4, name: "Ethan Park",     title: "Master Plumber",              rating: 4.75, reviews: 287, price: 85, avatar: window.__resources["contact_1_jpg"], tags: ["Leaks", "Fixtures"], available: "Today", response: "~ 30 min" },
  { id: 5, name: "Sophia Lane",    title: "Cleaning Lead",               rating: 5.00, reviews: 198, price: 60, avatar: window.__resources["contact_2_jpg"], tags: ["Deep Clean", "Move-out"], available: "Today", response: "Quick" },
  { id: 6, name: "Noah Hartwell",  title: "Journeyman Electrician",      rating: 4.65, reviews: 154, price: 70, avatar: window.__resources["contact_3_jpg"], tags: ["Lighting", "Outlets"], available: "Weekend", response: "~ 1 hr" },
];

const FilterButton = ({ label, active, onClick, count }) => (
  <button
    onClick={onClick}
    className="btn"
    style={{
      width: "100%",
      padding: "12px 20px",
      background: active ? "var(--accent)" : "var(--bg-2)",
      color: active ? "#000" : "var(--text)",
      border: "none",
      borderRadius: 999,
      textAlign: "left",
      fontSize: 14,
      fontWeight: active ? 700 : 500,
      display: "flex",
      justifyContent: "space-between",
      alignItems: "center",
    }}>
    <span>{label}</span>
    {count != null && (
      <span style={{ opacity: 0.6, fontSize: 12 }}>{count}</span>
    )}
  </button>
);

const SpecialistCard = ({ s, onView }) => (
  <div style={{
    width: 291,
    background: "var(--bg-1)",
    border: "1px solid var(--border-2)",
    borderRadius: 24,
    padding: 20,
    display: "flex", flexDirection: "column",
    transition: "border-color 180ms, transform 180ms",
    cursor: "pointer",
  }}
    onClick={() => onView?.(s)}
    onMouseEnter={(e) => { e.currentTarget.style.borderColor = "var(--accent)"; e.currentTarget.style.transform = "translateY(-2px)"; }}
    onMouseLeave={(e) => { e.currentTarget.style.borderColor = "var(--border-2)"; e.currentTarget.style.transform = ""; }}
  >
    {/* avatar area */}
    <div style={{
      position: "relative",
      width: "100%",
      height: 200,
      borderRadius: 16,
      backgroundImage: `url(${s.avatar})`,
      backgroundSize: "cover",
      backgroundPosition: "center",
      marginBottom: 16,
    }}>
      <div style={{
        position: "absolute", top: 12, right: 12,
        padding: "4px 10px",
        borderRadius: 999,
        background: s.available === "Today" ? "var(--accent)" : "rgba(0,0,0,0.6)",
        color: s.available === "Today" ? "#000" : "#fff",
        fontSize: 10,
        fontWeight: 700,
        letterSpacing: "1px",
        textTransform: "uppercase",
        backdropFilter: "blur(4px)",
      }}>{s.available}</div>
      <div style={{
        position: "absolute", bottom: 12, left: 12,
        padding: "4px 10px",
        borderRadius: 999,
        background: "rgba(0,0,0,0.6)",
        backdropFilter: "blur(8px)",
        color: "#fff",
        fontSize: 11,
        fontWeight: 700,
        display: "flex", alignItems: "center", gap: 4,
      }}>
        <svg width="11" height="11" viewBox="0 0 24 24" fill="var(--accent)">
          <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
        </svg>
        {s.rating}
      </div>
    </div>

    <h3 style={{ margin: 0, fontSize: 18, fontWeight: 700, color: "var(--text)" }}>{s.name}</h3>
    <p style={{ margin: "4px 0 12px", fontSize: 13, color: "var(--text-3)" }}>{s.title}</p>

    <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginBottom: 16 }}>
      {s.tags.map((t) => (
        <span key={t} style={{
          fontSize: 11, padding: "3px 8px",
          background: "rgba(255,255,0,0.08)",
          color: "var(--accent)",
          borderRadius: 999,
          fontWeight: 500,
        }}>{t}</span>
      ))}
    </div>

    <div style={{
      marginTop: "auto",
      display: "flex", justifyContent: "space-between", alignItems: "center",
      paddingTop: 16, borderTop: "1px solid var(--border-2)",
    }}>
      <div>
        <div style={{ fontSize: 22, fontWeight: 700, color: "var(--text)" }}>
          ${s.price}<span style={{ fontSize: 12, color: "var(--text-3)", fontWeight: 500 }}> /hr</span>
        </div>
        <div style={{ fontSize: 11, color: "var(--text-3)" }}>{s.reviews} reviews</div>
      </div>
      <button className="btn" style={{
        padding: "10px 16px",
        background: "var(--accent)", color: "#000",
        fontWeight: 700, fontSize: 13,
      }}>Book</button>
    </div>
  </div>
);

const ScreenSpecialists = ({ onNav, onBookSpecialist }) => {
  const [category, setCategory] = React.useState("Electrical");
  const [sortBy, setSortBy] = React.useState("Highest Rated");
  const [rating, setRating] = React.useState("4.5+");
  const [avails, setAvails] = React.useState({ today: false, emergency: true, weekend: false });
  const [price, setPrice] = React.useState([40, 180]);
  const [page, setPage] = React.useState(1);

  const sorted = React.useMemo(() => {
    const list = [...SPECIALISTS];
    if (sortBy === "Highest Rated") list.sort((a,b)=>b.rating-a.rating);
    else if (sortBy === "Lowest Price") list.sort((a,b)=>a.price-b.price);
    else if (sortBy === "Most Reviews") list.sort((a,b)=>b.reviews-a.reviews);
    return list.filter(s => s.price >= price[0] && s.price <= price[1]);
  }, [sortBy, price]);

  return (
    <div className="frame" style={{ minHeight: 1380 }}>
      <TopBarLogged active="specialists" onNav={onNav} />

      <main style={{
        display: "grid",
        gridTemplateColumns: "288px 1fr",
        gap: 32,
        padding: "48px 110px",
      }}>
        {/* Sidebar */}
        <aside style={{ display: "flex", flexDirection: "column", gap: 32 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <h2 style={{ margin: 0, fontSize: 20, fontWeight: 700 }}>Filters</h2>
            <a style={{ fontSize: 12, color: "var(--accent)", fontWeight: 700, letterSpacing: "0.6px", cursor: "pointer" }}>CLEAR ALL</a>
          </div>

          {/* Service Type */}
          <div>
            <div style={{ fontSize: 14, fontWeight: 700, color: "var(--text-3)", letterSpacing: "1.4px", marginBottom: 16 }}>SERVICE TYPE</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              {[
                { label: "Electrical", count: 42 },
                { label: "Plumbing", count: 38 },
                { label: "Cleaning", count: 61 },
                { label: "Gardening", count: 19 },
              ].map((c) => (
                <FilterButton
                  key={c.label}
                  label={c.label}
                  count={c.count}
                  active={category === c.label}
                  onClick={() => setCategory(c.label)}
                />
              ))}
              <button className="btn btn-ghost" style={{ padding: "12px 20px", fontSize: 14, marginTop: 4 }}>See more</button>
            </div>
          </div>

          {/* Price */}
          <div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
              <div style={{ fontSize: 14, fontWeight: 700, color: "var(--text-3)", letterSpacing: "1.4px" }}>PRICE / HR</div>
              <div style={{ fontSize: 16, fontWeight: 700, color: "var(--accent)" }}>${price[0]} — ${price[1]}</div>
            </div>
            <RangeSlider value={price} onChange={setPrice} min={40} max={300} />
          </div>

          {/* Rating */}
          <div>
            <div style={{ fontSize: 14, fontWeight: 700, color: "var(--text-3)", letterSpacing: "1.4px", marginBottom: 16 }}>MINIMUM RATING</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              {["4.5+ ★", "4.0+ ★", "3.5+ ★", "Any"].map((r) => (
                <FilterButton key={r} label={r} active={rating === r} onClick={() => setRating(r)} />
              ))}
            </div>
          </div>

          {/* Availability */}
          <div>
            <div style={{ fontSize: 14, fontWeight: 700, color: "var(--text-3)", letterSpacing: "1.4px", marginBottom: 16 }}>AVAILABILITY</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              {[
                { k: "today", label: "Available Today" },
                { k: "emergency", label: "Emergency Service" },
                { k: "weekend", label: "Weekend Availability" },
              ].map((o) => (
                <label key={o.k} style={{ display: "flex", gap: 12, alignItems: "center", cursor: "pointer", fontSize: 14, color: "var(--text-2)" }}>
                  <span style={{
                    width: 18, height: 18, borderRadius: "50%",
                    background: avails[o.k] ? "var(--accent)" : "transparent",
                    border: avails[o.k] ? "1px solid var(--accent)" : "1px solid rgba(255,255,255,0.2)",
                    display: "grid", placeItems: "center",
                    transition: "all 160ms",
                  }}>
                    {avails[o.k] && (
                      <svg width="10" height="8" viewBox="0 0 10 8" fill="#000"><path d="M1 4l3 3 5-6" stroke="#000" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
                    )}
                  </span>
                  <input
                    type="checkbox"
                    checked={avails[o.k]}
                    onChange={() => setAvails({ ...avails, [o.k]: !avails[o.k] })}
                    style={{ display: "none" }}
                  />
                  {o.label}
                </label>
              ))}
            </div>
          </div>
        </aside>

        {/* Main */}
        <section>
          {/* header */}
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 32 }}>
            <div>
              <h1 style={{ margin: 0, fontSize: 30, fontWeight: 700 }}>{category} Specialists</h1>
              <p style={{ margin: "4px 0 0", fontSize: 16, color: "var(--text-3)" }}>
                Found {sorted.length * 7} certified pros in your area
              </p>
            </div>

            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
              <span style={{ color: "var(--text-3)", fontSize: 14 }}>Sort by:</span>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value)}
                style={{
                  appearance: "none",
                  background: "var(--bg-2)",
                  border: "none",
                  padding: "8px 40px 8px 16px",
                  borderRadius: 999,
                  color: "var(--text)",
                  fontFamily: "inherit",
                  fontSize: 14,
                  fontWeight: 500,
                  cursor: "pointer",
                  backgroundImage: "url(\"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='10' height='6' viewBox='0 0 10 6'><path d='M1 1l4 4 4-4' stroke='rgb(107,114,128)' stroke-width='1.5' fill='none' stroke-linecap='round'/></svg>\")",
                  backgroundRepeat: "no-repeat",
                  backgroundPosition: "right 16px center",
                }}
              >
                <option>Highest Rated</option>
                <option>Lowest Price</option>
                <option>Most Reviews</option>
              </select>
            </div>
          </div>

          {/* grid */}
          <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 291px)", gap: 12 }}>
            {sorted.map((s) => (
              <SpecialistCard key={s.id} s={s} onView={() => onBookSpecialist?.(s)} />
            ))}
          </div>

          {/* pagination */}
          <div style={{ display: "flex", justifyContent: "center", gap: 8, marginTop: 48 }}>
            <button className="btn" style={{
              width: 48, height: 48, borderRadius: "50%",
              border: "1px solid var(--border)",
              background: "transparent", color: "var(--text)",
              display: "grid", placeItems: "center",
            }}>‹</button>
            {[1, 2, 3, "...", 14].map((p, i) => (
              <button
                key={i}
                onClick={() => typeof p === "number" && setPage(p)}
                className="btn"
                style={{
                  width: 48, height: 48, borderRadius: "50%",
                  background: page === p ? "var(--accent)" : "transparent",
                  color: page === p ? "#000" : "var(--text)",
                  border: page === p ? "none" : "1px solid var(--border)",
                  fontWeight: 500,
                }}>{p}</button>
            ))}
            <button className="btn" style={{
              width: 48, height: 48, borderRadius: "50%",
              border: "1px solid var(--border)",
              background: "transparent", color: "var(--text)",
              display: "grid", placeItems: "center",
            }}>›</button>
          </div>
        </section>
      </main>

      <FooterBar />
    </div>
  );
};

// Dual-handle range slider
const RangeSlider = ({ value, onChange, min, max }) => {
  const [dragging, setDragging] = React.useState(null);
  const trackRef = React.useRef();

  const pct = (v) => ((v - min) / (max - min)) * 100;

  const startDrag = (which) => (e) => {
    e.preventDefault();
    setDragging(which);
  };

  React.useEffect(() => {
    if (!dragging) return;
    const onMove = (e) => {
      if (!trackRef.current) return;
      const r = trackRef.current.getBoundingClientRect();
      const x = Math.max(0, Math.min(1, (e.clientX - r.left) / r.width));
      const v = Math.round(min + x * (max - min));
      if (dragging === "min") onChange([Math.min(v, value[1] - 10), value[1]]);
      else onChange([value[0], Math.max(v, value[0] + 10)]);
    };
    const onUp = () => setDragging(null);
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
    return () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
  }, [dragging, value, onChange, min, max]);

  return (
    <div ref={trackRef} style={{
      position: "relative",
      width: "100%", height: 8,
      background: "var(--bg-2)",
      borderRadius: 999,
      margin: "20px 0",
    }}>
      <div style={{
        position: "absolute",
        left: `${pct(value[0])}%`,
        right: `${100 - pct(value[1])}%`,
        height: 8,
        background: "var(--accent)",
        borderRadius: 999,
      }} />
      {[0, 1].map((i) => (
        <div
          key={i}
          onMouseDown={startDrag(i === 0 ? "min" : "max")}
          style={{
            position: "absolute",
            left: `${pct(value[i])}%`,
            top: "50%",
            width: 18, height: 18,
            transform: "translate(-50%, -50%)",
            background: "#fff",
            borderRadius: "50%",
            boxShadow: "0 4px 10px rgba(0,0,0,0.3)",
            cursor: "grab",
          }}
        />
      ))}
    </div>
  );
};

Object.assign(window, { ScreenSpecialists, SpecialistCard, SPECIALISTS });
