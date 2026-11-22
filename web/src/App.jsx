import { useCallback, useEffect, useRef, useState } from "react";
import { fetchCalendar, fetchProducts, fetchRound, submitBid } from "./api.js";

const POLL_MS = 2000;

export default function App() {
  const [products, setProducts] = useState([]);
  const [calendar, setCalendar] = useState([]);
  const [round, setRound] = useState(null);
  const [error, setError] = useState("");

  useEffect(() => {
    fetchProducts().then(setProducts).catch((e) => setError(e.message));
    fetchCalendar().then(setCalendar).catch((e) => setError(e.message));
  }, []);

  // The round is polled. The server clock decides when a round is open.
  useEffect(() => {
    let stop = false;
    const tick = () =>
      fetchRound()
        .then((r) => !stop && (setRound(r), setError("")))
        .catch((e) => !stop && setError(e.message));
    tick();
    const id = setInterval(tick, POLL_MS);
    return () => {
      stop = true;
      clearInterval(id);
    };
  }, []);

  return (
    <main className="page">
      <h1>Bidder Console (practice)</h1>
      {error && <p className="banner">Problem talking to the platform: {error}</p>}
      <RoundPanel round={round} />
      <section>
        <h2>Products</h2>
        <ProductTable products={products} />
      </section>
      <section>
        <h2>Bid</h2>
        <BidForm products={products} round={round} />
      </section>
      <section>
        <h2>Upcoming events</h2>
        <ul>
          {calendar.map((e) => (
            <li key={e.id}>
              {e.type}: {new Date(e.startUtc).toLocaleString()}
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}

function RoundPanel({ round }) {
  const secondsLeft = useCountdown(round?.roundEndsUtc);
  if (!round) return <p>Loading round...</p>;
  return (
    <section className="round" data-status={round.status}>
      <strong>
        {round.eventId} — round {round.round} of {round.totalRounds}
      </strong>
      <span>{round.status}</span>
      <span>Price: USD {round.priceUsdPerMt}/MT</span>
      {round.status === "Open" && <span>{secondsLeft}s left</span>}
    </section>
  );
}

// Display only. The countdown never decides whether a bid is accepted.
function useCountdown(endIso) {
  const [left, setLeft] = useState(0);
  useEffect(() => {
    if (!endIso) return;
    const update = () =>
      setLeft(Math.max(0, Math.round((new Date(endIso) - Date.now()) / 1000)));
    update();
    const id = setInterval(update, 500);
    return () => clearInterval(id);
  }, [endIso]);
  return left;
}

function ProductTable({ products }) {
  if (!products.length) return <p>No products loaded.</p>;
  return (
    <table>
      <thead>
        <tr>
          <th>Code</th>
          <th>Product</th>
          <th>Offered (MT)</th>
          <th>Start price (USD/MT)</th>
        </tr>
      </thead>
      <tbody>
        {products.map((p) => (
          <tr key={p.code}>
            <td>{p.code}</td>
            <td>{p.name}</td>
            <td>{p.quantityMt}</td>
            <td>{p.startingPriceUsdPerMt}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

function BidForm({ products, round }) {
  const [bidder, setBidder] = useState("BIDDER-001");
  const [productCode, setProductCode] = useState("WMP");
  const [quantity, setQuantity] = useState(100);
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);
  const pendingKey = useRef(null);

  const open = round?.status === "Open";

  const onSubmit = useCallback(
    async (event) => {
      event.preventDefault();
      if (busy) return;
      setBusy(true);
      // Reuse the key while a submission is unresolved, so a retry is safe.
      pendingKey.current ??= crypto.randomUUID();
      try {
        const bid = await submitBid(
          { bidder, productCode, quantity: Number(quantity) },
          pendingKey.current
        );
        setMessage(`Accepted in round ${bid.round}: ${bid.quantity} MT of ${bid.productCode}`);
        pendingKey.current = null;
      } catch (e) {
        setMessage(`Not accepted: ${e.message}`);
        pendingKey.current = null;
      } finally {
        setBusy(false);
      }
    },
    [bidder, productCode, quantity, busy]
  );

  return (
    <form onSubmit={onSubmit}>
      <label>
        Bidder
        <input value={bidder} onChange={(e) => setBidder(e.target.value)} />
      </label>
      <label>
        Product
        <select value={productCode} onChange={(e) => setProductCode(e.target.value)}>
          {products.map((p) => (
            <option key={p.code} value={p.code}>
              {p.code}
            </option>
          ))}
        </select>
      </label>
      <label>
        Quantity (MT)
        <input
          type="number"
          min="1"
          value={quantity}
          onChange={(e) => setQuantity(e.target.value)}
        />
      </label>
      <button type="submit" disabled={!open || busy}>
        {busy ? "Submitting..." : "Submit bid"}
      </button>
      {message && <p role="status">{message}</p>}
    </form>
  );
}
