const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

const SOURCE_UID = '631D97F2-F464-4C99-A80E-CB52178C8281';
const TARGET_UID = '58A8BF96-DF62-424C-928C-9FEC1508AF98';

async function migrate() {
  console.log('Starting migration...');

  // 直接open_water/tilesを取得
  const tilesRef = db.collection(`users/${SOURCE_UID}/sheets/open_water/tiles`);
  const tilesSnap = await tilesRef.get();
  console.log('open_water tiles count:', tilesSnap.size);
  console.log('open_water tiles:', tilesSnap.docs.map(d => d.id));

  // データをそのままコピー
  for (const doc of tilesSnap.docs) {
    await db.collection(`users/${TARGET_UID}/sheets/open_water/tiles`).doc(doc.id).set(doc.data());
    console.log(`Migrated: ${doc.id}`);
  }

  // advanceシートも試みる
  const advTilesRef = db.collection(`users/${SOURCE_UID}/sheets/advance/tiles`);
  const advTilesSnap = await advTilesRef.get();
  console.log('advance tiles count:', advTilesSnap.size);
  for (const doc of advTilesSnap.docs) {
    await db.collection(`users/${TARGET_UID}/sheets/advance/tiles`).doc(doc.id).set(doc.data());
    console.log(`Migrated advance: ${doc.id}`);
  }

  console.log('Migration completed!');
  process.exit(0);
}

migrate().catch(console.error);
