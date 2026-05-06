#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Configuration
const SUPABASE_URL = 'https://iuhecyqizatkiskoznwq.supabase.co';
const PROJECT_REF = 'iuhecyqizatkiskoznwq';
// Use service role key - admin has full permissions, bypasses RLS
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
const APK_PATH = path.join(__dirname, 'releases/apne-saathi.apk');
const BUCKET_NAME = 'app-releases';
const FILE_NAME = 'apne-saathi-latest.apk';

async function uploadAPK() {
  console.log('📤 Uploading APK to Supabase Storage...\n');

  // Check if file exists
  if (!fs.existsSync(APK_PATH)) {
    console.error(`❌ APK not found: ${APK_PATH}`);
    process.exit(1);
  }

  const fileSize = fs.statSync(APK_PATH).size / (1024 * 1024);
  console.log(`📦 File: ${FILE_NAME}`);
  console.log(`📊 Size: ${fileSize.toFixed(2)} MB`);
  console.log(`🔗 URL: ${SUPABASE_URL}/storage/v1/object/public/${BUCKET_NAME}/${FILE_NAME}\n`);

  if (!SERVICE_ROLE_KEY) {
    console.log('⚠️  SERVICE_ROLE_KEY not provided.');
    console.log('\n📋 To complete the upload, either:\n');
    console.log('Option 1: Set SERVICE_ROLE_KEY environment variable');
    console.log('  $env:SUPABASE_SERVICE_ROLE_KEY = "<your-service-role-key>"');
    console.log('  node deploy-apk.js\n');
    console.log('Option 2: Upload manually via Supabase Dashboard');
    console.log('  1. Go to: https://app.supabase.com/project/' + PROJECT_REF + '/storage/buckets');
    console.log('  2. Select "app-releases" bucket');
    console.log('  3. Upload: ' + APK_PATH);
    console.log('  4. Rename to: ' + FILE_NAME + '\n');
    console.log('✅ Download URL is already configured in app_settings!');
    process.exit(0);
  }

  try {
    const fileBuffer = fs.readFileSync(APK_PATH);
    const uploadUrl = `${SUPABASE_URL}/storage/v1/object/${BUCKET_NAME}/${FILE_NAME}`;

    console.log('🚀 Uploading...\n');

    const response = await fetch(uploadUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
        'apikey': SERVICE_ROLE_KEY,
      },
      body: fileBuffer,
    });

    const statusCode = response.status;
    const responseText = await response.text();

    if (statusCode === 200 || statusCode === 201) {
      console.log(`✅ APK uploaded successfully!`);
      console.log(`✅ Status: ${statusCode}\n`);
      console.log('📋 Summary:');
      console.log(`  Bucket: ${BUCKET_NAME}`);
      console.log(`  File: ${FILE_NAME}`);
      console.log(`  Size: ${fileSize.toFixed(2)} MB`);
      console.log(`  Download URL: ${SUPABASE_URL}/storage/v1/object/public/${BUCKET_NAME}/${FILE_NAME}`);
      console.log('\n✅ Update check is now configured!');
      console.log('   Users with app version < 0.1.5 will see update prompt.');
    } else {
      console.error(`❌ Upload failed with status ${statusCode}`);
      console.error(`Response: ${responseText}`);
      process.exit(1);
    }
  } catch (error) {
    console.error('❌ Upload error:', error.message);
    process.exit(1);
  }
}

uploadAPK();
