---
id: INC-20260714-172000-listenandserve-deadlock
title: free-api-hunter ListenAndServe deadlock on /api/v1/* requests
status: closed
severity: high
discovered_by: streikbrecher
discovered_at: 2026-07-14T17:20:00Z
resolved_at: 2026-07-14T17:30:00Z
repo: free-api-hunter
---

## Симптом
E2E-тест (реальный сокет через `ListenAndServe()`) вис на `GET /api/v1/providers`
и любом другом `/api/v1/*` эндпоинте: клиент получал `context deadline exceeded`.
`GET /health` работал штатно.

## Корень
`ListenAndServe()` (internal/api/server.go) оборачивал `s.mux` в
`CORSMiddleware(RateLimitMiddleware(metricsMiddleware(s.mux)))`.
Внутри `s.mux` каждый route зарегистрирован через `buildHandler`, который УЖЕ
содержит `ProtectedMiddleware(RateLimitMiddleware(CORSMiddleware(MaxSizeMiddleware(handler))))`.
То есть `RateLimitMiddleware` применялся ДВАЖДЫ.

`globalRateLimiter.mu` — обычный не-реентерабельный `sync.Mutex`. Внешний
`RateLimitMiddleware` держал лок и вызывал `next.ServeHTTP` → внутренний
`RateLimitMiddleware` пытался залочить тот же мьютекс → перманентный deadlock.
`/health` зарегистрирован как `s.mux.HandleFunc("/health", s.handleHealth)`
БЕЗ `buildHandler` → не затронут, поэтому работал.

## Почему не проявлялось в проде
`ListenAndServeGraceful` (используется в продакшене) сервит
`&http.Server{Handler: s.mux}` БЕЗ внешней обёртки → двойного
`RateLimitMiddleware` нет. Баг проявлялся только в не-graceful `ListenAndServe`
и, соответственно, в E2E-тесте, который его дёргает.

## Решение
`ListenAndServe` теперь оборачивает mux только в `metricsMiddleware(s.mux)`;
CORS / RateLimit / MaxSize / Protected остаются per-route через `buildHandler`.
Коммит `5e36bc0` (ветка `streikbrecher/free-api-hunter-go-coverage`) → main.

## Верификация
- E2E `tests/e2e_test.go` зелёный (реальный сокет, все `/api/v1/*` отвечают 200).
- `go vet ./...` — чисто.
- `go build ./...` — exit 0.
- coverage: `internal/api` 83.7%, `internal/scraper` 89.9%.
- Попутно переименован `scraper_test_extended.go` → `scraper_extended_test.go`
  (старое имя не компилировалось как тест, 10 `Test*` были мёртвым кодом).
