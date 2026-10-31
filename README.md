# Geometry Dash (Aurora OS 5 Edition)

2D ритм-платформер на базе фреймворка Flutter для мобильной операционной системы ОС Аврора 5.2.1.
Проект использует нативный C++ Embedder (Wayland/EGL) без применения QML.

---

## Требования для разработки

1. **ОС:** Windows 10 / 11 x64
2. **Git** и **OpenSSH** (клиент ssh должен быть доступен в консоли)
3. **Docker Desktop** (запущенный, с образом `aurora-build-tools:5.2.1.200`)
4. **Aurora OS SDK 5.2.1** (установлен в `C:\AuroraOS` с образом эмулятора QEMU)

> **Важно:** Flutter SDK для Авроры (версия 3.32.7 с рантаймом Dart 3.8.1) устанавливается и настраивается **автоматически** скриптом `setup_environment.bat` (или `setup_environment.ps1`).

---

## Быстрый старт на новом ПК

1. Склонируйте репозиторий:
   ```cmd
   git clone <URL_РЕПОЗИТОРИЯ> game_aurora
   cd game_aurora
   ```

2. Запустите первоначальную настройку окружения (всё установится и пропатчится в 1 клик):
   ```cmd
   setup_environment.bat
   ```
   *Скрипт автоматически склонирует Flutter for Aurora 3.32.7 в `C:\flutter-aurora`, загрузит точный Dart SDK 3.8.1, настроит штампы версий и включит поддержку ОС Аврора.*

3. Соберите RPM и запустите игру в эмуляторе:
   ```powershell
   powershell .\build_and_run_aurora.ps1
   ```

---

## Скрипты управления

| Скрипт | Описание |
|---|---|
| `build_and_run_aurora.ps1` | Полный цикл: сборка Dart-бандла, компиляция RPM в Docker, запуск QEMU, установка пакета и запуск игры. |
| `build_flutter_rpm.ps1` | Сборка чистого RPM-пакета в Docker и копирование в `vmshare`. |
| `run_aurora.ps1` | Быстрый запуск уже установленной игры в эмуляторе Авроры (включение экрана, установка RPM, запуск через invoker). |
| `start_emulator.bat` / `start_emulator.ps1` | Запуск виртуальной машины эмулятора ОС Аврора через QEMU x86_64 с аппаратным ускорением WHPX. |
| `setup_environment.bat` / `setup_environment.ps1` | Мастер автоматической проверки и настройки окружения (Git, SSH, Flutter Aurora SDK, Docker, Aurora SDK, VS Code). |

---

## Структура проекта

* `lib/` — исходный код игры (Dart): физика, рендеринг, игровой цикл, звуковые эффекты и экраны меню.
* `aurora/` — исходники платформы Аврора:
  * `main.cpp` — точка входа C-API Aurora Embedder.
  * `CMakeLists.txt` — CMake-конфигурация нативной сборки.
  * `desktop/ru.aurora.geometry_dash_aurora.desktop` — конфигурация ярлыка рабочего стола (с поддержкой Sailjail).
  * `rpm/ru.aurora.geometry_dash_aurora.spec` — спецификация сборки RPM-пакета.
  * `include/` & `lib/` — заголовочные файлы и библиотеки `libaurora_embedder.so`, `libflutter_engine.so`.
* `icons/` — иконки приложения различных разрешений.
* `test/` — тесты физической модели и логики игры.

---

## Управление в игре

* **Прыжок / Действие:** Пробел (`Space`), Стрелка вверх (`Up Arrow`), левая кнопка мыши или касание сенсорного экрана в эмуляторе.
* **Пауза:** Клавиша `Escape` или кнопка на экране.
