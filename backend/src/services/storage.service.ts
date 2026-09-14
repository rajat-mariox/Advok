// Photo storage. With S3_BUCKET set, base64 data URLs sent by the app are
// uploaded to S3 and only the resulting URL is saved in the database. Without
// it (local dev) the data URL is stored as-is, exactly like before.
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { randomUUID } from 'crypto';
import { AWS_REGION, S3_BUCKET, S3_PUBLIC_URL } from '../config';

const s3 = S3_BUCKET ? new S3Client({ region: AWS_REGION }) : null;

const DATA_URL_RE = /^data:(image\/[a-z0-9+.-]+);base64,(.+)$/i;

/**
 * Uploads a photo to S3 and returns its public URL.
 *
 * Pass-through cases: S3 not configured, or `photo` is not a base64 data URL
 * (e.g. an https URL from a previous upload, or '' meaning "remove photo").
 */
export async function storePhoto(photo: string, folder: string): Promise<string> {
  if (!s3) return photo;
  const match = DATA_URL_RE.exec(photo);
  if (!match) return photo;

  const [, contentType, base64] = match;
  const ext = contentType.split('/')[1].replace('jpeg', 'jpg').replace(/[^a-z0-9]/gi, '');
  const key = `${folder}/${randomUUID()}.${ext}`;

  await s3.send(
    new PutObjectCommand({
      Bucket: S3_BUCKET,
      Key: key,
      Body: Buffer.from(base64, 'base64'),
      ContentType: contentType,
    }),
  );

  const base = S3_PUBLIC_URL || `https://${S3_BUCKET}.s3.${AWS_REGION}.amazonaws.com`;
  return `${base}/${key}`;
}

const FILE_DATA_URL_RE = /^data:([a-z0-9.+-]+\/[a-z0-9.+-]+);base64,(.+)$/i;

/**
 * Like [storePhoto] but for any file type (case documents: PDFs, images,
 * Word files, …). With S3 configured the file is uploaded and its URL
 * returned; otherwise the data URL is stored as-is (local dev).
 */
export async function storeFile(dataUrl: string, folder: string): Promise<string> {
  if (!s3) return dataUrl;
  const match = FILE_DATA_URL_RE.exec(dataUrl);
  if (!match) return dataUrl;

  const [, contentType, base64] = match;
  const subtype = contentType.split('/')[1] ?? 'bin';
  const ext = subtype.replace('jpeg', 'jpg').replace(/[^a-z0-9]/gi, '').slice(0, 10) || 'bin';
  const key = `${folder}/${randomUUID()}.${ext}`;

  await s3.send(
    new PutObjectCommand({
      Bucket: S3_BUCKET,
      Key: key,
      Body: Buffer.from(base64, 'base64'),
      ContentType: contentType,
    }),
  );

  const base = S3_PUBLIC_URL || `https://${S3_BUCKET}.s3.${AWS_REGION}.amazonaws.com`;
  return `${base}/${key}`;
}
