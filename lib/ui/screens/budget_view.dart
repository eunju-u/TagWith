import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../core/app_config.dart';
import '../widgets/app_dialog.dart';


class BudgetView extends StatefulWidget {
  const BudgetView({super.key});

  @override
  State<BudgetView> createState() => _BudgetViewState();
}

class _BudgetViewState extends State<BudgetView> {
  // 네이버 API 키 설정 (환경 설정에서 불러옵니다)
  final String _naverClientId = AppConfig.naverClientId;
  final String _naverClientSecret = AppConfig.naverClientSecret;
  final String _naverMapClientId = AppConfig.naverMapClientId;

  final _storage = const FlutterSecureStorage();
  bool _isAiRecommendEnabled = false;
  bool _isLoadingLocation = false;
  bool _isServerLunchEnabled = true; // 서버 설정값 (어드민)
  List<RecommendedStore> _recommendedStores = [];

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    // 1. 서버 설정 확인 (어드민 권한)
    await _fetchServerConfig();
    
    // 2. 서버가 허용한 경우에만 사용자의 기존 선택을 불러옵니다.
    if (_isServerLunchEnabled) {
      String? savedStatus = await _storage.read(key: 'lunch_recommend_on');
      if (savedStatus == 'true') {
        // 이전에 켜두었다면 바로 추천 로직을 실행합니다.
        await _toggleAiRecommend(true);
      }
    }
  }

  Future<void> _fetchServerConfig() async {
    final dio = Dio();
    // 5초 타임아웃 추가
    dio.options.connectTimeout = const Duration(seconds: 5);
    dio.options.receiveTimeout = const Duration(seconds: 5);

    try {
      final response = await dio.get('https://web-production-e1340.up.railway.app/system/config');
      
      if (response.statusCode == 200) {
        // 서버에서 온 데이터가 어떤 모양인지 상세히 확인합니다.
        final rawData = response.data;
        bool enabled = false;

        // 1단계: 직접 들어있는 경우
        if (rawData['lunch_recommend_active'] != null) {
          enabled = rawData['lunch_recommend_active'] == true || rawData['lunch_recommend_active'] == 'true';
        } 
        // 2단계: 'data'라는 이름으로 한 번 감싸져 있는 경우 대비
        else if (rawData['data'] != null && rawData['data']['lunch_recommend_active'] != null) {
          enabled = rawData['data']['lunch_recommend_active'] == true || rawData['data']['lunch_recommend_active'] == 'true';
        }

        if (mounted) {
          setState(() => _isServerLunchEnabled = enabled);
        }
      }
    } catch (e) {
      debugPrint('Config Fetch Error: $e');
      if (mounted) {
        setState(() => _isServerLunchEnabled = false);
      }
    }
  }

  Future<void> _toggleAiRecommend(bool value) async {
    // 1. 사용자 선택 저장 및 화면 즉시 업데이트
    await _storage.write(key: 'lunch_recommend_on', value: value.toString());
    
    if (value) {
      setState(() {
        _isAiRecommendEnabled = true; // 버튼은 즉시 켭니다!
        _isLoadingLocation = true;
      });

      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) _showErrorDialog(AppStrings.locationServiceDisabled);
          setState(() {
            _isAiRecommendEnabled = false; // 실패 시 다시 끕니다.
            _isLoadingLocation = false;
          });
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            setState(() {
              _isAiRecommendEnabled = false;
              _isLoadingLocation = false;
            });
            return;
          }
        }

        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

        String neighborhood = "";
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            neighborhood = placemarks.first.subLocality ?? placemarks.first.locality ?? "";
          }
        } catch (_) {}

        final provider = Provider.of<TransactionProvider>(context, listen: false);
        final now = DateTime.now();
        final remaining = provider.monthlyBudget - provider.getTotalExpenseByMonth(now);
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        final dailyAdvice = remaining / (lastDay - now.day + 1);

        String typeKeyword = dailyAdvice < 2500 ? AppStrings.keywordConvenience : (dailyAdvice < 15000 ? AppStrings.keywordRestaurant : AppStrings.keywordCafe);
        String finalSearchQuery = "$neighborhood $typeKeyword".trim();

        final fetchedStores = await _fetchNaverStores(finalSearchQuery);

        if (mounted) {
          setState(() {
            _recommendedStores = fetchedStores;
            _isLoadingLocation = false;
          });
        }
      } catch (e) {
        debugPrint('Naver Search Error: $e');
        if (mounted) {
          _showErrorDialog(AppStrings.locationFetchError);
          setState(() {
            _isAiRecommendEnabled = false;
            _isLoadingLocation = false;
          });
        }
      }
    } else {
      setState(() {
        _isAiRecommendEnabled = false;
        _recommendedStores = [];
      });
    }
  }

  Future<List<RecommendedStore>> _fetchNaverStores(String query) async {
    final dio = Dio();
    
    try {
      final response = await dio.get(
        'https://openapi.naver.com/v1/search/local.json',
        queryParameters: {
          'query': query,
          'display': 5,
          'sort': 'random',
        },
        options: Options(
          headers: {
            'X-Naver-Client-Id': _naverClientId.trim(),
            'X-Naver-Client-Secret': _naverClientSecret.trim(),
          },
        ),
      );

      if (response.statusCode == 200) {
        final List items = response.data['items'];
        return items.map((item) {
          String cleanTitle = (item['title'] as String).replaceAll(RegExp(r'<[^>]*>|&quot;'), '');
          return RecommendedStore(
            cleanTitle,
            (item['category'] as String).split('>').last.trim(),
            4.0,
            AppStrings.nearbyDistanceLabel,
            item['address'] ?? '',
            query.contains('편의점') ? Colors.orange : AppColors.primary,
            mapX: item['mapx'] ?? "",
            mapY: item['mapy'] ?? "",
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Naver Local API Error: $e');
    }
    return [];
  }

  void _showErrorDialog(String message) {
    AppDialog.show(
      context: context,
      title: AppStrings.warning,
      content: message,
      icon: Icons.info_outline_rounded,
      confirmText: AppStrings.ok,
      onConfirm: () {},
    );
  }

  void _showOptionDialog(String title, String message, String actionLabel, VoidCallback onAction) {
    AppDialog.show(
      context: context,
      title: title,
      content: message,
      cancelText: AppStrings.close,
      confirmText: actionLabel,
      onConfirm: onAction,
    );
  }

  Future<void> _launchNearbySearch(String query) async {
    // 앱 내 새로운 화면(KakaoMapScreen)으로 이동하여 지도 표시
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NaverMapScreen(
            query: query, 
            mapClientId: _naverMapClientId, 
            stores: _recommendedStores,
          ),
        ),
      );
    }
  }

  void _showEditBudgetDialog(BuildContext context, double currentBudget) {
    final controller = TextEditingController(text: currentBudget.toInt().toString());
    final theme = Theme.of(context);

    AppDialog.show(
      context: context,
      title: AppStrings.budgetDialogTitle,
      icon: Icons.account_balance_wallet_rounded,
      contentWidget: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        decoration: InputDecoration(
          hintText: AppStrings.budgetHint,
          suffixText: AppStrings.currencyUnit,
          filled: true,
          fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(20),
        ),
        autofocus: true,
        textAlign: TextAlign.center,
      ),
      cancelText: AppStrings.cancel,
      confirmText: AppStrings.save,
      onConfirm: () {
        final newBudget = double.tryParse(controller.text) ?? 0.0;
        Provider.of<TransactionProvider>(context, listen: false).updateMonthlyBudget(newBudget);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context);
    
    final double budgetGoal = provider.monthlyBudget;
    final currentSpending = provider.getTotalExpenseByMonth(DateTime.now());
    final remaining = budgetGoal - currentSpending;
    final progress = budgetGoal > 0 ? (currentSpending / budgetGoal).clamp(0.0, 1.0) : 1.0;
    
    final isOver = remaining < 0;
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final remainingDays = lastDayOfMonth.day - now.day + 1;
    final dailyAdvice = remaining > 0 ? remaining / remainingDays : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.budgetManagementTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showEditBudgetDialog(context, budgetGoal),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text(AppStrings.editGoalButton),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildBudgetCard(theme, budgetGoal, currentSpending, progress),
              if (_isServerLunchEnabled) ...[
                const SizedBox(height: 32),
                _buildAiRecommendToggle(theme),
                if (_isAiRecommendEnabled) ...[
                  const SizedBox(height: 24),
                  _buildAiRecommendationSection(theme, dailyAdvice),
                  const SizedBox(height: 16),
                  _buildStoreListSection(theme),
                ],
              ],
              const SizedBox(height: 40),
              _buildStatusSection(theme, currentSpending, budgetGoal, remaining, dailyAdvice, isOver),
              const SizedBox(height: 32),
              _buildTipCard(theme, progress, dailyAdvice, isOver),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetCard(ThemeData theme, double goal, double current, double progress) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.currentSpendingLabel, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        NumberFormat('#,###').format(current),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900, 
                          color: progress > 0.8 ? Colors.deepOrange : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(AppStrings.currencyUnit, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.3))),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: (progress > 0.8 ? Colors.deepOrange : AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: progress > 0.8 ? Colors.deepOrange : AppColors.primary, 
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOutExpo,
                    height: 16,
                    width: constraints.maxWidth * progress, // 박스 크기에 정확히 비례하도록 수정
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: progress > 0.8 
                            ? [Colors.orange, Colors.deepOrange]
                            : [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (progress > 0.8 ? Colors.deepOrange : AppColors.primary).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.currencyUnit, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.3))),
              Text(
                '${AppStrings.budgetGoalLabelPrefix} ${NumberFormat('#,###').format(goal)}${AppStrings.currencyUnit}', 
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(ThemeData theme, double current, double goal, double remaining, double dailyAdvice, bool isOver) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatItem(
              theme, 
              AppStrings.remainingBudgetLabel, 
              '${NumberFormat('#,###').format(remaining.abs())}${AppStrings.currencyUnit}', 
              isOver ? AppStrings.overBudgetLabel : AppStrings.canSpendLabel,
              isOver ? Colors.redAccent : Colors.green,
            ),
            const SizedBox(width: 16),
            _buildStatItem(
              theme, 
              AppStrings.dailyRecommendLabel, 
              '${NumberFormat('#,###').format(dailyAdvice.toInt())}${AppStrings.currencyUnit}', 
              AppStrings.dailySpendLimitLabel,
              AppColors.primary,
              onInfoTap: () => _showInfoDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context) {
    AppDialog.show(
      context: context,
      title: AppStrings.budgetHelpTitle,
      content: AppStrings.budgetHelpContent,
      icon: Icons.info_outline_rounded,
      confirmText: AppStrings.ok,
      onConfirm: () {},
    );
  }

  Widget _buildStatItem(ThemeData theme, String title, String value, String sub, Color color, {VoidCallback? onInfoTap}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                if (onInfoTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: onInfoTap,
                      child: Icon(Icons.info_outline_rounded, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value, 
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(sub, style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(ThemeData theme, double progress, double dailyAdvice, bool isOver) {
    String tip;
    Color tipColor = AppColors.primary;
    IconData tipIcon = Icons.lightbulb_outline_rounded;

    if (progress >= 1.0) {
      tip = AppStrings.budgetTipFull;
      tipColor = Colors.redAccent;
      tipIcon = Icons.check_circle_outline_rounded;
    } else if (isOver) {
      tip = AppStrings.budgetTipOver;
      tipColor = Colors.redAccent;
      tipIcon = Icons.warning_amber_rounded;
    } else if (dailyAdvice < 5000) {
      tip = AppStrings.budgetTipCritical;
      tipColor = Colors.orange;
      tipIcon = Icons.error_outline_rounded;
    } else if (dailyAdvice < 15000) {
      tip = AppStrings.budgetTipWarning;
      tipColor = Colors.orangeAccent;
      tipIcon = Icons.restaurant_rounded;
    } else if (progress > 0.8) {
      tip = AppStrings.budgetTipCaution;
      tipColor = Colors.amber;
      tipIcon = Icons.info_outline_rounded;
    } else {
      tip = AppStrings.budgetTipGood;
      tipColor = AppColors.primary;
      tipIcon = Icons.thumb_up_alt_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tipColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tipColor.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(tipIcon, color: tipColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tipColor.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiRecommendToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.lunchRecommendModeTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  _isAiRecommendEnabled ? AppStrings.lunchRecommendActiveSub : AppStrings.lunchRecommendInactiveSub,
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          if (_isLoadingLocation)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else
            Switch.adaptive(
              value: _isAiRecommendEnabled,
              activeColor: AppColors.primary,
              onChanged: _toggleAiRecommend,
            ),
        ],
      ),
    );
  }

  Widget _buildAiRecommendationSection(ThemeData theme, double dailyAdvice) {
    IconData icon;
    String title;
    String description;
    String budgetTag;
    Color color;

    if (dailyAdvice < 2500) {
      icon = Icons.store_rounded;
      title = AppStrings.nearbyConvenienceTitle;
      description = AppStrings.nearbyConvenienceDesc;
      budgetTag = AppStrings.saveModeTag;
      color = Colors.orange;
    } else if (dailyAdvice < 9000) {
      icon = Icons.restaurant_rounded;
      title = AppStrings.nearbyRationalTitle;
      description = AppStrings.nearbyRationalDesc;
      budgetTag = AppStrings.rationalSpendingTag;
      color = AppColors.primary;
    } else {
      icon = Icons.celebration_rounded;
      title = AppStrings.nearbyFlexTitle;
      description = AppStrings.nearbyFlexDesc;
      budgetTag = AppStrings.todayFlexTag;
      color = Colors.purple;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(budgetTag, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _launchNearbySearch(title.contains(AppStrings.nearbyConvenienceTitle) ? AppStrings.searchConvenience : AppStrings.searchRestaurant),
            icon: const Icon(Icons.near_me_rounded, size: 14),
            label: const Text(AppStrings.nearbyStoreSearchButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMapPlaceholder(ThemeData theme, Color color) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: Opacity(opacity: 0.05, child: CustomPaint(painter: MapGridPainter()))),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded, color: color, size: 28),
                const SizedBox(height: 4),
                Text(AppStrings.mapLocationDetected, style: theme.textTheme.labelSmall?.copyWith(color: color.withOpacity(0.5), fontSize: 9)),
              ],
            ),
          ),
          Positioned(top: 30, left: 80, child: Icon(Icons.location_on_rounded, color: color.withOpacity(0.6), size: 20)),
          Positioned(bottom: 40, right: 60, child: Icon(Icons.location_on_rounded, color: color.withOpacity(0.4), size: 16)),
          Positioned(top: 70, right: 120, child: Icon(Icons.location_on_rounded, color: color.withOpacity(0.5), size: 16)),
        ],
      ),
    );
  }

  Widget _buildStoreListSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppStrings.nearbyRecommendationTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            Text('${_recommendedStores.length}${AppStrings.countSuffix}', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendedStores.length,
            itemBuilder: (context, index) {
              final store = _recommendedStores[index];
              return _buildStoreCard(theme, store);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoreCard(ThemeData theme, RecommendedStore store) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: store.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(store.category, style: TextStyle(color: store.color, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                  Text(store.rating.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(store.description, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 10), maxLines: 1),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(store.distance, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3), fontSize: 10)),
              Icon(Icons.arrow_forward_ios_rounded, size: 10, color: store.color),
            ],
          ),
        ],
      ),
    );
  }
}

class RecommendedStore {
  final String name;
  final String category;
  final double rating;
  final String distance;
  final String description;
  final Color color;
  final String mapX;
  final String mapY;

  RecommendedStore(this.name, this.category, this.rating, this.distance, this.description, this.color, {this.mapX = "", this.mapY = ""});
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 20) { canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint); }
    for (double i = 0; i < size.height; i += 20) { canvas.drawLine(Offset(0, i), Offset(size.width, i), paint); }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class NaverMapScreen extends StatefulWidget {
  final String query;
  final String mapClientId;
  final List<RecommendedStore> stores;
  const NaverMapScreen({super.key, required this.query, required this.mapClientId, required this.stores});

  @override
  State<NaverMapScreen> createState() => _NaverMapScreenState();
}

class _NaverMapScreenState extends State<NaverMapScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  void _initMap() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint('Naver Map Error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(
        _buildHtml(widget.mapClientId, widget.stores),
        baseUrl: 'https://map.naver.com', 
      );
  }

  String _buildHtml(String apiKey, List<RecommendedStore> stores) {
    final storesJson = jsonEncode(stores.map((s) => {
      'name': s.name,
      'mapX': s.mapX,
      'mapY': s.mapY,
    }).toList());

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <script type="text/javascript" src="https://oapi.map.naver.com/openapi/v3/maps.js?ncpClientId=$apiKey&submodules=geocoder"></script>
    <style>
        body, html, #map { width: 100%; height: 100%; margin: 0; padding: 0; overflow: hidden; background: #f8f8f8; }
        #map { position: absolute; top: 0; left: 0; right: 0; bottom: 0; }
    </style>
</head>
<body>
    <div id="map"></div>
    <script>
        var mapOptions = {
            center: new naver.maps.LatLng(37.5665, 126.9780),
            zoom: 15,
            logoControl: true,
            mapDataControl: true,
            zoomControl: true
        };
        var map = new naver.maps.Map('map', mapOptions);
        var stores = $storesJson;

        // 1. 내 위치 추적
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(function(position) {
                var currLoc = new naver.maps.LatLng(position.coords.latitude, position.coords.longitude);
                map.setCenter(currLoc);
                new naver.maps.Marker({
                    position: currLoc,
                    map: map,
                    zIndex: 100,
                    icon: {
                        content: '<div style="background:#4285F4;width:16px;height:16px;border-radius:50%;border:3px solid white;box-shadow:0 0 8px rgba(0,0,0,0.3);"></div>',
                        anchor: new naver.maps.Point(8, 8)
                    }
                });
            }, function(err) { console.warn("Geolocation denied"); });
        }

        // 2. 마커 생성 유틸리티
        function renderMarkers() {
            if (typeof naver === 'undefined' || !naver.maps || !naver.maps.TransCoord) {
                setTimeout(renderMarkers, 100);
                return;
            }

            stores.forEach(function(store) {
                if (store.mapX && store.mapY) {
                    try {
                        var utmk = new naver.maps.Point(store.mapX, store.mapY);
                        var latlng = naver.maps.TransCoord.fromTM128ToLatLng(utmk);

                        var marker = new naver.maps.Marker({
                            position: latlng,
                            map: map,
                            animation: naver.maps.Animation.DROP
                        });

                        var infoWindow = new naver.maps.InfoWindow({
                            content: '<div style="padding:12px;min-width:100px;text-align:center;">' +
                                     '<h4 style="margin:0;font-size:14px;">' + store.name + '</h4>' +
                                     '</div>',
                            borderWidth: 0,
                            backgroundColor: "white",
                            anchorSkew: true,
                            anchorSize: new naver.maps.Size(10, 10),
                            pixelOffset: new naver.maps.Point(0, -10)
                        });

                        naver.maps.Event.addListener(marker, "click", function() {
                            if (infoWindow.getMap()) {
                                infoWindow.close();
                            } else {
                                infoWindow.open(map, marker);
                            }
                        });
                    } catch (e) {
                        console.error("Marker Error", e);
                    }
                }
            });
        }
        
        setTimeout(renderMarkers, 600);
    </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.query} ${AppStrings.naverMapTitleSuffix}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }
}
