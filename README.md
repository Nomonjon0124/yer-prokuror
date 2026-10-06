# YER PROKUROR Demo

Flutter 3.47.5 / Dart 3.13.4 bilan Android va iOS uchun tuzilgan interaktiv demo. Ilova berilgan ekranlarga mos bosh sahifa, xavf signallari, tahlillar, xarita, reestr, sud, ijro, zarar/to‘lov, bildirishnoma va profil sahifalarini o‘z ichiga oladi.

## Ishga tushirish

```bash
flutter pub get
flutter run
```

Android debug APK: `flutter build apk --debug`. iOS build uchun macOS va Xcode kerak. Xarita foniga internet kerak; internet bo‘lmasa marker va konturlar ko‘rinishda qoladi. Kamera, galereya va joriy joylashuv amallari qurilma ruxsatini so‘raydi.

## Demo oqimi

1. Profil orqali rolni **Kadastr agentligi** yoki **Agroinspeksiya**ga o‘tkazing. `RSK-ASOS-01` signalini ochib qabul qiling va tekshiruv usulini tanlang.
2. Dalolatnoma faylini biriktirib, qonunbuzilishni tasdiqlang. Yangi chora hujjatini biriktirib, ko‘rilgan chorani qayd eting.
3. Profil orqali **Prokuror** roliga o‘ting. Huquqiy baho bering, protest, taqdimnoma, ogohlantirish yoki qo‘shimcha tekshiruv hujjatini kiriting. Bu hujjat reestrda ham paydo bo‘ladi. Da’vo kiriting va sud qarorini qayd eting.
4. **Ijrochi** rolida ijro ishini oching. Ijro akti va yangi suratni biriktirib, obyektiv qayta tekshiruv natijasini tanlang. “O‘zgarish saqlangan” tanlansa signal formal ijro sifatida prokuror bosqichiga qaytadi.

Har amal sana, rol va izoh bilan vaqt chizig‘iga yoziladi. Demo sanasi boshlang‘ich holatda 30.04.2026; profil va sana filtrida o‘zgartiriladi. O‘zgarishlar ilova qayta ochilganda `sembast` bazasidan tiklanadi. Profil orqali demo boshlang‘ich holatga qaytariladi.

Bosqich muddatlari interaktiv namuna uchun hisoblanadi. Ular rasmiy protsessual muddat o‘rnini bosmaydi. Hisobot sahifasidan PDF va 12 ustunli CSV dalolatnoma, reestrdan PDF yoki CSV chiqariladi.

## Ma’lumot va chegaralar

- 833 namunaviy signal (152 yuqori, 263 o‘rta, 418 past xavf), 1248 reestr yozuvi va `YER_PROKUROR_TZ_11.docx`dan olingan 26 batafsil ssenariy bor. Dashboard va grafiklar ko‘rinayotgan ma’lumotlardan hisoblanadi.
- TZdagi huquqiy matnlar **demo ma’lumot** sifatida ko‘rsatiladi. Ilova AI xizmatiga murojaat qilmaydi va huquqiy qaror qabul qilmaydi. “Oldin–keyin” tasvirlari illustrativ chizma; rasman olingan kosmik surat emas.
- `Жадвал (6).docx`dagi 95/5 taqsimot zarar/to‘lov sahifasida taklifiy ko‘rinish sifatida hisoblanadi. Bu rasmiy hisob-kitob yoki avtomatik to‘lov emas.
- Davlat tizimlari, elektron imzo, kosmik tahlil va yuqori aniqlikdagi sun’iy yo‘ldosh qatlamiga jonli ulanish yo‘q. `SignalRepository` va `ApiGateway` haqiqiy API integratsiyasi uchun ajratilgan.
- OSM xarita plitkalarida atributsiya va ilovaga xos `User-Agent` berilgan. Ommaviy foydalanishdan oldin [OSM tile siyosati](https://operations.osmfoundation.org/policies/tiles/)ga mos alohida tile xizmatini tanlash kerak.

## Tuzilma va tekshirish

`lib/domain` — modellar, so‘rovlar, rol va olti bosqichli qoidalar. `lib/data` — demo fixture, doimiy saqlash, API chegarasi. `lib/ui` — ekranlar, grafiklar, xarita, PDF/CSV eksport va dizayn. Holat uchun Riverpod, yo‘nalishlar uchun go_router ishlatiladi.

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Telefon USB orqali APK o‘rnatishni rad etsa, Android qurilmada USB debugging va USB orqali ilova o‘rnatish ruxsatini yoqish kerak.
