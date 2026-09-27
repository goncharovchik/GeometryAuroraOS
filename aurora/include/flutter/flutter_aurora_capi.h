#ifndef FLUTTER_SHELL_PLATFORM_PUBLIC_FLUTTER_AURORA_CAPI_H_
#define FLUTTER_SHELL_PLATFORM_PUBLIC_FLUTTER_AURORA_CAPI_H_

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "flutter_aurora_export.h"
#include "flutter_plugin_registrar.h"

#if defined(__cplusplus)
extern "C" {
#endif

/// Opaque reference to a application instance.
typedef struct _FlutterAuroraApplication* FlutterAuroraApplicationRef;

/// Register plugins callback.
typedef void (*FlutterAuroraPluginsRegisterCallback)(
    FlutterDesktopPluginRegistrarRef registrar,
    FlutterAuroraEngineRef engine_ref,
    void* user_data);

/// Callback for FlutterAuroraCallback struct
typedef void (*FlutterAuroraVoidCallback)(void* user_data);

typedef enum {
  // The application initializes the graphics window and keyboard, but they
  // can be disabled via the '--no-gui' command line argument.
  FlutterAuroraGuiEnabled = 0,
  // The application will initialize the graphics window and the keyboard.
  FlutterAuroraGuiForceEnabled,
  // The application will not initialize the graphics window and keyboard.
  FlutterAuroraGuiForceDisabled,
} FlutterAuroraGuiType;

/// Flags for FlutterAuroraLaunchOptions.
typedef enum {
  // Disable virtual keyboard initialization on Application start. This flag
  // using if `gui_type` is `FlutterAuroraGuiEnabled` or
  // `FlutterAuroraGuiForceEnabled`.
  kFlutterAuroraExecFlagNoVirtualKeyboard = 1 << 0,

  // Statusbar always visible. Ignore system settings value.
  kFlutterAuroraExecFlagStatusbarAlwaysVisible = 1 << 1,

  // Force enable of Impeller rendering backend
  kFlutterAuroraExecFlagImpeller = 1 << 2,

} FlutterAuroraExecFlags;

typedef struct {
  // The size of this struct. Must be sizeof(FlutterAuroraExecOptions).
  size_t struct_size;
  // The name of the custom entry point or NULL. If NULL is set, the entry point
  // specified by the --dart-entry-point command line argument will be chosen,
  // if no command line argument is specified, the 'main' entry point will be
  // chosen.
  const char* dart_entry_point;
  // The type of initialization of the graphics window and keyboard in the
  // application.
  FlutterAuroraGuiType gui_type;
  // Launch flags. This field have to contains a bitset of
  // FlutterAuroraLaunchFlags.
  uint32_t flags;
  // Register plugins callback.
  FlutterAuroraPluginsRegisterCallback plugins_register_callback;
  /// User data to be returned on the invocation of callbacks.
  void* user_data;

} FlutterAuroraExecOptions;

typedef struct {
  // The size of this struct. Must be sizeof(FlutterAuroraOSVersion).
  size_t struct_size;

  uint32_t major;

  uint32_t minor;

  uint32_t patch;

  uint32_t build_number;
} FlutterAuroraOSVersion;

typedef struct {
  // The size of this struct. Must be sizeof(FlutterAuroraEmbedderVersion).
  size_t struct_size;

  uint32_t major;

  uint32_t minor;

  uint32_t patch;
} FlutterAuroraEmbedderVersion;

/// Types display orientations.
typedef enum {
  kFADisplayOrientationPortrait = 0,
  kFADisplayOrientationLandscape = 90,
  kFADisplayOrientationPortraitFlipped = 180,
  kFADisplayOrientationLandscapeFlipped = 270,
} FlutterAuroraDisplayOrientationType;

/**
 * Callback for signals
 */
typedef struct {
  // The size of this struct. Must be sizeof(FlutterAuroraSlot).
  size_t struct_size;
  FlutterAuroraVoidCallback callback;
  FlutterAuroraVoidCallback release;
  void* user_data;
} FlutterAuroraSlot;

/**
 * Flutter application initialization, services registration.
 *
 * @returns A pointer to an instance of the application that
 *          is necessary for further work with the app,
 *          e.g. running and releasing it.
 */
FLUTTER_AURORA_EXPORT
FlutterAuroraApplicationRef FlutterAuroraInitialize(int argc, char* argv[]);

/**
 * Initialize launch options with default values.
 *
 * @param options Pointer to launch options.
 * @param struct_size The size of the FlutterAuroraExecOptions struct.
 *                    Must be sizeof(FlutterAuroraExecOptions).
 */
FLUTTER_AURORA_EXPORT
void FlutterAuroraExecOptionsInitDefault(FlutterAuroraExecOptions* options,
                                         size_t struct_size);

/**
 * Launch the Flutter application using the specified options.
 *
 *
 * @param app_ref Pointer to an instance of the Application.
 *                Function will end up with the exit code 1 if nullptr was
 * provided. You must first initialize application and receive a pointer to it
 *                using FlutterAuroraInitialize().
 * @param options Pointer to application exec options.
 *                Use the FlutterAuroraDefaultLaunchOptions() method to get the
 *                default options.
 */
FLUTTER_AURORA_EXPORT
int FlutterAuroraExec(FlutterAuroraApplicationRef app_ref,
                      const FlutterAuroraExecOptions* options);

/**
 * Resetting the application data that we passed to the FlutterAuroraExec()
 * function for corresponding FlutterAuroraApplicationRef.
 * Execute this function in the FlutterApp class destructor.
 *
 * Assigns nullptr to the provided FlutterAuroraApplicationRef.
 *
 * @param app_ref Pointer to an instance of the Application to release.
 *                Will be set to nullptr after release completes.
 */
FLUTTER_AURORA_EXPORT
void FlutterAuroraRelease(FlutterAuroraApplicationRef app_ref);

/**
 * Terminate the Flutter application with the specified exit code.
 *
 * @param exit_code The exit code with which the application process will
 *                  terminate.
 */
FLUTTER_AURORA_EXPORT
void FlutterAuroraExit(int exit_code);

/**
 * Retrieve the dart entry point arguments.
 * This function populates the provided arguments count `argc` and argument
 * vector `argv`.
 *
 * @param argc Pointer to a variable that will be set to the number of
 *             arguments.
 * @param argv Pointer to the string array to which the argument strings will be
 *             set. There is no need to free up memory.
 */
FLUTTER_AURORA_EXPORT
void FlutterAuroraGetDartEntryPointArgs(int* argc, const char* const** argv);

/**
 * Path bundle/lib directory.
 */
FLUTTER_AURORA_EXPORT
int FlutterAuroraGetBundleLibPath(char* out, int out_size);

/**
 * Initialize FlutterAuroraOSVersion struct with 0's set to each field related
 * to version.
 *
 * @param version Pointer to version.
 * @param struct_size The size of FlutterAuroraOSVersion struct.
 *                    Must be sizeof(FlutterAuroraOSVersion).
 */
FLUTTER_AURORA_EXPORT
void FlutterAuroraOSVersionInitDefaults(FlutterAuroraOSVersion* version,
                                        size_t struct_size);

/**
 * Get Aurora OS version values from /etc/os-release file.
 *
 * If some values could not be extracted, they will be set to 0.
 *
 * @param version Pointer to version. The version must be first initialized
 * using FlutterAuroraOSVersionInitDefaults method.
 */
FLUTTER_AURORA_EXPORT
bool FlutterAuroraGetOSVersion(FlutterAuroraOSVersion* version);

/**
 * Initialize FlutterAuroraEmbedderVersion struct with 0's set to each field
 * related to version.
 *
 * @param version Pointer to version.
 * @param struct_size The size of FlutterAuroraEmbedderVersion struct.
 *                    Must be sizeof(FlutterAuroraEmbedderVersion).
 */
FLUTTER_AURORA_EXPORT
void FlutterAuroraEmbedderVersionInitDefaults(
    FlutterAuroraEmbedderVersion* version,
    size_t struct_size);

/**
 * Get Aurora Embedder version.
 *
 * If some values could not be extracted, they will be set to 0.
 *
 * @param version Pointer to version. The version must be first initialized
 * using FlutterAuroraEmbedderVersionInitDefaults method.
 */
FLUTTER_AURORA_EXPORT
bool FlutterAuroraGetEmbedderVersion(FlutterAuroraEmbedderVersion* version);

/**
 * This method returns the window orientation.
 *
 * @param engine Opaque reference to an engine instance.
 */
FLUTTER_AURORA_EXPORT
FlutterAuroraDisplayOrientationType FlutterAuroraGetWindowOrientation(
    FlutterAuroraEngineRef engine);

/**
 * This method returns the device orientation.
 *
 * @param engine Opaque reference to an engine instance.
 */
FLUTTER_AURORA_EXPORT
FlutterAuroraDisplayOrientationType FlutterAuroraGetDeviceOrientation(
    FlutterAuroraEngineRef engine);

/**
 * Subscribe to window orientation changed.
 * @param engine Opaque reference to an engine instance.
 *
 * @param slot The slot structure  pointer that describes the callback
 * parameters. Embedder does not save this pointer and copies fields value. In
 * this argument you can pass temporary structure value.
 *
 * @returns Signal subscription ID. This value can be used to unsubscribe from
 * the signal in FlutterAuroraWindowOrientationChangedUnsubscribe() function.
 */
FLUTTER_AURORA_EXPORT
uint32_t FlutterAuroraWindowOrientationChangedSubscribe(
    FlutterAuroraEngineRef engine,
    FlutterAuroraSlot* slot);

/**
 * Unsubscribe from window orientation changed.
 *
 * @param engine Opaque reference to an engine instance.
 *
 * @param connection_id Value from
 * FlutterAuroraWindowOrientationChangedSubscribe() function.
 */
FLUTTER_AURORA_EXPORT
void FlutterAuroraWindowOrientationChangedUnsubscribe(
    FlutterAuroraEngineRef engine,
    uint32_t connection_id);

/**
 * Subscribe to device orientation changed.
 * @param engine Opaque reference to an engine instance.
 *
 * @param slot The slot structure  pointer that describes the callback
 * parameters. Embedder does not save this pointer and copies fields value. In
 * this argument you can pass temporary structure value.
 *
 * @returns Signal subscription ID. This value can be used to unsubscribe from
 * the signal in FlutterAuroraDeviceOrientationChangedUnsubscribe() function.
 */
FLUTTER_AURORA_EXPORT
uint32_t FlutterAuroraDeviceOrientationChangedSubscribe(
    FlutterAuroraEngineRef engine,
    FlutterAuroraSlot* slot);

/**
 * Unsubscribe from device orientation changed.
 *
 * @param engine Opaque reference to an engine instance.
 *
 * @param connection_id Value from
 * FlutterAuroraDeviceOrientationChangedSubscribe() function.
 */
FLUTTER_AURORA_EXPORT
void FlutterAuroraDeviceOrientationChangedUnsubscribe(
    FlutterAuroraEngineRef engine,
    uint32_t connection_id);

#if defined(__cplusplus)
}
#endif

#endif  // FLUTTER_SHELL_PLATFORM_PUBLIC_FLUTTER_AURORA_CAPI_H_
