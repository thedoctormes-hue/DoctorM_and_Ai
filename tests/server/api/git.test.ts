import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import express from 'express';
import { router } from '../../../demo/api/git.js';

// Создаём тестовое приложение
const app = express();
app.use(express.json());
app.use('/api/git', router);

describe('Git Health API', () => {

  // ---- /api/git/health ----

  describe('GET /api/git/health', () => {
    it('возвращает score, status, rci, cnr', async () => {
      const res = await request(app).get('/api/git/health');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('score');
      expect(res.body).toHaveProperty('status');
      expect(res.body).toHaveProperty('rci');
      expect(res.body).toHaveProperty('cnr');
      expect(res.body).toHaveProperty('branch_count');
      expect(res.body).toHaveProperty('stale_branches');
      expect(res.body).toHaveProperty('conflicts');
      expect(res.body).toHaveProperty('computed_at');
    });

    it('score между 0 и 100', async () => {
      const res = await request(app).get('/api/git/health');
      expect(res.body.score).toBeGreaterThanOrEqual(0);
      expect(res.body.score).toBeLessThanOrEqual(100);
    });

    it('status один из: healthy, warning, critical', async () => {
      const res = await request(app).get('/api/git/health');
      expect(['healthy', 'warning', 'critical']).toContain(res.body.status);
    });
  });

  // ---- /api/git/rci ----

  describe('GET /api/git/rci', () => {
    it('возвращает rci и status', async () => {
      const res = await request(app).get('/api/git/rci');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('rci');
      expect(res.body).toHaveProperty('status');
      expect(res.body).toHaveProperty('window_days');
      expect(res.body.window_days).toBe(30);
    });

    it('rci >= 0', async () => {
      const res = await request(app).get('/api/git/rci');
      expect(res.body.rci).toBeGreaterThanOrEqual(0);
    });

    it('status один из: excellent, normal, low', async () => {
      const res = await request(app).get('/api/git/rci');
      expect(['excellent', 'normal', 'low']).toContain(res.body.status);
    });
  });

  // ---- /api/git/cnr ----

  describe('GET /api/git/cnr', () => {
    it('возвращает cnr и status', async () => {
      const res = await request(app).get('/api/git/cnr');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('cnr');
      expect(res.body).toHaveProperty('status');
      expect(res.body).toHaveProperty('window_days');
    });

    it('cnr между 0 и 1', async () => {
      const res = await request(app).get('/api/git/cnr');
      expect(res.body.cnr).toBeGreaterThanOrEqual(0);
      expect(res.body.cnr).toBeLessThanOrEqual(1);
    });

    it('status один из: excellent, warning, critical', async () => {
      const res = await request(app).get('/api/git/cnr');
      expect(['excellent', 'warning', 'critical']).toContain(res.body.status);
    });
  });

  // ---- /api/git/conflicts ----

  describe('GET /api/git/conflicts', () => {
    it('возвращает has_conflicts и conflicts', async () => {
      const res = await request(app).get('/api/git/conflicts');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('has_conflicts');
      expect(res.body).toHaveProperty('conflicts');
      expect(Array.isArray(res.body.conflicts)).toBe(true);
    });

    it('has_conflicts = false когда нет конфликтов', async () => {
      const res = await request(app).get('/api/git/conflicts');
      // В чистом репозитории конфликтов быть не должно
      expect(res.body.has_conflicts).toBe(false);
    });
  });

  // ---- /api/git/branches ----

  describe('GET /api/git/branches', () => {
    it('возвращает branches и count', async () => {
      const res = await request(app).get('/api/git/branches');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('branches');
      expect(res.body).toHaveProperty('count');
      expect(Array.isArray(res.body.branches)).toBe(true);
    });

    it('count совпадает с длиной branches', async () => {
      const res = await request(app).get('/api/git/branches');
      expect(res.body.count).toBe(res.body.branches.length);
    });

    it('branches не пустой (есть хотя бы main)', async () => {
      const res = await request(app).get('/api/git/branches');
      expect(res.body.branches.length).toBeGreaterThan(0);
    });

    it('каждая ветка имеет name, type, last_commit', async () => {
      const res = await request(app).get('/api/git/branches');
      for (const branch of res.body.branches) {
        expect(branch).toHaveProperty('name');
        expect(branch).toHaveProperty('type');
        expect(branch).toHaveProperty('last_commit');
        expect(branch).toHaveProperty('is_stale');
        expect(branch).toHaveProperty('age_days');
      }
    });
  });

  // ---- /api/git/worktrees ----

  describe('GET /api/git/worktrees', () => {
    it('возвращает worktrees и count', async () => {
      const res = await request(app).get('/api/git/worktrees');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('worktrees');
      expect(res.body).toHaveProperty('count');
      expect(Array.isArray(res.body.worktrees)).toBe(true);
    });

    it('count совпадает с длиной worktrees', async () => {
      const res = await request(app).get('/api/git/worktrees');
      expect(res.body.count).toBe(res.body.worktrees.length);
    });

    it('worktrees содержат path и branch', async () => {
      const res = await request(app).get('/api/git/worktrees');
      for (const wt of res.body.worktrees) {
        expect(wt).toHaveProperty('path');
      }
    });
  });
});
