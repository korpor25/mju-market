import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../services/visit_history.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/guest_gate.dart';
import '../widgets/shop_cards.dart';
import '../widgets/shop_ui.dart';
import 'market_map_screen.dart';

/// หน้าร้าน — รูปปกเต็มความกว้าง ปุ่มกลมลอยทับรูป ชื่อร้านกลางภาพ
/// สินค้าเป็นตาราง 2 คอลัมน์ และแถบปุ่มลอยด้านล่าง (ย้อนกลับ/ติดตาม/แผนที่)
class ShopDetailScreen extends StatefulWidget {
  final Shop shop;
  const ShopDetailScreen({super.key, required this.shop});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late Future<List<Product>> _future;
  List<Review> _reviews = [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _future = appState.fetchProductsFor(widget.shop.id);
    _loadReviews();
    // เก็บไว้ในเครื่องเท่านั้น ผู้เยี่ยมชมที่ยังไม่ลงทะเบียนก็มีประวัติของตัวเอง
    VisitHistory.record(widget.shop);
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    // โหลดไม่ได้ (เน็ตหลุด/สิทธิ์ไม่พอ) ก็ให้แสดงว่า "ยังไม่มีรีวิว" แทนที่จะค้างหมุน
    List<Review> r;
    try {
      r = await appState.fetchReviewsFor(widget.shop.id);
    } catch (e) {
      debugPrint('fetchReviewsFor failed: $e');
      r = [];
    }
    if (!mounted) return;
    setState(() {
      _reviews = r;
      _loadingReviews = false;
    });
  }

  double get _avg => _reviews.isEmpty
      ? 0
      : _reviews.map((e) => e.rating).reduce((a, b) => a + b) / _reviews.length;

  Review? get _myReview {
    final uid = appState.user?.uid;
    if (uid == null) return null;
    for (final r in _reviews) {
      if (r.uid == uid) return r;
    }
    return null;
  }

  bool get _canReview =>
      appState.isLoggedIn && appState.user!.uid != widget.shop.ownerUid;

  Future<void> _openWriteSheet() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReviewSheet(shop: widget.shop, existing: _myReview),
    );
    if (ok == true) {
      if (mounted) showSnack(context, 'ขอบคุณสำหรับรีวิว 🙏');
      await _loadReviews();
    }
  }

  Future<void> _toggleFav() async {
    if (!appState.isLoggedIn) {
      await promptSignIn(context, 'การติดตามร้าน');
      return;
    }
    final nowFav = await appState.toggleFavorite(widget.shop.id);
    if (!mounted) return;
    setState(() {});
    showSnack(context, nowFav ? 'ติดตามร้าน ${widget.shop.name} แล้ว ❤️' : 'เลิกติดตามแล้ว');
  }

  void _openMap() {
    if (!widget.shop.hasStall) {
      showSnack(context, 'ร้านนี้ยังไม่ได้จองแผง');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MarketMapScreen(focusStallId: widget.shop.stallId)),
    );
  }

  Future<void> _deleteMyReview(Review r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบรีวิว'),
        content: const Text('ต้องการลบรีวิวของคุณใช่ไหม?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (ok != true) return;
    await appState.deleteReview(r.id, widget.shop.id);
    if (mounted) showSnack(context, 'ลบรีวิวแล้ว');
    await _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final count = _reviews.length;
    final headerRating = count > 0 ? _avg : shop.rating;
    final fav = appState.isFavorite(shop.id);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: HeroHeader(
                  imageUrl: shop.imageUrl,
                  fallbackIcon: shop.icon,
                  title: shop.name,
                  subtitle: count > 0
                      ? '${headerRating.toStringAsFixed(1)} ★ ($count รีวิว)'
                      : 'ยังไม่มีรีวิว · ${shop.category}',
                  height: 290,
                  leadingActions: [
                    CircleIconButton(Icons.arrow_back_rounded,
                        tooltip: 'ย้อนกลับ', onTap: () => Navigator.pop(context)),
                  ],
                  trailingActions: [
                    PillButton(
                      fav ? 'กำลังติดตาม' : 'ติดตาม',
                      icon: fav ? Icons.check_rounded : Icons.add_rounded,
                      onTap: _toggleFav,
                    ),
                  ],
                ),
              ),

              // ---- ข้อมูลร้านแบบชิปเรียงแนวนอน ----
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(Icons.access_time_rounded, shop.hoursLabel),
                          _InfoChip(
                              Icons.place_outlined,
                              shop.hasStall
                                  ? 'โซน ${shop.zone} · แผง ${shop.stallId}'
                                  : 'ยังไม่จองแผง'),
                          _InfoChip(Icons.sell_outlined, shop.category),
                          if (shop.status == 'closed')
                            StatusPill('ปิดปรับปรุง', tone: 'bad')
                          else
                            StatusPill('เปิดขาย', tone: 'ok'),
                        ],
                      ),
                      if (shop.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(shop.description,
                            style: const TextStyle(fontSize: 14, height: 1.5)),
                      ],
                      const SizedBox(height: 24),
                      const PageHeading('เมนู / สินค้า'),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // ---- สินค้าแบบตาราง ----
              FutureBuilder<List<Product>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: EmptyState(
                          icon: Icons.restaurant_menu_rounded,
                          message: 'ยังไม่มีเมนู/สินค้าในร้านนี้',
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.74,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => ProductTile(product: items[i]),
                        childCount: items.length,
                      ),
                    ),
                  );
                },
              ),

              // ---- รีวิว ----
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 28, 16, navBarInset(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PageHeading('รีวิวจากลูกค้า'),
                      const SizedBox(height: 14),
                      _reviewSummary(count),
                      const SizedBox(height: 14),
                      if (_loadingReviews)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_reviews.isEmpty)
                        EmptyState(
                          icon: Icons.rate_review_outlined,
                          message: 'ยังไม่มีรีวิว เป็นคนแรกที่รีวิวร้านนี้เลย!',
                        )
                      else
                        Column(children: _reviews.map(_reviewCard).toList()),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ---- แถบปุ่มลอยล่างจอ ----
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(children: [
                  CircleIconButton(Icons.arrow_back_rounded,
                      size: 52, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PillButton(
                      shop.hasStall ? 'พาไปที่แผง ${shop.stallId}' : 'ดูแผนผังตลาด',
                      icon: Icons.map_rounded,
                      filled: true,
                      height: 52,
                      onTap: _openMap,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // สรุปคะแนนเฉลี่ย + ปุ่มเขียนรีวิว
  Widget _reviewSummary(int count) {
    final mine = _myReview;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(kPanelRadius),
      ),
      child: Row(children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(count > 0 ? _avg.toStringAsFixed(1) : '–',
                style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    height: 1.1)),
            StarRow(rating: count > 0 ? _avg : 0, size: 16),
            const SizedBox(height: 2),
            Text('$count รีวิว', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _canReview
              ? PillButton(
                  mine == null ? 'เขียนรีวิว' : 'แก้ไขรีวิวของฉัน',
                  icon: mine == null ? Icons.rate_review_rounded : Icons.edit_rounded,
                  filled: true,
                  onTap: _openWriteSheet,
                )
              : appState.isLoggedIn
                  // ผู้เยี่ยมชมกดได้เลย แล้วค่อยชวนเข้าสู่ระบบ ดีกว่าบอกเฉย ๆ ว่าต้องล็อกอิน
                  ? Text('นี่คือร้านของคุณ',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5))
                  : PillButton(
                      'เข้าสู่ระบบเพื่อรีวิว',
                      icon: Icons.login_rounded,
                      onTap: () => promptSignIn(context, 'การเขียนรีวิว'),
                    ),
        ),
      ]),
    );
  }

  Widget _reviewCard(Review r) {
    final mine = r.uid == appState.user?.uid;
    final initial = r.authorName.trim().isEmpty ? '?' : r.authorName.characters.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.leafSoft,
                child: Text(initial,
                    style: TextStyle(
                        color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(r.authorName.isEmpty ? 'ผู้ใช้' : r.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (mine) ...[
                        const SizedBox(width: 6),
                        StatusPill('ของฉัน', tone: 'ok'),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      StarRow(rating: r.rating.toDouble(), size: 13),
                      if (r.createdAt > 0) ...[
                        const SizedBox(width: 6),
                        Text(_timeAgo(r.createdAt),
                            style: TextStyle(fontSize: 11, color: AppColors.faint)),
                      ],
                    ]),
                  ],
                ),
              ),
              if (mine)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _deleteMyReview(r),
                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.muted),
                ),
            ]),
            if (r.comment.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r.comment, style: const TextStyle(fontSize: 13.5, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}

/// ชิปข้อมูลเล็ก ๆ ใต้รูปปก (เวลาเปิด/ที่ตั้ง/หมวด)
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(kPillRadius),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(fontSize: 12.5, color: AppColors.text, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Bottom sheet สำหรับเขียน/แก้ไขรีวิว
class _ReviewSheet extends StatefulWidget {
  final Shop shop;
  final Review? existing;
  const _ReviewSheet({required this.shop, this.existing});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late int _rating = widget.existing?.rating ?? 5;
  late final TextEditingController _c =
      TextEditingController(text: widget.existing?.comment ?? '');
  bool _busy = false;

  static const _labels = ['', 'แย่', 'พอใช้', 'ปานกลาง', 'ดี', 'ยอดเยี่ยม'];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final err = await appState.addReview(widget.shop.id, _rating, _c.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      showSnack(context, err);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.existing == null ? 'ให้คะแนนร้าน' : 'แก้ไขรีวิว',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(widget.shop.name, style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 16),
          // ดาวแบบกดเลือก
          Center(
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final pos = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = pos),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        _rating >= pos ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 40,
                        color: AppColors.accent,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(_labels[_rating],
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _c,
            maxLines: 4,
            maxLength: 300,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'เล่าประสบการณ์ของคุณ (ไม่บังคับ)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          const SizedBox(height: 8),
          PillButton(
            _busy ? 'กำลังส่ง...' : 'ส่งรีวิว',
            icon: Icons.send_rounded,
            filled: true,
            height: 52,
            onTap: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}

String _timeAgo(int millis) {
  final diff = DateTime.now().millisecondsSinceEpoch - millis;
  final m = diff ~/ 60000;
  if (m < 1) return 'เมื่อสักครู่';
  if (m < 60) return '$m นาทีที่แล้ว';
  final h = m ~/ 60;
  if (h < 24) return '$h ชั่วโมงที่แล้ว';
  final d = h ~/ 24;
  return '$d วันที่แล้ว';
}
