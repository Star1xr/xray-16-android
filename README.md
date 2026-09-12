<div align="center">
  <p>
    <a href="https://github.com/OpenXRay">
      <img src="misc/media/OpenXRayCover.png" alt="Open for everyone" />
    </a>
  </p>
</div>

<h1 align="center">
  OpenXRay - Android
</h1>

**OpenXRay** Android portu. S.T.A.L.K.E.R. motorunun OpenGL ES ile çalışan versiyonu.

Bu fork, orijinal xray-16 projesine Android desteği ekler.

## Android Özellikleri

- OpenGL ES 3.0 desteği (TOGLES preprocessor)
- SDL2 tabanlı giriş yönetimi (Bluetooth klavye/fare + gamepad)
- ARM64 (arm64-v8a) mimarisi desteği
- Statik bağlantı (shared libs hariç)
- LuaJIT devre dışı (Android'de uyumsuz)

## Derleme

### Gereksinimler
- Android NDK r26d
- CMake 3.22+
- JDK 17

### Adımlar

```bash
# Repository'yi klonla
git clone --recursive https://github.com/your-username/xray-16-android.git
cd xray-16-android

# CMake ile derle
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-29 \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DXRAY_USE_LUAJIT=OFF \
  -DXRAY_USE_GLES=ON

cmake --build build -j$(nproc)

# Çıktı: build/libxr_3da.so
```

## CI

GitHub Actions ile otomatik derleme. Push/PR ile `libxr_3da.so` üretilir.

**Artifact:** Actions sekmesinden indirebilirsiniz.

## Launcher

Android launcher uygulaması ayrı repodadır:
- [openxray-android-launcher](https://github.com/your-username/openxray-android-launcher)

## Değişiklikler (Orijinal xray-16'dan)

### Eklenen
- `src/Common/PlatformAndroid.inl` — Android platform soyutlama
- `XRAY_USE_GLES` CMake seçeneği
- `TOGLES` preprocessor define'i

### Değiştirilen
- `src/Common/Platform.hpp` — `XR_PLATFORM_ANDROID` algılama
- `cmake/XRay.Compiler.GNULike.cmake` — Android/TOGLES desteği
- `src/xr_3da/CMakeLists.txt` — Android'de shared lib
- `src/Layers/xrRenderGL/glHW.cpp` — GLES bağlamı oluşturma
- `src/Layers/xrRenderPC_GL/rgl_shaders.cpp` — GLSL 300 es
- `src/Layers/xrRenderGL/glR_Backend_Runtime.h` — Draw calls
- `src/Layers/xrRenderGL/glHWCaps.cpp` — GLES caps
- `src/xrCore/LocatorAPI.cpp` — Android dosya sistemi
- `.github/workflows/cibuild.yml` — Android job

## Oyun Desteği

- Call of Chernobyl 1.4.22
- Call of Pripyat 1.6.02
- Clear Sky 1.5.10

## Lisans

Orijinal xray-16 lisansına bakınız.
