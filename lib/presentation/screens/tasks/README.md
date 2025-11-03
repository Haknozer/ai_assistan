# Tasks Screen Modülü

Görev yönetimi ekranı - Kanban board ile görevlerinizi yönetin.

## 📂 Klasör Yapısı

```
tasks/
├── tasks_screen.dart          # Ana görevler ekranı (300 satır)
├── data/
│   └── mock_tasks.dart        # Mock görev verileri
├── utils/
│   ├── task_filter.dart       # Görev filtreleme enum'u
│   └── task_utils.dart        # Görev yardımcı fonksiyonları
└── README.md                  # Bu dosya
```

## 🎨 Widget Yapısı

### Widgets (lib/presentation/widgets/tasks/)
- `tasks_page_header.dart` - Sayfa başlığı ve "Görev Ekle" butonu
- `search_and_filter_section.dart` - Arama ve filtre chip'leri
- `kanban_board.dart` - Ana Kanban panosu container'ı
- `kanban_column.dart` - Her durum için sütun (Yapılacak, Devam Ediyor, Tamamlandı)
- `task_card.dart` - Tek bir görev kartı (sürüklenebilir)
- `add_task_dialog.dart` - Görev ekleme dialog'u
- `task_notification_overlay.dart` - Toast-style bildirimler

## 🔧 Utilities

### TaskUtils (task_utils.dart)
- `getStatusColor()` - Görev durumu rengi (pending/inProgress/completed/cancelled)
- `getStatusIcon()` - Görev durumu ikonu
- `getPriorityColor()` - Öncelik derecesi rengi (urgent/high/medium/low)

### TaskFilter (task_filter.dart)
- Enum: `all`, `pending`, `inProgress`, `completed`
- Her filtre için displayName

### MockTasks (mock_tasks.dart)
- `tasks` - Mock görev listesi
- `groupByStatus()` - Görevleri duruma göre grupla

## 📊 Özellikler

### Görev Yönetimi
- ✅ Kanban board görünümü (Yapılacak / Devam Ediyor / Tamamlandı)
- ✅ Drag & Drop görev taşıma
- ✅ Görev arama (başlık ve açıklama)
- ✅ Görev filtreleme (Tümü, Yapılacak, Devam Ediyor, Tamamlandı)
- ✅ Yeni görev ekleme
- ✅ Öncelik seçimi (Acil, Yüksek, Orta, Düşük)
- ✅ Son tarih seçimi (tarih + saat)
- ✅ Durum seçimi
- ✅ Gecikmiş görev uyarıları (kırmızı)
- ✅ Gerçek zamanlı bildirimler (toast)

### Responsive Tasarım
- **Desktop**: Sol menü + yatay Kanban sütunları
- **Mobile**: Drawer menü + dikey Kanban sütunları

### Drag & Drop
- Görevleri sürükleyip bırakarak durumlarını değiştirme
- Hover efektleri
- Görsel geri bildirim (opacity, border, shadow)
- Boş sütunlar için "buraya bırakın" mesajı

### Dialog'lar
- **Add Task Dialog**: Yeni görev oluşturma
  - Başlık (zorunlu)
  - Açıklama (opsiyonel)
  - Öncelik seçimi (chip'ler)
  - Durum seçimi (dropdown)
  - Son tarih seçimi (date + time picker)

### Bildirimler
- **Task Update Notification**: Görev durumu değiştiğinde
- **Task Added Notification**: Yeni görev eklendiğinde
- Otomatik kapanma (4 saniye)
- Manuel kapatma (X butonu)
- Renk kodlu (durum/başarı rengine göre)

## 🎯 Ana Fonksiyonlar

### TasksScreen
- `_filteredTasks` - Filtrelenmiş ve aranmış görev listesi
- `_tasksByStatus` - Duruma göre gruplandırılmış görevler
- `_updateTaskStatus()` - Görev durumunu güncelle (drag & drop için)
- `_showAddTaskDialog()` - Görev ekleme dialog'unu göster
- `_showTaskUpdateNotification()` - Durum değişikliği bildirimi
- `_showTaskAddedNotification()` - Görev ekleme bildirimi

## 🔄 State Yönetimi

- `_currentFilter` - Seçili filtre (all/pending/inProgress/completed)
- `_searchQuery` - Arama sorgusu
- `_mockTasks` - Görev listesi (mutable)

## 📱 Responsive Davranış

### Desktop (> 900px)
- Sol menü sabit
- Yatay Kanban sütunları (Row)
- Her sütun eşit genişlik (Expanded)
- Sağ boşluk 16px

### Mobile (< 900px)
- Drawer menü
- Dikey Kanban sütunları (Column)
- Her sütun eşit yükseklik (Expanded)
- Alt boşluk 12px

## 🎨 Tema ve Renkler

### Durum Renkleri
- **Yapılacak (Pending)**: Turuncu (Warning)
- **Devam Ediyor (InProgress)**: Mavi (Primary)
- **Tamamlandı (Completed)**: Yeşil (Success)
- **İptal Edildi (Cancelled)**: Gri

### Öncelik Renkleri
- **Acil (Urgent)**: Koyu Kırmızı (#D32F2F)
- **Yüksek (High)**: Kırmızı (Error)
- **Orta (Medium)**: Turuncu (Warning)
- **Düşük (Low)**: Yeşil (Success)

## 📝 Kod İyileştirmeleri

### Öncesi (1553 satır)
- Tüm kod tek dosyada
- Mock data ana dosyada
- AddTaskDialog ana dosyada
- Tüm build methodları ana dosyada
- Overlay bildirimleri ana dosyada
- Çok büyük ve okunamaz

### Sonrası (300 satır)
- ✅ Modüler widget yapısı
- ✅ Mock data ayrı dosyada
- ✅ Utilities ayrı dosyada
- ✅ Widget'lar ayrı dosyalarda
- ✅ Temiz ve okunabilir
- ✅ Bakım ve test kolay

## 🚀 Performans

- Drag & Drop: Optimized with feedback widget
- Filtreleme: Getter ile lazy evaluation
- Arama: Real-time filtering
- Bildirimler: Overlay ile performanslı

## 📚 Kullanım Örneği

```dart
// Görevler ekranına navigasyon
context.go('/tasks');

// Görev durumunu güncelle
_updateTaskStatus(task, TaskStatus.completed);

// Yeni görev ekle
_showAddTaskDialog();

// Bildirim göster
TaskNotificationOverlay.show(
  context: context,
  task: task,
  message: 'Görev tamamlandı',
  status: TaskStatus.completed,
);
```

## 🏗️ Mimari

Bu modül Clean Architecture prensiplerine uygun olarak tasarlanmıştır:
- **Presentation**: Widgets ve Screens (tek sorumluluk)
- **Domain**: Models ve Business Logic
- **Data**: Mock Data ve Services (TODO)

Her widget tek bir sorumluluğa sahip ve bağımsız olarak test edilebilir.

## 🔗 Bağımlılıklar

- `flutter_riverpod` - State yönetimi
- `go_router` - Navigasyon
- `Task` model - Görev veri modeli
- `TaskStatus` enum - Görev durumu
- `TaskPriority` enum - Görev önceliği
- `MockTasks` - Mock görev verileri

## 🧪 Test Durumu

⚠️ Test dosyaları henüz oluşturulmadı.

## 📈 Gelecek Geliştirmeler (TODO)

- [ ] Backend entegrasyonu (API)
- [ ] Görev silme işlevi
- [ ] Görev düzenleme işlevi
- [ ] Görev detay sayfası
- [ ] Görev ataması (kullanıcılara)
- [ ] Görev kategorileri/etiketleri
- [ ] Görev dosya ekleri
- [ ] Görev yorumları
- [ ] Görev geçmişi
- [ ] Toplu işlemler
- [ ] Sıralama seçenekleri
- [ ] Görünüm modu (liste/kanban/takvim)
- [ ] Bildirim ayarları
- [ ] Offline modu
- [ ] Real-time sync (WebSocket)

## 📊 Dosya Satır Sayıları

| Dosya | Satır Sayısı | Açıklama |
|-------|--------------|----------|
| tasks_screen.dart | 300 | Ana ekran (1553'ten düştü!) |
| mock_tasks.dart | 50 | Mock veriler |
| task_filter.dart | 12 | Filter enum |
| task_utils.dart | 54 | Utility fonksiyonlar |
| tasks_page_header.dart | 76 | Sayfa başlığı |
| search_and_filter_section.dart | 111 | Arama ve filtre |
| kanban_board.dart | 58 | Kanban container |
| kanban_column.dart | 175 | Kanban sütunu |
| task_card.dart | 190 | Görev kartı |
| add_task_dialog.dart | 401 | Görev ekleme dialog'u |
| task_notification_overlay.dart | 133 | Bildirimler |

**Toplam**: ~1560 satır (önceden 1553 satır TEK DOSYADA!)
**Şimdi**: 11 dosyada, her biri odaklanmış ve bakımı kolay! 🎉
