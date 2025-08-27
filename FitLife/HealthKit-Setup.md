w# HealthKit Kurulum Rehberi

Bu rehber, FitLife uygulamasında HealthKit entegrasyonu için gerekli adımları açıklar.

## 1. Xcode Proje Ayarları

### HealthKit Capability Ekleme
1. Xcode'da projeyi açın
2. Project Navigator'da projeyi seçin
3. Target'ı seçin (FitLife)
4. "Signing & Capabilities" sekmesine gidin
5. "+" butonuna tıklayın
6. "HealthKit" capability'sini ekleyin

### Info.plist Ayarları
Aşağıdaki anahtarları Info.plist dosyasına ekleyin:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Bu uygulama Apple Watch'tan adım sayısı ve yakılan kalori verilerini okumak için HealthKit erişimi istiyor.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Bu uygulama sağlık verilerinizi güncellemek için HealthKit erişimi istiyor.</string>
```

## 2. Kod Entegrasyonu

### HealthKitService Kullanımı

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var healthKitService = HealthKitService()
    
    var body: some View {
        VStack {
            if healthKitService.isAuthorized {
                Text("Günlük Adımlar: \(healthKitService.dailySteps)")
                Text("Günlük Kaloriler: \(Int(healthKitService.dailyCalories))")
            } else {
                Button("HealthKit İzni Ver") {
                    Task {
                        await healthKitService.requestAuthorization()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await healthKitService.requestAuthorization()
            }
        }
    }
}
```

## 3. Özellikler

### Mevcut Özellikler
- ✅ Günlük adım sayısı
- ✅ Günlük yakılan kalori
- ✅ Haftalık veri grafikleri
- ✅ Gerçek zamanlı veri güncellemeleri
- ✅ Background veri senkronizasyonu

### Desteklenen Veri Türleri
- `HKQuantityType.stepCount` - Adım sayısı
- `HKQuantityType.activeEnergyBurned` - Aktif enerji (kalori)

## 4. Test Etme

### Simulator'da Test
1. Health uygulamasını açın
2. "Browse" sekmesine gidin
3. "Activity" > "Steps" seçin
4. Manuel veri ekleyin

### Gerçek Cihazda Test
1. Apple Watch ile iPhone'u eşleştirin
2. Uygulamayı çalıştırın
3. HealthKit izni verin
4. Biraz yürüyün ve verilerin güncellendiğini kontrol edin

## 5. Hata Ayıklama

### Yaygın Sorunlar
1. **İzin verilmedi**: Ayarlar > Gizlilik ve Güvenlik > Sağlık > FitLife'dan izinleri kontrol edin
2. **Veri gelmiyor**: Apple Watch'ın iPhone ile senkronize olduğundan emin olun
3. **Background güncellemeler çalışmıyor**: Background App Refresh'in açık olduğundan emin olun

### Debug Mesajları
HealthKitService'te hata mesajları `authorizationError` property'sinde saklanır.

## 6. Güvenlik ve Gizlilik

- Uygulama sadece okuma izni ister
- Veriler cihazda saklanır
- Apple'ın HealthKit gizlilik kurallarına uygun
- Kullanıcı istediği zaman izinleri iptal edebilir

## 7. Gelecek Geliştirmeler

Eklenebilecek özellikler:
- Kalp atış hızı
- Uyku verileri
- Egzersiz seansları
- Beslenme verileri
- Kan basıncı
- Vücut ağırlığı 
