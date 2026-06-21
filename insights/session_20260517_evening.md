
# Сессия 17.05.2026 вечер — Affiliate Injector

## Инсайты

### INS-20260517-013 [architecture] Affiliate Injector создан [layer: skills]
Создан модуль `AffiliateInjector` — автоматическая контекстная вставка аффилиат-ссылок в контент.
- Подход: keyword-based injection, максимум 1 ссылка на пост
- Не спамит — только при релевантном упоминании + проверка status == "registered"
- Каналы: @LLMevangelist, @doctormes_ai, @ZALUPCHICKI — у каждого свой набор программ

### INS-20260517-014 [integration] Affiliate Injector интегрирован в Hype Pilot [layer: infrastructure]
Подключён к `publish_post.py` (публикация из inbox) и `observe_and_post.py` (автопостинг из projects.json).
Lazy init через `get_affiliate_injector()` — не грузит конфиг без необходимости.

### INS-20260517-015 [discovery] Пассивный доход через аффилиаты — первый шаг [layer: agents]
Пассивный income engine v0.1.0. Текущие registered программы: DigitalOcean ($25-200 CPA), Yandex Cloud (10-15%).
Runway ML, ElevenLabs, HeyGen — в pending (нужна регистрация).
Потенциал: при 20 постах/мес с аффилиатами = ~$50-100/мес пассивного дохода.

