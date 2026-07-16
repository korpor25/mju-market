import 'package:flutter/material.dart';
import '../../models/shop.dart';
import '../../models/stall.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/market_map.dart';
import '../profile_tab.dart';
import '../shop_detail_screen.dart';

class BuyerShell extends StatefulWidget {
  const BuyerShell({super.key});

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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => showSnack(context, 'ยังไม่มีการแจ้งเตือนใหม่'),
          ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
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
      ('เครื่องดื่ม', Icons.local_cafe_rounded, const Color(0xFF8D6E63)),
      ('ของใช้', Icons.shopping_bag_outlined, const Color(0xFF5C6BC0)),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SearchBox(),
        const SizedBox(height: 16),
        // แบนเนอร์
        Container(
          height: 130,
          decoration: BoxDecoration(
            gradient: brandGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('เทศกาลผักสด',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const Text('จากชุมชนแม่โจ้', style: TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: const Text('ดูเพิ่มเติม',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SectionTitle('หมวดหมู่', icon: Icons.grid_view_rounded),
        Row(
          children: cats
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(children: [
                        IconChip(c.$2, color: c.$3, bg: c.$3.withOpacity(0.12), size: 52),
                        const SizedBox(height: 6),
                        Text(c.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ))
              .toList(),
        ),
        SectionTitle('ร้านแนะนำ', icon: Icons.star_rounded, trailing: const _SeeAll()),
        ...shops.take(4).map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ShopRow(shop: s),
            )),
      ],
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

  @override
  Widget build(BuildContext context) {
    final cats = ['ทั้งหมด', 'อาหาร', 'ผักสด', 'ผลไม้', 'ผัก / ผลไม้', 'ประมง', 'เครื่องดื่ม'];
    var shops = appState.shops.where((s) {
      final okQ = _q.isEmpty ||
          s.name.contains(_q) ||
          s.stallId.toLowerCase().contains(_q.toLowerCase());
      final okC = _cat == 'ทั้งหมด' || s.category == _cat;
      return okQ && okC;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _SearchBox(onChanged: (v) => setState(() => _q = v)),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: cats.map((c) {
              final on = c == _cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: on,
                  onSelected: (_) => setState(() => _cat = c),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: on ? Colors.white : AppColors.muted, fontWeight: FontWeight.w600),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: shops.isEmpty
              ? const Center(child: Text('ไม่พบร้านค้าที่ค้นหา', style: TextStyle(color: AppColors.muted)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: shops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => ShopRow(shop: shops[i]),
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
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: MarketMap(
            stalls: appState.stalls,
            selectedId: _sel?.id,
            onTap: (s) => setState(() => _sel = s),
          ),
        ),
        if (_sel != null) ...[
          const SizedBox(height: 14),
          AppCard(
            child: Row(children: [
              IconChip(Icons.storefront_rounded,
                  color: AppColors.primary, bg: AppColors.leafSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('แผง ${_sel!.id}${_sel!.shopName != null ? " · ${_sel!.shopName}" : ""}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(_sel!.isEmpty ? 'ยังไม่มีผู้เช่า' : 'โซน ${_sel!.zone} · ${_sel!.pricePerDay}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
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
        prefixIcon: const Icon(Icons.search_rounded),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }
}

class _SeeAll extends StatelessWidget {
  const _SeeAll();
  @override
  Widget build(BuildContext context) {
    return const Text('ดูทั้งหมด',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12.5));
  }
}

class ShopRow extends StatelessWidget {
  final Shop shop;
  const ShopRow({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop))),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: AppColors.leafSoft, borderRadius: BorderRadius.circular(14)),
          alignment: Alignment.center,
          child: Text(shop.emoji, style: const TextStyle(fontSize: 26)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shop.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(6)),
                  child: Text(shop.stallId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                Text('โซน ${shop.zone} · ${shop.category}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
              ]),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(children: [
              const Icon(Icons.star_rounded, size: 15, color: AppColors.accent),
              const SizedBox(width: 2),
              Text('${shop.rating}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
            ]),
          ],
        ),
      ]),
    );
  }
}
