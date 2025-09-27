import os
import shutil
import subprocess
import requests
import yaml

# إعدادات
original_apk = "app-arm64-v8a-release.apk"
final_apk = "app-release.apk"
apk_source_path = os.path.join("build", "app", "outputs", "flutter-apk", original_apk)
public_dir = os.path.join(os.getcwd(), "public")
apk_dest_path = os.path.join(public_dir, final_apk)
firebase_url = "https://fapp-e0966-default-rtdb.firebaseio.com/app_update.json"
flutter_path = r"C:\flutter\bin\flutter.bat"

# 1. قراءة نسخة التطبيق
print("📄 قراءة نسخة التطبيق...")
with open("pubspec.yaml", "r", encoding="utf-8") as f:
    pubspec = yaml.safe_load(f)
version = pubspec.get("version", "1.0.0").split("+")[0]

# 2. التحقق من النسخة الحالية في Firebase
print("🔎 التحقق من Firebase...")
try:
    current_data = requests.get(firebase_url).json()
    if current_data.get("latest_version") == version:
        print(f"ℹ️ نفس النسخة ({version}) مرفوعة مسبقًا، لا حاجة للتحديث.")
        exit(0)
except Exception:
    print("⚠️ تعذر الاتصال بـ Firebase، سيتم المتابعة...")

# 3. بناء APK
print("🚧 جاري بناء APK...")
build = subprocess.run([flutter_path, "build", "apk", "--release", "--split-per-abi"])
if build.returncode != 0 or not os.path.exists(apk_source_path):
    print("❌ فشل البناء أو لم يتم العثور على APK.")
    exit(1)

# 4. حذف النسخة القديمة
if os.path.exists(apk_dest_path):
    print("🧹 حذف النسخة القديمة من public...")
    os.remove(apk_dest_path)

# 5. نسخ النسخة الجديدة
print(f"✅ نقل النسخة إلى: {apk_dest_path}")
os.makedirs(public_dir, exist_ok=True)
shutil.copy2(apk_source_path, apk_dest_path)

# 6. نشر إلى Firebase Hosting
print("🚀 رفع APK إلى Firebase Hosting...")
try:
    subprocess.run([
        "firebase", "deploy",
        "--only", "hosting",
        "--project", "fapp-e0966",
        "--force"
    ], shell=True, check=True)

    apk_url = f"https://fapp-e0966.web.app/{final_apk}?v={version}"  # ✅ كاش بستر
    print("🎉 تم رفع التطبيق إلى Firebase Hosting بنجاح!")
    print(f"🔗 رابط التحميل المباشر: {apk_url}")

except subprocess.CalledProcessError as e:
    print(f"❌ فشل رفع Firebase Hosting: {e}")
    exit(1)

# 7. تحديث قاعدة البيانات
print("📡 تحديث قاعدة بيانات Firebase...")
payload = {
    "latest_version": version,
    "apk_url": apk_url
}
response = requests.patch(firebase_url, json=payload)
print("🔄 الرد من Firebase:", response.status_code, response.text)

if response.status_code == 200:
    print("🎯 تم تحديث Firebase Realtime بنجاح!")
    print("🔗 الرابط:", payload["apk_url"])
else:
    print(f"❌ فشل التحديث: {response.status_code} - {response.text}")
