#!/usr/bin/env node
/**
 * One-off cleanup: remove Google/Apple profile photos and real names that
 * Google/Apple sign-up copied into Dear Claire user profiles.
 *
 * Dry run (default, writes nothing, prints counts):
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node scripts/anonymize_google_profiles.js
 * Apply:
 *   ... node scripts/anonymize_google_profiles.js --apply
 *
 * What it changes, per affected user:
 *   users/{uid}.avatarUrl  -> a random default Clairevatar (if it is a provider photo)
 *   users/{uid}.nickname   -> an anonymous nickname, only when it still equals the
 *                              real name on the user's Google/Apple account
 *   sessions where userId == uid: userAvatarUrl / userNickname updated to match
 * A backup of every changed field is written to anonymize-backup-<time>.json.
 * Comments and chats keep their stored copy, but the app (15.4.x+) already
 * replaces provider photos with a Clairevatar when it shows them.
 */
const fs = require('fs');
const path = require('path');
const admin = require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));

const APPLY = process.argv.includes('--apply');
admin.initializeApp({ projectId: 'clair-52652' });
const db = admin.firestore();
const auth = admin.auth();

const CLAIREVATARS = [
  'https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-walter-white-72.png?alt=media&token=0b791843-76ae-4441-aca6-8a06f9e6fa67',
  'https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fbear.png?alt=media&token=c5348009-e700-4a5f-ae83-6653e29784d7',
  'https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fthoughtful_baby.png?alt=media&token=702c1fa9-ed42-4764-ad8e-8a1a21ff9679',
  'https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-homer-simpson-72.png?alt=media&token=3461c319-0840-47f0-8025-8773587a6189',
  'https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-parrot-72.png?alt=media&token=3cdf21b9-b7da-450e-94e0-c54b4fcba295',
  'https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-starfish-72.png?alt=media&token=ad4feba1-ddc3-4354-bc0e-4cef75fb2fbc',
  'https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2FYellow_Moon_Emoji.png?alt=media&token=98cd50a5-f2a0-411a-9aef-06fd91d16c52',
  'https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2FUpside-Down_Face_Emoji.png?alt=media&token=be8ded7e-4880-490a-9bf7-6a0aef361c1c',
  'https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-strawberry-72.png?alt=media&token=ff64370f-939c-46ce-af5e-d220a625ef51',
  'https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2FHugging_Face_Emoji.png?alt=media&token=108f537b-2671-4fce-ade8-3618d3665fc6',
  'https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fpanda_dance.png?alt=media&token=7bd9a4d9-ed60-4736-af74-c19eb7c69d6a',
  'https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-iron-man-72(-hdpi).png?alt=media&token=4c7b9989-a762-469b-8386-c1d8daf2c8cc'
];
const PHOTO_HOSTS = ['googleusercontent.com', 'ggpht.com', 'graph.facebook.com', 'fbcdn.net', 'pbs.twimg.com', 'appleid.cdn-apple.com'];
const ADJ = ['Gentle', 'Quiet', 'Brave', 'Kind', 'Sunny', 'Calm', 'Hopeful', 'Bright', 'Soft', 'Golden', 'Lucky', 'Cosy', 'Dreamy', 'Sweet', 'Wise', 'Silver'];
const NOUN = ['Moon', 'Petal', 'Sparrow', 'Star', 'River', 'Cloud', 'Rose', 'Breeze', 'Dove', 'Lily', 'Pearl', 'Robin', 'Meadow', 'Willow', 'Ember', 'Daisy'];
const pick = (a) => a[Math.floor(Math.random() * a.length)];
const nickname = () => `${pick(ADJ)} ${pick(NOUN)} ${100 + Math.floor(Math.random() * 900)}`;

function isProviderPhoto(url) {
  if (typeof url !== 'string' || !url.trim()) return false;
  try {
    const host = new URL(url.trim()).host.toLowerCase();
    return PHOTO_HOSTS.some((h) => host === h || host.endsWith('.' + h));
  } catch (_) { return false; }
}

const norm = (s) => (s || '').trim().toLowerCase();

async function main() {
  const backup = [];
  let scanned = 0, photoCount = 0, nameCount = 0, sessionCount = 0;
  let last = null;
  for (;;) {
    let q = db.collection('users').orderBy(admin.firestore.FieldPath.documentId()).limit(500);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    if (snap.empty) break;
    for (const doc of snap.docs) {
      scanned++;
      const d = doc.data();
      const update = {};
      if (isProviderPhoto(d.avatarUrl)) update.avatarUrl = pick(CLAIREVATARS);
      // Real-name check against the Firebase Auth account (Google/Apple display name).
      if (d.nickname) {
        let authUser = null;
        try { authUser = await auth.getUser(doc.id); } catch (_) {}
        const social = authUser && authUser.providerData.some((p) => ['google.com', 'apple.com'].includes(p.providerId));
        const realNames = authUser ? [authUser.displayName, ...authUser.providerData.map((p) => p.displayName)]
          .filter(Boolean).map(norm) : [];
        if (social && realNames.includes(norm(d.nickname))) update.nickname = nickname();
      }
      if (!Object.keys(update).length) continue;
      if (update.avatarUrl) photoCount++;
      if (update.nickname) nameCount++;
      backup.push({ uid: doc.id, before: { avatarUrl: d.avatarUrl, nickname: d.nickname }, after: update });
      const sessions = await db.collection('sessions').where('userId', '==', doc.id).get();
      for (const s of sessions.docs) {
        const sd = s.data();
        const su = {};
        if (update.avatarUrl && isProviderPhoto(sd.userAvatarUrl)) su.userAvatarUrl = update.avatarUrl;
        if (update.nickname && norm(sd.userNickname) === norm(d.nickname)) su.userNickname = update.nickname;
        if (!Object.keys(su).length) continue;
        sessionCount++;
        if (APPLY) await s.ref.update(su);
      }
      if (APPLY) await doc.ref.update(update);
    }
    last = snap.docs[snap.docs.length - 1];
  }
  const file = `anonymize-backup-${Date.now()}.json`;
  fs.writeFileSync(file, JSON.stringify(backup, null, 2));
  console.log(`${APPLY ? 'APPLIED' : 'DRY RUN'}: scanned ${scanned} users; ` +
    `${photoCount} with a provider photo, ${nameCount} with their real name as nickname, ` +
    `${sessionCount} sessions to update. Details in ${file}`);
}

main().catch((e) => { console.error(e); process.exit(1); });
