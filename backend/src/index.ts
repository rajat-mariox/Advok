import cors from 'cors';
import express from 'express';
import { PORT, SEED_ADMIN_EMAIL } from './config';
import { requestLogger } from './middlewares/logger.middleware';
import apiRoutes from './routes';
import { initDb } from './services/db.service';

const app = express();

app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use(requestLogger);

app.use('/api', apiRoutes);

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Connect MongoDB (or the db.json fallback) + seed admin, then start serving.
initDb()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`ADVOK backend running on http://localhost:${PORT}`);
      console.log(`Admin login: ${SEED_ADMIN_EMAIL}`);
    });
  })
  .catch((err) => {
    console.error('Failed to initialize database:', err);
    process.exit(1);
  });
