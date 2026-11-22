using System.Collections.Concurrent;
using System.Net.Sockets;
using System.Text;

// Dummy bid API for interview practice.
// Data is held in memory on purpose: a real platform would use a relational database
// (see db/schema.sql) and a cache. Settings come from appsettings.json or environment
// variables (for example Auction__RoundSeconds, Dependencies__Sql).

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<AuctionClock>();
builder.Services.AddSingleton<BidStore>();
builder.Services.AddSingleton<Counters>();

var app = builder.Build();

// Liveness: the process is up.
app.MapGet("/healthz", () => Results.Ok(new { status = "ok" }));

// Readiness: only ready when the configured dependencies accept connections.
app.MapGet("/readyz", async (IConfiguration config) =>
{
    var checks = new Dictionary<string, string>();
    var ready = true;

    foreach (var name in new[] { "Sql", "Redis" })
    {
        var target = config[$"Dependencies:{name}"];
        if (string.IsNullOrWhiteSpace(target))
        {
            checks[name] = "not configured";
            continue;
        }

        var ok = await CanConnect(target);
        checks[name] = ok ? "up" : "down";
        ready &= ok;
    }

    var body = new { status = ready ? "ready" : "not ready", checks };
    return ready ? Results.Ok(body) : Results.Json(body, statusCode: 503);
});

// The current round. The server clock is the only clock that counts:
// browsers show a countdown for display only.
app.MapGet("/api/events/current", (AuctionClock clock) => Results.Ok(clock.Now()));

app.MapGet("/api/bids", (string bidder, BidStore store) => Results.Ok(store.ForBidder(bidder)));

app.MapPost("/api/bids", (HttpContext http, BidRequest request, AuctionClock clock, BidStore store, Counters counters) =>
{
    var key = http.Request.Headers["Idempotency-Key"].ToString();
    if (string.IsNullOrWhiteSpace(key))
    {
        return Results.BadRequest(new { error = "Idempotency-Key header is required" });
    }

    if (string.IsNullOrWhiteSpace(request.Bidder) || request.Quantity <= 0)
    {
        return Results.BadRequest(new { error = "bidder and a positive quantity are required" });
    }

    var snapshot = clock.Now();
    if (snapshot.Status != "Open")
    {
        counters.Rejected();
        return Results.Conflict(new { error = $"Round is not open (status: {snapshot.Status})" });
    }

    var result = store.Submit(key, snapshot.Round, request);
    if (!result.Ok)
    {
        counters.Rejected();
        return Results.UnprocessableEntity(new { error = result.Error });
    }

    if (result.Replayed)
    {
        counters.Replayed();
    }
    else
    {
        counters.Accepted();
    }

    return Results.Accepted($"/api/bids/{result.Bid!.Id}", result.Bid);
});

// Plain-text counters in the Prometheus exposition format.
app.MapGet("/metrics", (Counters counters) =>
{
    var text = new StringBuilder();
    text.AppendLine("# TYPE bids_accepted_total counter");
    text.AppendLine($"bids_accepted_total {counters.AcceptedCount}");
    text.AppendLine("# TYPE bids_rejected_total counter");
    text.AppendLine($"bids_rejected_total {counters.RejectedCount}");
    text.AppendLine("# TYPE bids_replayed_total counter");
    text.AppendLine($"bids_replayed_total {counters.ReplayedCount}");
    return Results.Text(text.ToString(), "text/plain; version=0.0.4");
});

app.Run();

static async Task<bool> CanConnect(string hostAndPort)
{
    var parts = hostAndPort.Split(':', 2);
    if (parts.Length != 2 || !int.TryParse(parts[1], out var port))
    {
        return false;
    }

    try
    {
        using var client = new TcpClient();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(1));
        await client.ConnectAsync(parts[0], port, timeout.Token);
        return true;
    }
    catch
    {
        return false;
    }
}

record BidRequest(string Bidder, string ProductCode, decimal Quantity);

record Bid(Guid Id, string Bidder, string ProductCode, int Round, decimal Quantity, DateTimeOffset AcceptedUtc);

record SubmitResult(bool Ok, string? Error, Bid? Bid, bool Replayed);

record RoundSnapshot(string EventId, string Status, int Round, int TotalRounds, DateTimeOffset RoundEndsUtc, decimal PriceUsdPerMt);

class AuctionClock
{
    private readonly DateTimeOffset _start = DateTimeOffset.UtcNow;
    private readonly string _eventId;
    private readonly int _roundSeconds;
    private readonly int _totalRounds;
    private readonly decimal _startingPrice;
    private readonly decimal _priceStep;

    public AuctionClock(IConfiguration config)
    {
        _eventId = config.GetValue("Auction:EventId", "TE-SAMPLE")!;
        _roundSeconds = config.GetValue("Auction:RoundSeconds", 60);
        _totalRounds = config.GetValue("Auction:TotalRounds", 15);
        _startingPrice = config.GetValue("Auction:StartingPriceUsdPerMt", 3000m);
        _priceStep = config.GetValue("Auction:PriceStepUsdPerMt", 25m);
    }

    public RoundSnapshot Now()
    {
        var now = DateTimeOffset.UtcNow;
        var elapsed = (now - _start).TotalSeconds;
        var round = (int)(elapsed / _roundSeconds) + 1;

        if (round > _totalRounds)
        {
            return new RoundSnapshot(_eventId, "Closed", _totalRounds, _totalRounds, now,
                _startingPrice + (_totalRounds - 1) * _priceStep);
        }

        var roundEnds = _start.AddSeconds(round * _roundSeconds);
        return new RoundSnapshot(_eventId, "Open", round, _totalRounds, roundEnds,
            _startingPrice + (round - 1) * _priceStep);
    }
}

class BidStore
{
    private readonly ConcurrentDictionary<string, Bid> _byKey = new();
    private readonly ConcurrentDictionary<string, List<Bid>> _byBidder = new();
    private readonly object _gate = new();

    public SubmitResult Submit(string idempotencyKey, int round, BidRequest request)
    {
        lock (_gate)
        {
            // A retry with the same key returns the original bid and changes nothing.
            if (_byKey.TryGetValue(idempotencyKey, out var existing))
            {
                return new SubmitResult(true, null, existing, true);
            }

            var history = _byBidder.GetOrAdd(request.Bidder, _ => new List<Bid>());

            // After round one, a bidder may keep or reduce a quantity, never raise it.
            var previous = history
                .Where(b => b.ProductCode == request.ProductCode)
                .OrderByDescending(b => b.Round)
                .FirstOrDefault();

            if (round > 1 && previous is not null && request.Quantity > previous.Quantity)
            {
                return new SubmitResult(false, "Quantity cannot increase after round one", null, false);
            }

            var bid = new Bid(Guid.NewGuid(), request.Bidder, request.ProductCode, round, request.Quantity, DateTimeOffset.UtcNow);
            history.Add(bid);
            _byKey[idempotencyKey] = bid;
            return new SubmitResult(true, null, bid, false);
        }
    }

    public IReadOnlyList<Bid> ForBidder(string bidder)
    {
        lock (_gate)
        {
            return _byBidder.TryGetValue(bidder, out var list) ? list.ToList() : new List<Bid>();
        }
    }
}

class Counters
{
    private long _accepted;
    private long _rejected;
    private long _replayed;

    public long AcceptedCount => Interlocked.Read(ref _accepted);
    public long RejectedCount => Interlocked.Read(ref _rejected);
    public long ReplayedCount => Interlocked.Read(ref _replayed);

    public void Accepted() => Interlocked.Increment(ref _accepted);
    public void Rejected() => Interlocked.Increment(ref _rejected);
    public void Replayed() => Interlocked.Increment(ref _replayed);
}
