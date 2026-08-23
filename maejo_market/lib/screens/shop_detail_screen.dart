import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'market_map_screen.dart';

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
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    final r = await appState.fetchReviewsFor(widget.shop.id);
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
      showSnack(context, 'เข้าสู่ระบบเพื่อติดตามร้าน');
      return;
    }
    final nowFav = await appState.toggleFavorite(widget.shop.id);
    if (!mounted) return;
    setState(() {});
    showSnack(context, nowFav ? 'ติดตามร้าน ${widget.shop.name} แล้ว ❤️' : 'เลิกติดตามแล้ว');
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                tooltip: appState.isFavorite(shop.id) ? 'เลิกติดตาม' : 'ติดตามร้าน',
                onPressed: _toggleFav,
                icon: Icon(
                  appState.isFavorite(shop.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: appState.isFavorite(shop.id) ? AppColors.bad : Colors.white,
                ),
              ),
              SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: shop.hasImage
                  ? Image.network(
                      shop.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(gradient: brandGradient),
                        child: Center(child: Icon(shop.icon, color: Colors.white, size: 76)),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(gradient: brandGradient),
                      child: Center(child: Icon(shop.icon, color: Colors.white, size: 76)),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(shop.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                    StatusPill('ร้านแนะนำ', tone: 'ok'),
                  ]),
                  SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
                    SizedBox(width: 4),
                    Text(
                      count > 0 ? '${headerRating.toStringAsFixed(1)}  ($count รีวิว)' : 'ยังไม่มีรีวิว',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ]),
                  SizedBox(height: 10),
                  _infoRow(Icons.access_time_rounded, shop.hoursLabel),
                  _infoRow(Icons.place_outlined, shop.hasStall ? 'โซน ${shop.zone} · แผง ${shop.stallId}' : 'ยังไม่จองแผง'),
                  _infoRow(Icons.sell_outlined, 'หมวด: ${shop.category}'),
                  if (shop.description.trim().isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(shop.description, style: TextStyle(fontSize: 13.5, height: 1.4)),
                  ],
                  SectionTitle('เมนู / สินค้า', icon: Icons.restaurant_menu_rounded),
                  FutureBuilder<List<Product>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final items = snap.data ?? [];
                      if (items.isEmpty) {
                        return AppCard(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('ยังไม่มีเมนู/สินค้า', style: TextStyle(color: AppColors.muted)),
                          ),
                        );
                      }
                      return Column(
                        children: items
                            .map((p) => Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: AppCard(
                                    padding: EdgeInsets.all(12),
                                    child: Row(children: [
                                      NetImage(url: p.imageUrl, fallback: Icons.restaurant_rounded, width: 44, height: 44, radius: 12),
                                      SizedBox(width: 12),
                                      Expanded(child: Text(p.name, style: TextStyle(fontWeight: FontWeight.w700))),
                                      if (!p.available)
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: StatusPill('หมด', tone: 'bad'),
                                        ),
                                      Text('฿${p.price.toStringAsFixed(0)}',
                                          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                                    ]),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),

                  // ---------------- รีวิว ----------------
                  SectionTitle('รีวิวจากลูกค้า', icon: Icons.reviews_rounded),
                  _reviewSummary(count),
                  SizedBox(height: 12),
                  if (_loadingReviews)
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_reviews.isEmpty)
                    AppCard(
                      child: Row(children: [
                        Icon(Icons.rate_review_outlined, color: AppColors.muted),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('ยังไม่มีรีวิว เป็นคนแรกที่รีวิวร้านนี้เลย!',
                              style: TextStyle(color: AppColors.muted)),
                        ),
                      ]),
                    )
                  else
                    Column(children: _reviews.map(_reviewCard).toList()),

                  SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (!shop.hasStall) {
                            showSnack(context, 'ร้านนี้ยังไม่ได้จองแผง');
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MarketMapScreen(focusStallId: shop.stallId)),
                          );
                        },
                        icon: Icon(Icons.map_outlined),
                        label: Text('ดูแผนที่'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: appState.isFavorite(shop.id)
                          ? OutlinedButton.icon(
                              onPressed: _toggleFav,
                              icon: Icon(Icons.check_rounded),
                              label: Text('กำลังติดตาม'),
                            )
                          : ElevatedButton.icon(
                              onPressed: _toggleFav,
                              icon: Icon(Icons.add),
                              label: Text('ติดตามร้าน'),
                            ),
                    ),
                  ]),
                ],
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
    return AppCard(
      child: Row(children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(count > 0 ? _avg.toStringAsFixed(1) : '–',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.text, height: 1.1)),
            _StarRow(rating: count > 0 ? _avg : 0, size: 15),
            SizedBox(height: 2),
            Text('$count รีวิว', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ],
        ),
        SizedBox(width: 18),
        Expanded(
          child: _canReview
              ? SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openWriteSheet,
                    icon: Icon(mine == null ? Icons.rate_review_rounded : Icons.edit_rounded, size: 18),
                    label: Text(mine == null ? 'เขียนรีวิว' : 'แก้ไขรีวิวของฉัน'),
                  ),
                )
              : Text(
                  appState.isLoggedIn ? 'นี่คือร้านของคุณ' : 'เข้าสู่ระบบเพื่อรีวิว',
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
        ),
      ]),
    );
  }

  Widget _reviewCard(Review r) {
    final mine = r.uid == appState.user?.uid;
    final initial = r.authorName.trim().isEmpty ? '?' : r.authorName.characters.first;
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.leafSoft,
                child: Text(initial,
                    style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(r.authorName.isEmpty ? 'ผู้ใช้' : r.authorName,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (mine) ...[
                        SizedBox(width: 6),
                        StatusPill('ของฉัน', tone: 'ok'),
                      ],
                    ]),
                    SizedBox(height: 2),
                    Row(children: [
                      _StarRow(rating: r.rating.toDouble(), size: 13),
                      if (r.createdAt > 0) ...[
                        SizedBox(width: 6),
                        Text(_timeAgo(r.createdAt), style: TextStyle(fontSize: 11, color: AppColors.faint)),
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
              SizedBox(height: 8),
              Text(r.comment, style: TextStyle(fontSize: 13.5, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.muted),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ]),
      );
}

/// แถวดาว (อ่านอย่างเดียว) รองรับครึ่งดาว
class _StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const _StarRow({required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final pos = i + 1;
        IconData ic;
        if (rating >= pos) {
          ic = Icons.star_rounded;
        } else if (rating >= pos - 0.5) {
          ic = Icons.star_half_rounded;
        } else {
          ic = Icons.star_border_rounded;
        }
        return Icon(ic, size: size, color: AppColors.accent);
      }),
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
          SizedBox(height: 16),
          Text(widget.existing == null ? 'ให้คะแนนร้าน' : 'แก้ไขรีวิว',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          SizedBox(height: 2),
          Text(widget.shop.name, style: TextStyle(color: AppColors.muted, fontSize: 13)),
          SizedBox(height: 16),
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
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        _rating >= pos ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 40,
                        color: AppColors.accent,
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 4),
              Text(_labels[_rating],
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ]),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _c,
            maxLines: 4,
            maxLength: 300,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'เล่าประสบการณ์ของคุณ (ไม่บังคับ)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.send_rounded, size: 18),
              label: Text(_busy ? 'กำลังส่ง...' : 'ส่งรีวิว'),
            ),
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
