import '../../widgets/banner_carousel.dart';
import 'package:flutter/material.dart';
import '../../models/shop.dart';
import '../../models/stall.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/animations.dart';
import '../../widgets/market_map.dart';
import '../../widgets/notification_button.dart';
import '../../theme/theme_controller.dart';
import '../profile_tab.dart';
import '../shop_detail_screen.dart';

class BuyerShell extends StatefulWidget {
  BuyerShell({super.key});

  @override
  State<BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends State<BuyerShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [_BuyerHome(), _BuyerSearch(), _BuyerMap(), ProfileTab()];
    final titles = ['Maejo Market', 'ค้นหาร้านค้า', 'แผนที่ตลาดแม่โจ้', 'บัญชีของฉัน'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        automaticallyImplyLeading: false,
        actions: const [ThemeToggleButton(), NotificationButton()],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'หน้าแรก'),
          NavigationDestination(icon: Icon(Icons.search_rounded), label: 'ค้นหา'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'แผนที่'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}

// ---------------- HOME ----------------
class _BuyerHome extends StatelessWidget {
  const _BuyerHome();

  @override
  Widget build(BuildContext context) {
    final shops = appState.shops;
    final cats = [
      ('อาหาร', Icons.ramen_dining_rounded, AppColors.accent),
      ('ผัก / ผลไม้', Icons.eco_rounded, AppColors.primary),
      ('เครื่องดื่ม', Icons.local_cafe_rounded, Color(0xFF8D6E63)),
      ('ของใช้', Icons.shopping_bag_outlined, Color(0xFF5C6BC0)),
    ];
    return ListView(
      padding: EdgeInsets.all(16),
      children: staggered([
        const _SearchBox(),
        SizedBox(height: 16),
        const BannerCarousel(),
        SectionTitle('หมวดหมู่', icon: Icons.grid_view_rounded),
        Row(
          children: cats
              .map((c) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Column(children: [
                        IconChip(c.$2, color: c.$3, bg: c.$3.withOpacity(0.12), size: 52),
                        SizedBox(height: 6),
                        Text(c.$1, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ))
              .toList(),
        ),
        SectionTitle('ร้านแนะนำ', icon: Icons.star_rounded, trailing: _SeeAll()),
        ...shops.take(4).map((s) => Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: ShopRow(shop: s),
            )),
      ]),
    );
  }
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
      return okQ && okC && okF;
    }).toList();
    if (_sort == 'name') {
      shops.sort((a, b) => a.name.compareTo(b.name));
    } else {
      shops.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return shops;
  }

  @override
  Widget build(BuildContext context) {
    final cats = ['ทั้งหมด', 'อาหาร', 'ผักสด', 'ผลไม้', 'ผัก / ผลไม้', 'ประมง', 'เครื่องดื่ม'];
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _SearchBox(onChanged: (v) => setState(() => _q = v)),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            children: cats.map((c) {
              final on = c == _cat;
              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: on,
                  onSelected: (_) => setState(() => _cat = c),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: on ? Colors.white : AppColors.muted, fontWeight: FontWeight.w600),
                  backgroundColor: AppColors.surface,
                  side: BorderSide(color: AppColors.border),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: appState,
            builder: (_, __) {
              final shops = _filtered();
              return Column(
                children: [
                  // แถบผลลัพธ์ + ตัวกรอง/เรียงลำดับ
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 8, 4),
                    child: Row(children: [
                      Text('พบ ${shops.length} ร้าน',
                          style: TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      Spacer(),
                      if (appState.isLoggedIn)
                        FilterChip(
                          label: Text('โปรด'),
                          avatar: Icon(
                            _favOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 16,
                            color: _favOnly ? Colors.white : AppColors.bad,
                          ),
                          selected: _favOnly,
                          onSelected: (v) => setState(() => _favOnly = v),
                          selectedColor: AppColors.bad,
                          labelStyle: TextStyle(
                              color: _favOnly ? Colors.white : AppColors.muted, fontWeight: FontWeight.w600, fontSize: 12.5),
                          backgroundColor: AppColors.surface,
                          side: BorderSide(color: AppColors.border),
                          visualDensity: VisualDensity.compact,
                        ),
                      PopupMenuButton<String>(
                        tooltip: 'เรียงลำดับ',
                        onSelected: (v) => setState(() => _sort = v),
                        itemBuilder: (_) => [
                          CheckedPopupMenuItem(value: 'rating', checked: _sort == 'rating', child: Text('คะแนนสูงสุด')),
                          CheckedPopupMenuItem(value: 'name', checked: _sort == 'name', child: Text('ชื่อ ก–ฮ')),
                        ],
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.swap_vert_rounded, size: 18, color: AppColors.primary),
                            SizedBox(width: 2),
                            Text(_sort == 'name' ? 'ชื่อ' : 'คะแนน',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: shops.isEmpty
                        ? Center(child: Text(
                            _favOnly ? 'ยังไม่มีร้านโปรดที่ตรงเงื่อนไข' : 'ไม่พบร้านค้าที่ค้นหา',
                            style: TextStyle(color: AppColors.muted)))
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: shops.length,
                            separatorBuilder: (_, __) => SizedBox(height: 10),
                            itemBuilder: (_, i) => ShopRow(shop: shops[i]),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
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
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        AppCard(
          child: MarketMap(
            stalls: appState.stalls,
            selectedId: _sel?.id,
            // ผู้บริโภคสนใจว่า "จะไปซื้ออะไร" มากกว่าเลขโซน จึงแยกตามหมวด
            grouping: MapGrouping.category,
            onTap: (s) => setState(() => _sel = s),
          ),
        ),
        if (_sel != null) ...[
          SizedBox(height: 14),
          AppCard(
            child: Row(children: [
              IconChip(Icons.storefront_rounded,
                  color: AppColors.primary, bg: AppColors.leafSoft),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('แผง ${_sel!.id}${_sel!.shopName != null ? " · ${_sel!.shopName}" : ""}',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                        _sel!.isEmpty
                            ? 'แผงว่าง · ${_sel!.positionLabel}'
                            : '${_sel!.categoryLabel} · ${_sel!.positionLabel}',
                        style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                  ],
                ),
              ),
              StatusPill(
                _sel!.isEmpty ? 'ว่าง' : (_sel!.status == 'due' ? 'ค้างชำระ' : (_sel!.status == 'closed' ? 'ปิดปรับปรุง' : 'เปิดขาย')),
                tone: _sel!.isEmpty ? 'muted' : (_sel!.status == 'due' ? 'warn' : (_sel!.status == 'closed' ? 'bad' : 'ok')),
              ),
            ]),
          ),
        ],
      ],
    );
  }
}

// ---------------- shared bits ----------------
class _SearchBox extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  const _SearchBox({this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      readOnly: onChanged == null,
      decoration: InputDecoration(
        hintText: 'ค้นหาร้านค้า / สินค้า…',
        prefixIcon: Icon(Icons.search_rounded),
        contentPadding: EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }
}

class _SeeAll extends StatelessWidget {
  const _SeeAll();
  @override
  Widget build(BuildContext context) {
    return Text('ดูทั้งหมด',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12.5));
  }
}

class ShopRow extends StatelessWidget {
  final Shop shop;
  ShopRow({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(12),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop))),
      child: Row(children: [
        NetImage(url: shop.imageUrl, fallback: shop.icon, width: 52, height: 52, radius: 14),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shop.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(6)),
                  child: Text(shop.hasStall ? shop.stallId : 'รอจองแผง', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                SizedBox(width: 6),
                Text(shop.hasStall ? 'โซน ${shop.zone} · ${shop.category}' : shop.category,
                    style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
              ]),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(children: [
              Icon(Icons.star_rounded, size: 15, color: AppColors.accent),
              SizedBox(width: 2),
              Text('${shop.rating}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
            ]),
            ListenableBuilder(
              listenable: appState,
              builder: (_, __) {
                if (!appState.isLoggedIn) return SizedBox(height: 4);
                final fav = appState.isFavorite(shop.id);
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => appState.toggleFavorite(shop.id),
                  child: Padding(
                    padding: EdgeInsets.only(top: 6, left: 8),
                    child: Icon(
                      fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 20,
                      color: fav ? AppColors.bad : AppColors.faint,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ]),
    );
  }
}
