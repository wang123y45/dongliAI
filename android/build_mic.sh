set -e
SDK=/opt/android-sdk
BT=$SDK/build-tools/34.0.0
PLATFORM=$SDK/platforms/android-34/android.jar
WORK=/opt/dongli-build
rm -rf $WORK/app_mic $WORK/build_mic
mkdir -p $WORK/app_mic $WORK/build_mic/classes $WORK/build_mic/dex
unzip -q -o $WORK/src_mic.zip -d $WORK/app_mic
cd $WORK/app_mic

$BT/aapt2 compile --dir res -o $WORK/build_mic/res.zip
$BT/aapt2 link -o $WORK/build_mic/app-unsigned.apk -I $PLATFORM \
  --manifest AndroidManifest.xml -R $WORK/build_mic/res.zip --auto-add-overlay \
  --min-sdk-version 24 --target-sdk-version 34 \
  --version-code 4 --version-name 1.0.3

javac -source 8 -target 8 -bootclasspath $PLATFORM -d $WORK/build_mic/classes \
  src/top/jhcmzy/dongli/MainActivity.java

$BT/d8 --lib $PLATFORM --min-api 24 --output $WORK/build_mic/dex \
  $WORK/build_mic/classes/top/jhcmzy/dongli/*.class

python3 - <<'PY'
import zipfile
apk='/opt/dongli-build/build_mic/app-unsigned.apk'
with zipfile.ZipFile(apk,'a',zipfile.ZIP_DEFLATED) as z:
    z.write('/opt/dongli-build/build_mic/dex/classes.dex','classes.dex')
print('dex added')
PY

$BT/zipalign -f 4 $WORK/build_mic/app-unsigned.apk $WORK/build_mic/app-aligned.apk

if [ ! -f $WORK/dongli.jks ]; then
  echo 'missing signing key'
  exit 1
fi

$BT/apksigner sign --ks $WORK/dongli.jks --ks-pass 'pass:Dongli2026!' --key-pass 'pass:Dongli2026!' \
  --ks-key-alias dongli --out $WORK/dongli-mic.apk $WORK/build_mic/app-aligned.apk
$BT/apksigner verify --print-certs $WORK/dongli-mic.apk | head -8

mkdir -p /www/wwwroot/dongli-ai/public/download
cp -f $WORK/dongli-mic.apk /www/wwwroot/dongli-ai/public/download/dongli.apk
chown www:www /www/wwwroot/dongli-ai/public/download/dongli.apk
chmod 644 /www/wwwroot/dongli-ai/public/download/dongli.apk
ls -lh $WORK/dongli-mic.apk /www/wwwroot/dongli-ai/public/download/dongli.apk
