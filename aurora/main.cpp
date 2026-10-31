#include <flutter/flutter_aurora_capi.h>

int main(int argc, char *argv[]) {
    FlutterAuroraApplicationRef app = FlutterAuroraInitialize(argc, argv);
    if (!app) {
        return 1;
    }
    FlutterAuroraExecOptions options;
    FlutterAuroraExecOptionsInitDefault(&options, sizeof(options));
    int result = FlutterAuroraExec(app, &options);
    FlutterAuroraRelease(app);
    return result;
}
