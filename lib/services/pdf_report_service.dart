import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../features/analytics/analytics_feature.dart';

/// PDF rapor servisi - Analytics verilerini PDF'e dönüştürür
class PDFReportService {
  pw.Font? _turkishFont;
  pw.Font? _turkishFontBold;
  bool _fontLoaded = false;

  /// Türkçe karakter desteği için font yükle (Noto Sans - Türkçe karakterleri destekler)
  /// Font dosyaları assets/fonts/ klasöründe olmalı:
  /// - NotoSans-Regular.ttf
  /// - NotoSans-Bold.ttf
  Future<void> _loadTurkishFont() async {
    if (_fontLoaded) return;

    try {
      // Önce assets'ten yüklemeyi dene
      try {
        debugPrint('🔄 Font assets\'ten yükleniyor...');

        // Regular font - Noto Sans Türkçe karakterleri destekler
        final regularFontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
        final fontBytes = regularFontData.buffer.asByteData();
        _turkishFont = pw.Font.ttf(fontBytes);
        debugPrint('✅ Noto Sans Regular font assets\'ten yüklendi (${regularFontData.lengthInBytes} bytes)');
        debugPrint('   Font Türkçe karakterleri desteklemelidir (İ, ı, Ş, ş, Ğ, ğ, Ü, ü, Ö, ö, Ç, ç)');

        // Bold font
        try {
          final boldFontData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
          _turkishFontBold = pw.Font.ttf(boldFontData.buffer.asByteData());
          debugPrint('✅ Noto Sans Bold font assets\'ten yüklendi (${boldFontData.lengthInBytes} bytes)');
        } catch (e) {
          debugPrint('⚠️ Bold font assets\'ten yüklenemedi: $e');
          debugPrint('   Regular font kullanılacak.');
        }

        _fontLoaded = true;
        return; // Başarılı olduysa çık
      } catch (e) {
        debugPrint('⚠️ Font assets\'ten yüklenemedi: $e');
        debugPrint('   İnternet\'ten indirilmeye çalışılacak...');
      }

      // Assets'ten yüklenemezse internet'ten indirmeyi dene (fallback)
      const fontUrls = [
        'https://github.com/google/fonts/raw/main/ofl/notosans/NotoSans-Regular.ttf',
        'https://raw.githubusercontent.com/google/fonts/main/ofl/notosans/NotoSans-Regular.ttf',
      ];
      const boldFontUrls = [
        'https://github.com/google/fonts/raw/main/ofl/notosans/NotoSans-Bold.ttf',
        'https://raw.githubusercontent.com/google/fonts/main/ofl/notosans/NotoSans-Bold.ttf',
      ];

      bool regularFontLoaded = false;

      // Regular font yükle
      for (final fontUrl in fontUrls) {
        try {
          debugPrint('🔄 Font indiriliyor: $fontUrl');
          final fontResponse = await http.get(Uri.parse(fontUrl)).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw Exception('Font indirme zaman aşımı');
            },
          );

          debugPrint('📥 Font yanıtı: Status ${fontResponse.statusCode}, Size: ${fontResponse.bodyBytes.length} bytes');

          if (fontResponse.statusCode == 200 && fontResponse.bodyBytes.isNotEmpty) {
            try {
              if (fontUrl.endsWith('.woff2')) {
                debugPrint('⚠️ WOFF2 formatı desteklenmiyor, TTF kullanılmalı');
                continue;
              }
              _turkishFont = pw.Font.ttf(fontResponse.bodyBytes.buffer.asByteData());
              regularFontLoaded = true;
              debugPrint('✅ Noto Sans font yüklendi (${fontResponse.bodyBytes.length} bytes) - URL: $fontUrl');
              break;
            } catch (e, stackTrace) {
              debugPrint('⚠️ Font parse hatası: $e');
              debugPrint('Stack trace: $stackTrace');
              continue;
            }
          } else {
            debugPrint(
                '⚠️ Font indirme başarısız: Status ${fontResponse.statusCode}, Size: ${fontResponse.bodyBytes.length}');
          }
        } catch (e, stackTrace) {
          debugPrint('⚠️ Font indirme hatası ($fontUrl): $e');
          debugPrint('Stack trace: $stackTrace');
          continue;
        }
      }

      if (!regularFontLoaded) {
        debugPrint('❌ Regular font yüklenemedi! Tüm URL\'ler denendi.');
      }

      bool boldFontLoaded = false;

      // Bold font yükle
      for (final boldFontUrl in boldFontUrls) {
        try {
          debugPrint('🔄 Bold font indiriliyor: $boldFontUrl');
          final boldFontResponse = await http.get(Uri.parse(boldFontUrl)).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw Exception('Bold font indirme zaman aşımı');
            },
          );

          debugPrint(
              '📥 Bold font yanıtı: Status ${boldFontResponse.statusCode}, Size: ${boldFontResponse.bodyBytes.length} bytes');

          if (boldFontResponse.statusCode == 200 && boldFontResponse.bodyBytes.isNotEmpty) {
            try {
              if (boldFontUrl.endsWith('.woff2')) {
                debugPrint('⚠️ WOFF2 formatı desteklenmiyor, TTF kullanılmalı');
                continue;
              }
              _turkishFontBold = pw.Font.ttf(boldFontResponse.bodyBytes.buffer.asByteData());
              boldFontLoaded = true;
              debugPrint(
                  '✅ Noto Sans Bold font yüklendi (${boldFontResponse.bodyBytes.length} bytes) - URL: $boldFontUrl');
              break;
            } catch (e, stackTrace) {
              debugPrint('⚠️ Bold font parse hatası: $e');
              debugPrint('Stack trace: $stackTrace');
              continue;
            }
          } else {
            debugPrint(
                '⚠️ Bold font indirme başarısız: Status ${boldFontResponse.statusCode}, Size: ${boldFontResponse.bodyBytes.length}');
          }
        } catch (e, stackTrace) {
          debugPrint('⚠️ Bold font indirme hatası ($boldFontUrl): $e');
          debugPrint('Stack trace: $stackTrace');
          continue;
        }
      }

      if (!boldFontLoaded) {
        debugPrint('⚠️ Bold font yüklenemedi, regular font kullanılacak.');
      }

      _fontLoaded = true;
    } catch (e) {
      debugPrint('⚠️ Font yükleme hatası: $e');
      _fontLoaded = true; // Hata olsa bile devam et
    }
  }

  /// Türkçe karakterleri düzelt
  /// Noto Sans font'u Türkçe karakterleri destekler ama bazı karakterler için
  /// Unicode normalization yapmak gerekebilir
  String _fixTurkishChars(String text) {
    // Font Türkçe karakterleri desteklediği için direkt döndür
    // Eğer bazı karakterler görünmüyorsa, font dosyasının tam versiyonunu kullanmak gerekebilir
    return text;
  }

  /// Analytics raporunu PDF olarak oluştur ve indir
  Future<File?> generateAnalyticsPDF({
    required List<StatCardData> stats,
    required Map<String, int> weeklyTasks,
    required Map<String, Map<String, int>> weeklyTasksDetailed,
    required Map<String, int> emailDistribution,
    required Map<String, int> monthlyMeetings,
    required Map<String, int> priorityTasks,
    required String userName,
    required String userEmail,
  }) async {
    try {
      // Türkçe font yükle
      await _loadTurkishFont();

      // Font yüklenmediyse hata ver
      if (_turkishFont == null) {
        debugPrint('❌ Türkçe font yüklenemedi! PDF oluşturulamıyor.');
        throw Exception('Türkçe font yüklenemedi. Lütfen internet bağlantınızı kontrol edin.');
      }

      final pdf = pw.Document();

      // PDF paketi font'ları otomatik olarak embed eder
      // Font'lar TextStyle'larda kullanıldığında otomatik olarak PDF'e eklenir

      // PDF başlık sayfası - Minimal ve modern tasarım
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(60),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo ve tarih
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _fixTurkishChars('AI ASİSTAN'),
                          style: pw.TextStyle(
                            color: PdfColors.blue900,
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            font: _turkishFontBold ?? _turkishFont!,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _fixTurkishChars('Analitik Raporu'),
                          style: pw.TextStyle(
                            color: PdfColors.grey600,
                            fontSize: 14,
                            font: _turkishFont!,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      _fixTurkishChars(DateFormat('dd.MM.yyyy').format(DateTime.now())),
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey500,
                        font: _turkishFont,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),

                // İnce çizgi
                pw.Container(
                  height: 2,
                  width: 80,
                  color: PdfColors.blue700,
                ),
                pw.SizedBox(height: 30),

                // Kullanıcı bilgileri - Minimal
                pw.Text(
                  _fixTurkishChars('Kullanıcı Bilgileri'),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                    font: _turkishFontBold ?? _turkishFont!,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  _fixTurkishChars(userName),
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.grey900,
                    font: _turkishFont!,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _fixTurkishChars(userEmail),
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                    font: _turkishFont!,
                  ),
                ),
                pw.Spacer(),

                // Alt not
                pw.Text(
                  _fixTurkishChars('Bu rapor üretkenlik ve aktivite analizlerinizi içermektedir.'),
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                    fontStyle: pw.FontStyle.italic,
                    font: _turkishFont!,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // İstatistik kartları sayfası
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Başlık
                pw.Row(
                  children: [
                    pw.Container(
                      width: 4,
                      height: 24,
                      color: PdfColors.blue700,
                    ),
                    pw.SizedBox(width: 12),
                    pw.Text(
                      _fixTurkishChars('Genel İstatistikler'),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                        font: _turkishFontBold ?? _turkishFont!,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),

                // İstatistik kartları - Grid layout (2x2)
                if (stats.isNotEmpty)
                  ...() {
                    // İki satırlı grid oluştur
                    final rows = <pw.Widget>[];
                    for (var i = 0; i < stats.length; i += 2) {
                      final rowStats = stats.skip(i).take(2).toList();
                      rows.add(
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: rowStats.map((stat) {
                            return pw.Expanded(
                              child: pw.Container(
                                margin: pw.EdgeInsets.only(
                                  right: rowStats.indexOf(stat) == 0 && rowStats.length > 1 ? 16 : 0,
                                  bottom: 16,
                                ),
                                padding: const pw.EdgeInsets.all(20),
                                decoration: pw.BoxDecoration(
                                  color: _getPdfColorWithOpacity(stat.color, 0.05),
                                  border: pw.Border(
                                    left: pw.BorderSide(
                                      color: _getPdfColorFromColor(stat.color),
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  mainAxisSize: pw.MainAxisSize.min,
                                  children: [
                                    pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Expanded(
                                          child: pw.Text(
                                            _fixTurkishChars(stat.title),
                                            style: pw.TextStyle(
                                              fontSize: 12,
                                              fontWeight: pw.FontWeight.bold,
                                              color: PdfColors.grey800,
                                              font: _turkishFontBold ?? _turkishFont!,
                                            ),
                                          ),
                                        ),
                                        pw.Container(
                                          width: 32,
                                          height: 32,
                                          decoration: pw.BoxDecoration(
                                            color: _getPdfColorFromColor(stat.color),
                                            shape: pw.BoxShape.circle,
                                          ),
                                          child: pw.Center(
                                            child: pw.Text(
                                              _getIconString(stat.icon),
                                              style: pw.TextStyle(
                                                fontSize: 14,
                                                color: PdfColors.white,
                                                font: _turkishFont!,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    pw.SizedBox(height: 16),
                                    pw.Text(
                                      _fixTurkishChars(stat.mainValue),
                                      style: pw.TextStyle(
                                        fontSize: 32,
                                        fontWeight: pw.FontWeight.bold,
                                        color: _getPdfColorFromColor(stat.color),
                                        font: _turkishFontBold ?? _turkishFont!,
                                      ),
                                    ),
                                    pw.SizedBox(height: 8),
                                    pw.Text(
                                      _fixTurkishChars(stat.subValue),
                                      style: pw.TextStyle(
                                        fontSize: 11,
                                        color: PdfColors.grey600,
                                        font: _turkishFont!,
                                      ),
                                    ),
                                    if (stat.trendValue.isNotEmpty) ...[
                                      pw.SizedBox(height: 6),
                                      pw.Text(
                                        _fixTurkishChars(stat.trendValue),
                                        style: pw.TextStyle(
                                          fontSize: 10,
                                          color: PdfColors.grey500,
                                          fontStyle: pw.FontStyle.italic,
                                          font: _turkishFont!,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }
                    return rows;
                  }()
                else
                  pw.Center(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(40),
                      child: pw.Text(
                        _fixTurkishChars('İstatistik verisi bulunamadı'),
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey600,
                          font: _turkishFont!,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );

      // Haftalık görevler grafiği sayfası
      if (weeklyTasks.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 4,
                        height: 24,
                        color: PdfColors.blue700,
                      ),
                      pw.SizedBox(width: 12),
                      pw.Text(
                        _fixTurkishChars('Haftalık Görev Dağılımı'),
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                          font: _turkishFontBold ?? _turkishFont!,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text(
                              _fixTurkishChars('Gün'),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColors.grey900,
                                font: _turkishFontBold ?? _turkishFont!,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text(
                              _fixTurkishChars('Tamamlanan'),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColors.grey900,
                                font: _turkishFontBold ?? _turkishFont!,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text(
                              _fixTurkishChars('Toplam'),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColors.grey900,
                                font: _turkishFontBold ?? _turkishFont!,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      ...weeklyTasks.keys.toList().map((day) {
                        final detailed = weeklyTasksDetailed[day] ?? {'completed': 0, 'total': 0};
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text(
                                _fixTurkishChars(day),
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  font: _turkishFont!,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text(
                                detailed['completed'].toString(),
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  font: _turkishFont!,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text(
                                detailed['total'].toString(),
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  font: _turkishFont!,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      // E-posta dağılımı sayfası
      if (emailDistribution.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 4,
                        height: 24,
                        color: PdfColors.blue700,
                      ),
                      pw.SizedBox(width: 12),
                      pw.Text(
                        _fixTurkishChars('E-posta Dağılımı'),
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                          font: _turkishFontBold ?? _turkishFont!,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text(
                              _fixTurkishChars('Klasör'),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColors.grey900,
                                font: _turkishFontBold ?? _turkishFont!,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text(
                              _fixTurkishChars('E-posta Sayısı'),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColors.grey900,
                                font: _turkishFontBold ?? _turkishFont!,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      ...emailDistribution.entries.map((entry) {
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text(
                                _fixTurkishChars(entry.key),
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  font: _turkishFont!,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text(
                                entry.value.toString(),
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  font: _turkishFont!,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      // Görev durumu dağılımı sayfası
      if (priorityTasks.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 4,
                        height: 24,
                        color: PdfColors.blue700,
                      ),
                      pw.SizedBox(width: 12),
                      pw.Text(
                        _fixTurkishChars('Görev Durumu Dağılımı'),
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                          font: _turkishFontBold ?? _turkishFont!,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text(
                              _fixTurkishChars('Durum'),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColors.grey900,
                                font: _turkishFontBold ?? _turkishFont!,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text(
                              _fixTurkishChars('Görev Sayısı'),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColors.grey900,
                                font: _turkishFontBold ?? _turkishFont!,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      ...priorityTasks.entries.map((entry) {
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text(
                                _fixTurkishChars(entry.key),
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  font: _turkishFont!,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text(
                                entry.value.toString(),
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  font: _turkishFont!,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      // PDF'i kaydet
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/analytics_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      debugPrint('❌ PDF oluşturma hatası: $e');
      return null;
    }
  }

  /// Flutter Color'ı PdfColor'a çevir
  PdfColor _getPdfColorFromColor(material.Color color) {
    return PdfColor.fromInt(color.toARGB32());
  }

  /// Flutter Color'ı opacity ile PdfColor'a çevir (beyaz ile karıştırarak)
  PdfColor _getPdfColorWithOpacity(material.Color color, double opacity) {
    // Opacity'yi 0-1 arasında sınırla
    final clampedOpacity = opacity.clamp(0.0, 1.0);

    // Orijinal RGB değerlerini al
    final r = (color.r * 255.0).round() & 0xff;
    final g = (color.g * 255.0).round() & 0xff;
    final b = (color.b * 255.0).round() & 0xff;

    // Beyaz ile karıştır (255, 255, 255)
    final newR = ((r * clampedOpacity) + (255 * (1 - clampedOpacity))).round();
    final newG = ((g * clampedOpacity) + (255 * (1 - clampedOpacity))).round();
    final newB = ((b * clampedOpacity) + (255 * (1 - clampedOpacity))).round();

    // Yeni PdfColor oluştur
    return PdfColor.fromInt((newR << 16) | (newG << 8) | newB);
  }

  /// IconData'yı string'e çevir
  String _getIconString(material.IconData icon) {
    // IconData'dan emoji veya sembol çıkar
    // Basit bir mapping yapabiliriz
    final codePoint = icon.codePoint;
    if (codePoint >= 0x1F300 && codePoint <= 0x1F9FF) {
      // Emoji range
      return String.fromCharCode(codePoint);
    }
    // Noto Sans'ta desteklenen basit bir karakter kullan
    // ● yerine • (U+2022) veya * kullan
    return '•'; // Bullet point - Noto Sans'ta desteklenir
  }
}
