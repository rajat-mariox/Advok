import cors from 'cors';
import express from 'express';
import { PORT, SEED_ADMIN_EMAIL } from './config';
import { getDb } from './db';
import adminRouter from './routes/admin';
import authRouter from './routes/auth';
import cmsRouter from './routes/cms';
import onboardingRouter from './routes/onboarding';

const app = express();

app.use(cors());
app.use(express.json({ limit: '2mb' }));

// Log every API request with its status code and duration.
app.use((req, res, next) => {
  const startedAt = Date.now();
  res.on('finish', () => {
    const time = new Date().toLocaleTimeString();
    console.log(
      `[${time}] ${req.method} ${req.originalUrl} -> ${res.statusCode} (${Date.now() - startedAt}ms)`,
    );
  });
  next();
});

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, service: 'advok-backend' });
});

app.use('/api/auth', authRouter);
app.use('/api/onboarding', onboardingRouter);
app.use('/api/admin', adminRouter);
app.use('/api/cms', cmsRouter);

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

getDb(); // load store + seed admin on boot

app.listen(PORT, () => {
  console.log(`ADVOK backend running on http://localhost:${PORT}`);
  console.log(`Admin login: ${SEED_ADMIN_EMAIL}`);
});
