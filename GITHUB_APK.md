# ساخت APK با GitHub Actions

1. این پوشه را در یک repository گیت‌هاب آپلود کن.
2. در GitHub برو به **Actions**.
3. workflow با نام **AGE OF TITANS - Android APK** را انتخاب کن.
4. روی **Run workflow** بزن.
5. بعد از سبز شدن build، در بخش **Artifacts** فایل `AGE-OF-TITANS-APK` را دانلود کن.

این workflow از Godot 4.3 استفاده می‌کند، چون پروژه با `config/features=...4.3...` ساخته شده است. Godot برای export خط فرمان به یک export preset و template متناظر نیاز دارد.
