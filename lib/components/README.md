# Buyer Components

Reusable widgets for the Unshelf buyer Flutter app. These widgets are buyer-specific — per the uniqueness rule (`[[unshelf-buyer-seller-uniqueness]]`), the seller app has its own components. Only the auth flow is visually shared between apps (see `brand-kit/docs/crucible/auth-screens.md`).

All components consume the brand theme via `Theme.of(context).colorScheme` and `textTheme`. None hardcode colors or fonts.

---

## Catalog

### BasketRow

A single line-item row inside the basket screen. Shows a 72×72 thumbnail, product name, store name, a `QuantityStepper`, and the line total rendered in DM Serif Display.

**File:** `lib/components/basket_row.dart`

**Props:**
- `productName` (String) — display name of the product
- `productImageUrl` (String) — URL for the product thumbnail
- `storeName` (String) — name of the selling store
- `unitPrice` (double) — price per unit after discount
- `quantity` (int) — current quantity in basket
- `maxQuantity` (int) — stock ceiling passed to `QuantityStepper`
- `onQuantityChanged` (ValueChanged\<int\>) — called when stepper changes
- `isSelected` (bool, default `false`) — whether the leading checkbox is checked
- `onSelectionChanged` (ValueChanged\<bool?\>?, optional) — if non-null, a leading checkbox is rendered

**Used by:**
- `lib/views/basket_view.dart`

**Example:**
```dart
BasketRow(
  productName: 'Sourdough Loaf',
  productImageUrl: imageUrl,
  storeName: 'Señor Pan',
  unitPrice: 120.0,
  quantity: 2,
  maxQuantity: 5,
  onQuantityChanged: (n) => ref.read(basketProvider.notifier).setQty(id, n),
  isSelected: true,
  onSelectionChanged: (v) => ref.read(basketProvider.notifier).toggle(id),
)
```

---

### CategoryIconsRow

A horizontally scrollable row of pill-shaped category filter buttons. Tapping a pill navigates to `CategoryProductsPage`. Animated press state using `AnimatedContainer`.

**File:** `lib/components/category_row_widget.dart`

**Props:** none — categories are hardcoded (Grocery, Fruits, Veggies, Baked).

**Used by:**
- `lib/views/home_view.dart`
- `lib/views/category_view.dart`

**Example:**
```dart
CategoryIconsRow()
```

---

### ChatBubble

A single message bubble for the in-app chat screen. Adjusts color and tail corner direction based on whether the message is from the current user ("sender") or the other party.

**File:** `lib/components/chat_bubble.dart`

**Props:**
- `message` (String) — the text to display
- `type` (String) — `'sender'` or any other value for the receiver side

**Used by:**
- `lib/views/chat_screen.dart`
- `lib/views/chat_view.dart`
- `lib/views/order_tracking_view.dart`
- `lib/views/store_view.dart`

**Example:**
```dart
ChatBubble(message: 'Is this still available?', type: 'sender')
ChatBubble(message: 'Yes, pick up by 5 PM.', type: 'receiver')
```

---

### CustomBottomNavigationBar

The app-wide bottom navigation bar with five tabs: Home, Stores, Orders, Notifications, My Stuff. Uses `Navigator.pushReplacement` with a fade transition. Animated scale on the active icon.

**File:** `lib/components/custom_navigation_bar.dart`

**Props:**
- `currentIndex` (int) — the index of the currently active tab (0–4)

**Used by:**
- `lib/views/home_view.dart` (index 0)
- `lib/views/map_view.dart` (index 1)
- `lib/views/stores_view.dart` (index 1)
- `lib/views/notifications_view.dart` (index 3)
- `lib/views/profile_view.dart` (index 4)

**Example:**
```dart
CustomBottomNavigationBar(currentIndex: 0)
```

---

### EmptyStateView

Centred placeholder used for empty, loading, and error states. Renders an icon, a headline, and a body paragraph. Optional CTA `OutlinedButton` below the body.

**File:** `lib/components/empty_state_view.dart`

**Props:**
- `icon` (IconData) — the large illustrative icon
- `headline` (String) — short heading (uses `headlineSmall`)
- `body` (String) — supporting copy (uses `bodyMedium`)
- `ctaLabel` (String?, optional) — label for the action button
- `onCta` (VoidCallback?, optional) — tap handler; button is hidden when either is null

**Used by:**
- `lib/views/basket_view.dart`
- `lib/views/category_view.dart`
- `lib/views/chat_screen.dart`
- `lib/views/home_view.dart`
- `lib/views/notifications_view.dart`
- `lib/views/order_history_view.dart`
- `lib/views/product_bundle_view.dart`
- `lib/views/product_view.dart`
- `lib/views/profile_favorites_view.dart`
- `lib/views/profile_following_view.dart`
- `lib/views/search_view.dart`
- `lib/views/stores_view.dart`
- `lib/views/store_reviews_view.dart`
- `lib/views/store_view.dart`

**Example:**
```dart
EmptyStateView(
  icon: Icons.shopping_basket_outlined,
  headline: 'Your basket is empty',
  body: 'Browse nearby stores to add items.',
  ctaLabel: 'Browse stores',
  onCta: () => Navigator.pop(context),
)
```

---

### FieldLabel

Small-caps form field label rendered above `TextFormField` widgets in auth screens and profile editing. Uses `labelLarge` with `FontWeight.w600` and a slight letter spacing.

**File:** `lib/components/field_label.dart`

**Props:**
- `text` (String) — the label string (positional)
- `color` (Color, required) — text color; callers pass `cs.onSurface` or `cs.onPrimary` etc.

**Used by:**
- `lib/authentication/views/login_view.dart`
- `lib/authentication/views/register_view.dart`
- `lib/authentication/views/forgot_password_view.dart`
- `lib/views/edit_profile_view.dart`

**Example:**
```dart
FieldLabel('Email address', color: cs.onSurface)
```

---

### OrderCard

A tappable card summarising a single order in the order history list. Shows store avatar, store name, status pill, order number, item count, total price (DM Serif Display), and order date.

**File:** `lib/components/order_card.dart`

**Props:**
- `storeImageUrl` (String) — URL for the store avatar
- `storeName` (String) — store display name
- `orderId` (String) — order identifier
- `status` (String) — order status string (e.g. `'Pending'`, `'Completed'`)
- `itemCount` (int) — number of distinct items
- `totalPrice` (double) — order total
- `createdAt` (DateTime) — order creation timestamp
- `onTap` (VoidCallback) — tap handler for navigating to order details

**Used by:**
- `lib/views/order_history_view.dart`

**Example:**
```dart
OrderCard(
  storeImageUrl: store.imageUrl,
  storeName: store.name,
  orderId: order.id,
  status: order.status,
  itemCount: order.items.length,
  totalPrice: order.total,
  createdAt: order.createdAt,
  onTap: () => Navigator.push(context, ...),
)
```

---

### OrderStatusTimeline

Vertical progress timeline showing the five order stages: Placed → Confirmed → Preparing → Ready for pickup → Picked up. Past stages show a filled circle with a check; the current stage pulses; future stages are grey outlines.

**File:** `lib/components/order_status_timeline.dart`

**Props:**
- `currentStage` (OrderStage) — the current stage enum value
- `timestamps` (List\<StageTimestamp\>, default `[]`) — optional per-stage timestamps to display below each label

**Supporting types:**
- `OrderStage` — enum: `placed`, `confirmed`, `preparing`, `ready`, `completed`
- `StageTimestamp` — value object: `{stage: OrderStage, timestamp: DateTime?}`

**Used by:**
- `lib/views/order_tracking_view.dart`

**Example:**
```dart
OrderStatusTimeline(
  currentStage: OrderStage.preparing,
  timestamps: [
    StageTimestamp(stage: OrderStage.placed, timestamp: order.placedAt),
    StageTimestamp(stage: OrderStage.confirmed, timestamp: order.confirmedAt),
  ],
)
```

---

### ProductCard

Card used throughout the buyer app to surface an individual product. Two layout modes:

- **Default (row):** wide thumbnail left, details right. Used in "Expiring soon" sections.
- **Compact (grid):** square thumbnail top, details below. Used in category, search, and store product grids.

**File:** `lib/components/product_card.dart`

**Props (both constructors):**
- `productId` (String) — navigates to `ProductPage` on tap
- `name` (String) — product display name
- `price` (double) — original unit price
- `discount` (int) — percentage discount (0–100); discounted price is computed internally
- `expiryDate` (DateTime) — used to compute the expiry badge label
- `mainImageUrl` (String?, optional) — product thumbnail URL
- `storeName` (String?, optional) — shown as a subtitle under the name

**Constructors:**
- `ProductCard({...})` — row layout
- `ProductCard.compact({...})` — grid/compact layout

**Used by:**
- `lib/views/category_view.dart`
- `lib/views/home_view.dart`
- `lib/views/profile_favorites_view.dart`
- `lib/views/search_view.dart`
- `lib/views/store_view.dart`

**Example:**
```dart
// Row (home feed)
ProductCard(
  productId: p.id,
  name: p.name,
  price: p.price,
  discount: p.discount,
  expiryDate: p.expiryDate,
  mainImageUrl: p.imageUrl,
  storeName: p.storeName,
)

// Grid
ProductCard.compact(
  productId: p.id,
  name: p.name,
  price: p.price,
  discount: p.discount,
  expiryDate: p.expiryDate,
  mainImageUrl: p.imageUrl,
)
```

---

### QuantityStepper

Inline `[–] count [+]` control. The decrement button disables at `min`; the increment button disables when `value == max`.

**File:** `lib/components/quantity_stepper.dart`

**Props:**
- `value` (int) — current count
- `onChanged` (ValueChanged\<int\>) — called with the new value
- `min` (int, default `1`) — minimum allowed value
- `max` (int?, optional) — maximum allowed value; no upper limit if null

**Used by:**
- `lib/components/basket_row.dart`
- `lib/views/product_bundle_view.dart`
- `lib/views/product_view.dart`

**Example:**
```dart
QuantityStepper(
  value: qty,
  onChanged: (n) => setState(() => qty = n),
  min: 1,
  max: stock,
)
```

---

### SectionCard

A 14-radius `surfaceContainerHighest` card with a two-layer ink shadow. Pure layout wrapper — callers provide the `child`.

**File:** `lib/components/section_card.dart`

**Props:**
- `child` (Widget) — the content to wrap
- `padding` (EdgeInsetsGeometry, default `EdgeInsets.all(16)`) — inner padding

**Used by:**
- `lib/views/basket_checkout_view.dart`
- `lib/views/order_details_view.dart`
- `lib/views/profile_view.dart`
- `lib/views/report_view.dart`

**Example:**
```dart
SectionCard(
  child: Column(
    children: [
      FieldLabel('Delivery address', color: cs.onSurface),
      const SizedBox(height: 8),
      Text(address),
    ],
  ),
)
```

---

### SectionHeader

Standardised row used to title content sections. Renders a `titleLarge` (DM Serif Display) label on the left with an optional right-aligned `TextButton` action.

**File:** `lib/components/section_header.dart`

**Props:**
- `title` (String) — section heading
- `actionLabel` (String?, optional) — right-side button label
- `onAction` (VoidCallback?, optional) — right-side button tap handler; button hidden when either is null

**Used by:**
- `lib/views/basket_view.dart`
- `lib/views/home_view.dart`
- `lib/views/notifications_view.dart`

**Example:**
```dart
SectionHeader(
  title: 'Expiring soon',
  actionLabel: 'See all',
  onAction: () => Navigator.push(context, ...),
)
```

---

### SettingsTile

A tappable `ListTile`-style row for the profile settings screen. Displays a pill icon badge, title, optional subtitle, and a trailing chevron. Supports a `destructive` mode that renders the icon and title in `cs.error`.

**File:** `lib/components/settings_tile.dart`

**Props:**
- `icon` (IconData) — icon shown in the leading badge
- `title` (String) — primary label
- `subtitle` (String?, optional) — secondary label beneath the title
- `onTap` (VoidCallback) — tap handler
- `iconColor` (Color?, optional) — overrides the default `cs.onSurface` icon tint
- `destructive` (bool, default `false`) — renders icon and title in `cs.error`

**Used by:**
- `lib/views/profile_view.dart`

**Example:**
```dart
SettingsTile(
  icon: Icons.edit_outlined,
  title: 'Edit profile',
  onTap: () => Navigator.push(context, ...),
)

SettingsTile(
  icon: Icons.logout,
  title: 'Log out',
  destructive: true,
  onTap: _handleLogOut,
)
```

---

### StarRatingPicker

Interactive 5-star tap-to-rate input widget. Tapping a star sets the rating to that star's index (1–5). Distinct from the read-only `_StarRow` inside `store_reviews_view.dart`.

**File:** `lib/components/star_rating_picker.dart`

**Props:**
- `value` (int) — current rating (1–5)
- `onChanged` (ValueChanged\<int\>) — called with the new rating
- `starSize` (double, default `40.0`) — diameter of each star icon

**Used by:**
- `lib/views/review_view.dart`

**Example:**
```dart
StarRatingPicker(
  value: _rating,
  onChanged: (r) => setState(() => _rating = r),
)
```

---

### StoreCard

Horizontal card used in the "Nearby stores" carousel on the home screen and other store-list contexts. Shows a cover image (or a brand-green gradient placeholder), store name, rating, and follower count. Navigates to `StoreView` on tap.

**File:** `lib/components/store_card.dart`

**Props:**
- `storeId` (String) — passed to `StoreView` on navigation
- `storeName` (String) — store display name
- `storeImageUrl` (String?, optional) — cover image URL
- `rating` (double?, optional) — average star rating
- `followerCount` (int?, optional) — number of followers

**Used by:**
- `lib/views/home_view.dart`
- `lib/views/profile_following_view.dart`
- `lib/views/stores_view.dart`

**Example:**
```dart
StoreCard(
  storeId: store.id,
  storeName: store.name,
  storeImageUrl: store.imageUrl,
  rating: store.rating,
  followerCount: store.followerCount,
)
```

---

### showDateTimePicker

A utility function (not a widget) that chains Flutter's built-in `showDatePicker` and `showTimePicker` into a single awaitable call. Returns `DateTime?` with the combined date and time.

**File:** `lib/components/datetime_picker.dart`

**Parameters:**
- `context` (BuildContext, required) — build context
- `initialDate` (DateTime?, optional) — defaults to `DateTime.now()`
- `firstDate` (DateTime?, optional) — defaults to `DateTime.now()`
- `lastDate` (DateTime?, optional) — defaults to 200 years from `firstDate`

**Returns:** `Future<DateTime?>` — `null` if the user cancels the date picker; the chosen date (without time) if the user cancels only the time picker.

**Used by:**
- `lib/views/basket_checkout_view.dart`

**Example:**
```dart
final picked = await showDateTimePicker(context: context);
if (picked != null) setState(() => _scheduledAt = picked);
```
