package nz.practice.catalog;

import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.time.Duration;

/**
 * Dummy catalogue and calendar service for interview practice.
 * The data is hard-coded. In a real platform it would come from a database.
 */
@RestController
@RequestMapping("/api")
public class CatalogController {

    public record Product(String code, String name, String category, int quantityMt, double startingPriceUsdPerMt) {}

    public record ScheduledEvent(String id, String type, String startUtc) {}

    private static final List<Product> PRODUCTS = List.of(
            new Product("WMP", "Whole Milk Powder", "Powders", 8000, 3000.0),
            new Product("SMP", "Skim Milk Powder", "Powders", 5000, 2600.0),
            new Product("BUT", "Butter", "Fats", 2500, 6500.0),
            new Product("AMF", "Anhydrous Milk Fat", "Fats", 1200, 7200.0),
            new Product("CHE", "Cheddar", "Cheese", 1500, 4800.0));

    // Dummy dates.
    private static final List<ScheduledEvent> CALENDAR = List.of(
            new ScheduledEvent("TE-A", "Trading Event", "2026-12-02T12:00:00Z"),
            new ScheduledEvent("TP-A", "Pulse", "2026-12-09T12:00:00Z"),
            new ScheduledEvent("TE-B", "Trading Event", "2026-12-16T12:00:00Z"));

    private final long cacheSeconds;

    public CatalogController(@Value("${catalog.cache-seconds:60}") long cacheSeconds) {
        this.cacheSeconds = cacheSeconds;
    }

    // Starting prices are published days before an event, so this response is safe to cache.
    @GetMapping("/products")
    public ResponseEntity<List<Product>> products() {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.maxAge(Duration.ofSeconds(cacheSeconds)).cachePublic())
                .body(PRODUCTS);
    }

    @GetMapping("/products/{code}")
    public ResponseEntity<Product> product(@PathVariable String code) {
        return PRODUCTS.stream()
                .filter(p -> p.code().equalsIgnoreCase(code))
                .findFirst()
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/calendar")
    public List<ScheduledEvent> calendar() {
        return CALENDAR;
    }
}
