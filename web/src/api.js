// All calls use relative URLs so the same build works behind any hostname.

async function getJson(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${url} returned ${res.status}`);
  return res.json();
}

export const fetchProducts = () => getJson("/api/products");
export const fetchCalendar = () => getJson("/api/calendar");
export const fetchRound = () => getJson("/api/events/current");

// The Idempotency-Key is created once per user action. A retry (a double click, a
// flaky network) sends the same key, so the server returns the original bid.
export async function submitBid(bid, idempotencyKey) {
  const res = await fetch("/api/bids", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Idempotency-Key": idempotencyKey,
    },
    body: JSON.stringify(bid),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(body.error ?? `Bid failed with ${res.status}`);
  return body;
}
