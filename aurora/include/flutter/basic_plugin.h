#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CLIENT_WRAPPER_INCLUDE_BASIC_PLUGIN_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CLIENT_WRAPPER_INCLUDE_BASIC_PLUGIN_H_

#include "binary_messenger.h"
#include "error_or.h"
#include "method_call.h"
#include "method_channel.h"
#include "method_result.h"
#include "plugin_registrar.h"
#include "standard_method_codec.h"

#define CHECK_HAS_ARGS(args, onError)         \
  if (!args) {                                \
    return Result::NoArgumentsError(onError); \
  }

namespace flutter {

template <typename T = EncodableValue, typename Codec = StandardMethodCodec>
class BasicPlugin : public Plugin {
 public:
  using Result = ErrorOr<T>;
  using Call = MethodCall<T>;
  using MethodResultPtr = std::unique_ptr<MethodResult<T>>;

  BasicPlugin(const std::string& name, BinaryMessenger* messenger)
      : channel_(std::make_unique<MethodChannel<T>>(messenger,
                                                    name,
                                                    &Codec::GetInstance())) {
    channel_->SetMethodCallHandler([this](const Call& call,
                                          MethodResultPtr result) {
      if (Preprocess(call, result) && result) {
        HandleMethodCall(call.method_name(), call.arguments()).Apply(*result);
      }
    });
  }

 protected:
  virtual bool Preprocess(const Call& /*call*/, MethodResultPtr& /*result*/) {
    return true;
  }

  virtual Result HandleMethodCall(const std::string& name,
                                  const T* arguments) = 0;

  void InvokeMethod(const std::string& name, std::unique_ptr<T>&& args) {
    channel_->InvokeMethod(name, std::move(args));
  }

 private:
  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<MethodChannel<T>> channel_;
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CLIENT_WRAPPER_INCLUDE_BASIC_PLUGIN_H_
