import 'package:flutter/material.dart';

import '../../models/shop.dart';
import '../../models/stall.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/animations.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/common.dart';
import '../../widgets/guest_gate.dart';
import '../../widgets/market_map.dart';
import '../../widgets/stall_info_card.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/shop_cards.dart';
import '../../widgets/shop_ui.dart';
import '../favorites_screen.dart';
import '../profile_tab.dart';

/// ฝั่งผู้ซื้อ — เลย์เอาต์แบบหน้าร้านออนไลน์: รูปปกเต็มจอ ปุ่มกลมลอย
/// ชิปหมวดหมู่เลื่อนแนวนอน การ์ดร้านแบบตาราง และแถบเมนูแคปซูลลอย
class BuyerShell extends StatefulWidget {
  const BuyerShell({super.key});

  @override
  State<BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends State<BuyerShell> {
  int _tab = 0;

  /// ให้หน้าลูกสั่งสลับแท็บได้ (เช่นกดช่องค้นหาบนหน้าแรก)
  void goToTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    return FloatingNavScaffold(
      // IndexedStack เก็บตำแหน่งเลื่อนของแต่ละแท็บไว้ สลับแท็บแล้วไม่เด้งกลับบนสุด
      body: IndexedStack(
        index: _tab,
        children: const [_BuyerHome(), _BuyerSearch(), _BuyerMap(), _BuyerProfile()],
      ),
      navBar: FloatingNavBar(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
        items: const [
          NavItem(Icons.home_outlined, 'หน้าแรก', activeIcon: Icons.home_rounded),
          NavItem(Icons.search_rounded, 'ค้นหา'),
          NavItem(Icons.map_outlined, 'แผนที่', activeIcon: Icons.map_rounded),
          NavItem(Icons.person_outline_rounded, 'โปรไฟล์', activeIcon: Icons.person_rounded),
        ],
      ),
    );
  }
}

/// หมวดหมู่ทั้งหมดที่มีร้านอยู่จริง (เรียงตามจำนวนร้าน) — ไม่ต้อง hardcode
List<String> _categories(List<Shop> shops) {
  final count = <String, int>{};
  for (final s in shops) {
    final c = s.category.trim();
    if (c.isEmpty) continue;
    count[c] = (count[c] ?? 0) + 1;
  }
  final cats = count.keys.toList()..sort((a, b) => count[b]!.compareTo(count[a]!));
  return ['ทั้งหมด', ...cats];
}

/// รูปตัวแทนของหมวด = รูปร้านคะแนนสูงสุดในหมวดนั้น (ชิปจะได้มีภาพเหมือนหน้าร้านจริง)
String _categoryThumb(List<Shop> shops, String cat) {
  final inCat = shops.where((s) => cat == 'ทั้งหมด' || s.category == cat).toList()
    ..sort((a, b) => b.rating.compareTo(a.rating));
  for (final s in inCat) {
    if (s.hasImage) return s.imageUrl;
  }
  return '';
}

IconData _categoryIcon(String cat) {
  switch (cat) {
    case 'ทั้งหมด':
      return Icons.grid_view_rounded;
    case 'อาหาร':
      return Icons.ramen_dining_rounded;
    case 'ผักสด':
    case 'ผลไม้':
    case 'ผัก / ผลไม้':
      return Icons.eco_rounded;
    case 'เครื่องดื่ม':
      return Icons.local_cafe_rounded;
    case 'ประมง':
      return Icons.set_meal_rounded;
    case 'ของแห้ง':
      return Icons.inventory_2_rounded;
    case 'ของใช้':
      return Icons.shopping_bag_rounded;
    default:
      return Icons.storefront_rounded;
  }
}

/// ตารางร้าน 2 คอลัมน์ (sliver) — ใช้ซ้ำทั้งหน้าแรกและหน้าค้นหา
SliverGrid _shopGrid(List<Shop> shops) {
  return SliverGrid(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 22,
      childAspectRatio: 0.62,
    ),
    delegate: SliverChildBuilderDelegate(
      (_, i) => ShopTile(shop: shops[i]),
      childCount: shops.length,
    ),
  );
}

// ---------------- HOME ----------------
class _BuyerHome extends StatefulWidget {
  const _BuyerHome();

  @override
  State<_BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<_BuyerHome> {
  String _cat = 'ทั้งหมด';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final shops = appState.shops;
        final cats = _categories(shops);
        if (!cats.contains(_cat)) _cat = 'ทั้งหมด';

        final listed = _cat == 'ทั้งหมด'
            ? shops
            : shops.where((s) => s.category == _cat).toList();
        final top = [...shops]..sort((a, b) => b.rating.compareTo(a.rating));
        // เฉลี่ยจากร้านที่มีรีวิวจริงเท่านั้น ร้านที่ยังไม่มีใครรีวิวไม่ควรถ่วงค่าเฉลี่ย
        final rated = shops.where((s) => s.hasRating).toList();
        final avg = rated.isEmpty
            ? 0.0
            : rated.map((s) => s.rating).reduce((a, b) => a + b) / rated.length;
        final banners = appState.activeBanners;
        final heroImage = banners.isNotEmpty && banners.first.hasImage
            ? banners.first.imageUrl
            : (top.isNotEmpty ? top.first.imageUrl : '');

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: HeroHeader(
                imageUrl: heroImage,
                title: 'Maejo Market',
                subtitle: shops.isEmpty
                    ? 'ตลาดแม่โจ้'
                    : (rated.isEmpty
                        ? '${shops.length} ร้านค้า'
                        : '${avg.toStringAsFixed(1)} ★ · ${shops.length} ร้านค้า'),
                leadingActions: const [ThemeToggleCircleButton()],
                trailingActions: [
                  CircleIconButton(
                    Icons.favorite_border_rounded,
                    tooltip: 'ร้านที่ติดตาม',
                    onTap: () => appState.isGuest
                        ? promptSignIn(context, 'การติดตามร้าน')
                        : Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                  ),
                  const NotificationCircleButton(),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _CategoryBar(
                categories: cats,
                selected: _cat,
                thumb: (c) => _categoryThumb(shops, c),
                onSelect: (c) => setState(() => _cat = c),
                topInset: MediaQuery.of(context).padding.top,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              sliver: SliverList.list(
                children: staggered([
                  const _HomeSearchBox(),
                  if (appState.isGuest) ...[
                    const SizedBox(height: 12),
                    const GuestBanner(),
                  ],
                  const SizedBox(height: 18),
                  if (top.isNotEmpty)
                    SoftPanel(
                      title: 'แนะนำสำหรับคุณ',
                      child: SizedBox(
                        height: 250,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: top.length > 8 ? 8 : top.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) =>
                              SizedBox(width: 152, child: ShopTile(shop: top[i])),
                        ),
                      ),
                    ),
                  if (banners.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const BannerCarousel(),
                  ],
                  const SizedBox(height: 26),
                  PageHeading(_cat == 'ทั้งหมด' ? 'ร้านค้าทั้งหมด' : _cat),
                  const SizedBox(height: 4),
                  Text('${listed.length} ร้าน',
                      style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(height: 14),
                ]),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, navBarInset(context)),
              sliver: listed.isEmpty
                  ? SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.storefront_outlined,
                        message: 'ยังไม่มีร้านในหมวดนี้',
                      ),
                    )
                  : _shopGrid(listed),
            ),
          ],
        );
      },
    );
  }
}

/// ช่องค้นหาบนหน้าแรก — กดแล้วกระโดดไปแท็บค้นหา
class _HomeSearchBox extends StatelessWidget {
  const _HomeSearchBox();

  @override
  Widget build(BuildContext context) {
    return SearchPill(
      onTap: () => context.findAncestorStateOfType<_BuyerShellState>()?.goToTab(1),
    );
  }
}

/// แถบชิปหมวดหมู่ที่ค้างอยู่บนสุดเวลาเลื่อน (พื้นหลังค่อย ๆ ทึบขึ้น)
///
/// ความสูงเผื่อแถบสถานะไว้ด้วย เวลาแถบค้างบนสุดชิปจะได้ไม่ไปซ้อนกับนาฬิกา
class _CategoryBar extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selected;
  final String Function(String) thumb;
  final ValueChanged<String> onSelect;
  final double topInset;

  _CategoryBar({
    required this.categories,
    required this.selected,
    required this.thumb,
    required this.onSelect,
    required this.topInset,
  });

  static const double _barHeight = 76;

  @override
  double get minExtent => _barHeight + topInset;
  @override
  double get maxExtent => _barHeight + topInset;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / 40).clamp(0.0, 1.0);
    return Container(
      color: AppColors.bg.withValues(alpha: t),
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: _barHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          clipBehavior: Clip.none,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final c = categories[i];
            return Center(
              child: CategoryPill(
                label: c,
                icon: _categoryIcon(c),
                imageUrl: thumb(c),
                selected: c == selected,
                onTap: () => onSelect(c),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryBar old) =>
      old.selected != selected ||
      old.categories.length != categories.length ||
      old.topInset != topInset;
}

// ---------------- SEARCH ----------------
class _BuyerSearch extends StatefulWidget {
  const _BuyerSearch();

  @override
  State<_BuyerSearch> createState() => _BuyerSearchState();
}

class _BuyerSearchState extends State<_BuyerSearch> {
  String _q = '';
  String _cat = 'ทั้งหมด';
  String _sort = 'rating'; // rating | name
  bool _favOnly = false;
  bool _openOnly = false;

  List<Shop> _filtered() {
    final ql = _q.trim().toLowerCase();
    final shops = appState.shops.where((s) {
      final okQ = ql.isEmpty ||
          s.name.toLowerCase().contains(ql) ||
          s.stallId.toLowerCase().contains(ql) ||
          s.category.toLowerCase().contains(ql) ||
          s.ownerName.toLowerCase().contains(ql);
      final okC = _cat == 'ทั้งหมด' || s.category == _cat;
      final okF = !_favOnly || appState.isFavorite(s.id);
      final okO = !_openOnly || s.status == 'open';
      return okQ && okC && okF && okO;
    }).toList();
    if (_sort == 'name') {
      shops.sort((a, b) => a.name.compareTo(b.name));
    } else {
      shops.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return shops;
  }

  Future<void> _openSortMenu() async {
    final v = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: Icon(Icons.star_rounded, color: AppColors.accent),
              title: const Text('คะแนนสูงสุด'),
              trailing: _sort == 'rating' ? Icon(Icons.check_rounded, color: AppColors.primary) : null,
              onTap: () => Navigator.pop(context, 'rating'),
            ),
            ListTile(
              leading: Icon(Icons.sort_by_alpha_rounded, color: AppColors.primary),
              title: const Text('ชื่อ ก–ฮ'),
              trailing: _sort == 'name' ? Icon(Icons.check_rounded, color: AppColors.primary) : null,
              onTap: () => Navigator.pop(context, 'name'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (v != null) setState(() => _sort = v);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final cats = _categories(appState.shops);
        if (!cats.contains(_cat)) _cat = 'ทั้งหมด';
        final shops = _filtered();

        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: SearchPill(onChanged: (v) => setState(() => _q = v)),
              ),
              // แถวตัวกรอง: ปุ่มกลมทึบ + ชิปเงื่อนไข (แบบเดียวกับหน้าค้นหาในแอปช้อปปิ้ง)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    CircleIconButton(Icons.tune_rounded,
                        size: 40, solid: true, tooltip: 'เรียงลำดับ', onTap: _openSortMenu),
                    const SizedBox(width: 8),
                    FilterPill(_sort == 'name' ? 'ชื่อ ก–ฮ' : 'คะแนนสูงสุด',
                        dropdown: true, onTap: _openSortMenu),
                    const SizedBox(width: 8),
                    if (appState.isLoggedIn) ...[
                      FilterPill('ร้านที่ติดตาม',
                          selected: _favOnly,
                          icon: Icons.favorite_rounded,
                          onTap: () => setState(() => _favOnly = !_favOnly)),
                      const SizedBox(width: 8),
                    ],
                    FilterPill('เปิดขายอยู่',
                        selected: _openOnly,
                        onTap: () => setState(() => _openOnly = !_openOnly)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => Center(
                    child: CategoryPill(
                      label: cats[i],
                      icon: _categoryIcon(cats[i]),
                      imageUrl: _categoryThumb(appState.shops, cats[i]),
                      selected: cats[i] == _cat,
                      onTap: () => setState(() => _cat = cats[i]),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(children: [
                  Text('พบ ${shops.length} ร้าน',
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
              Expanded(
                child: shops.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            _favOnly ? 'ยังไม่มีร้านโปรดที่ตรงเงื่อนไข' : 'ไม่พบร้านค้าที่ค้นหา',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, navBarInset(context)),
                            sliver: _shopGrid(shops),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------- MAP ----------------
class _BuyerMap extends StatefulWidget {
  const _BuyerMap();

  @override
  State<_BuyerMap> createState() => _BuyerMapState();
}

class _BuyerMapState extends State<_BuyerMap> {
  Stall? _sel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, navBarInset(context)),
        children: [
          const PageHeading('แผนที่ตลาด'),
          const SizedBox(height: 4),
          Text('แตะที่แผงเพื่อดูว่าใครขายอะไรอยู่ตรงไหน (ผังนี้แสดงเฉพาะแผงที่มีร้าน)',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 16),
          AppCard(
            child: MarketMap(
              stalls: appState.stalls,
              selectedId: _sel?.id,
              hideEmpty: true,
              onTap: (s) => setState(() => _sel = s),
            ),
          ),
          if (_sel != null) ...[
            const SizedBox(height: 14),
            StallInfoCard(stall: _sel!),
          ],
        ],
      ),
    );
  }
}

// ---------------- PROFILE ----------------
class _BuyerProfile extends StatelessWidget {
  const _BuyerProfile();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(bottom: false, child: ProfileTab());
  }
}
