import os from 'os';
import cors from 'cors';
import express from 'express';
import { PORT, SEED_ADMIN_EMAIL } from './config';
import { requestLogger } from './middlewares/logger.middleware';
import apiRoutes from './routes';
import { startCourtSyncScheduler } from './services/case-sync.service';
import { initDb } from './services/db.service';
import { loadDictionary } from './services/dictionary.service';

const app = express();

app.use(cors());
// 16mb fits a 10MB case document after base64's ~4/3 overhead.
app.use(express.json({ limit: '16mb' }));
app.use(requestLogger);

app.use('/api', apiRoutes);

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Connect MongoDB (or the db.json fallback) + seed admin, then start serving.
initDb()
  .then(() => {
    // Bind to all interfaces so phones on the same WiFi can reach it via LAN IP.
    app.listen(PORT, '0.0.0.0', () => {
      const lanIps = Object.values(os.networkInterfaces())
        .flat()
        .filter((n) => n && n.family === 'IPv4' && !n.internal)
        .map((n) => `http://${n!.address}:${PORT}`);
      console.log(`ADVOK backend listening on port ${PORT}`);
      console.log(`LAN URLs: ${lanIps.join(', ') || '(none found)'}`);
      console.log(`Admin login: ${SEED_ADMIN_EMAIL}`);
      startCourtSyncScheduler();
      loadDictionary();
    });
  })
  .catch((err) => {
    console.error('Failed to initialize database:', err);
    process.exit(1);
  });

