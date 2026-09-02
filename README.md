# AGE OF TITANS

Android-ready Godot 4 project for a fantasy online strategy game.

## Open in Godot
1. Install Godot 4.x with Android export support.
2. Import this folder (the folder containing `project.godot`).
3. Press Play to run the game.

## Android APK
1. In Godot open **Project > Install Android Build Template** if prompted.
2. Open **Project > Export**.
3. Select the **Android** preset already included in `export_presets.cfg`.
4. For testing choose **Export Project** and save an APK.
5. For Google Play use a signed **AAB** and a release keystore.

The project uses Godot's Compatibility renderer and includes ARMv7 + ARM64 Android architectures.

## Important
The current game client contains a local matchmaking/battle simulator. The `server/` directory is a separate development backend. A production online game still needs deployed hosting, secure authentication, a real database, TLS, server-authoritative combat, anti-cheat, backups and monitoring.
