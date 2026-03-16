#include "win32_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>
#include <versionhelpers.h>

#include "resource.h"

namespace {

// ========== Windows 11 视觉效果相关常量 ==========

// DWM 窗口属性 (为旧 SDK 提供兼容性定义)
#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

// Windows 11 Build 22621+ 的新属性
#ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#define DWMWA_WINDOW_CORNER_PREFERENCE 33
#endif

#ifndef DWMWA_BORDER_COLOR
#define DWMWA_BORDER_COLOR 34
#endif

#ifndef DWMWA_CAPTION_COLOR
#define DWMWA_CAPTION_COLOR 35
#endif

// Windows 11 Mica 效果相关 (Build 22621+)
#ifndef DWMWA_MICA_EFFECT
#define DWMWA_MICA_EFFECT 1029
#endif

// 窗口圆角偏好
enum DWM_WINDOW_CORNER_PREFERENCE {
  DWMWCP_DEFAULT = 0,
  DWMWCP_DONOTROUND = 1,
  DWMWCP_ROUND = 2,
  DWMWCP_ROUNDSMALL = 3
};

// ========== 其他常量 ==========

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

// 注册表键 - 系统主题偏好
constexpr const wchar_t kGetPreferredBrightnessRegKey[] =
  L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize";
constexpr const wchar_t kGetPreferredBrightnessRegValue[] = L"AppsUseLightTheme";

// 活跃窗口计数
static int g_active_window_count = 0;

// ========== 类型定义 ==========

using EnableNonClientDpiScaling = BOOL __stdcall(HWND hwnd);

// ========== 辅助函数 ==========

// 缩放帮助函数
int Scale(int source, double scale_factor) {
  return static_cast<int>(source * scale_factor);
}

// 动态加载 DPI 缩放支持
void EnableFullDpiSupportIfAvailable(HWND hwnd) {
  HMODULE user32_module = LoadLibraryA("User32.dll");
  if (!user32_module) {
    return;
  }
  auto enable_non_client_dpi_scaling =
      reinterpret_cast<EnableNonClientDpiScaling*>(
          GetProcAddress(user32_module, "EnableNonClientDpiScaling"));
  if (enable_non_client_dpi_scaling != nullptr) {
    enable_non_client_dpi_scaling(hwnd);
  }
  FreeLibrary(user32_module);
}

// 检测是否为 Windows 11 或更高版本
bool IsWindows11OrGreater() {
  // Windows 11 的版本号是 10.0.22000
  return IsWindows10OrGreater() && LOBYTE(LOWORD(GetVersion())) >= 10 &&
         HIBYTE(LOWORD(GetVersion())) >= 0 &&
         (static_cast<DWORD>(GetVersion()) >= 0x000000A00000 ? true :
          (static_cast<DWORD>(GetVersion()) & 0xFFFF) >= 22000);
}

// 检测是否为 Windows 11 22H2 (Build 22621) 或更高版本
bool IsWindows11_22H2OrGreater() {
  OSVERSIONINFOEXW osvi = { sizeof(osvi), 0, 0, 0, 0, {0}, 0, 0 };
  DWORDLONG const dwlConditionMask = VerSetConditionMask(
    VerSetConditionMask(
      VerSetConditionMask(0, VER_BUILDNUMBER, VER_GREATER_EQUAL),
      VER_MAJORVERSION, VER_GREATER_EQUAL),
    VER_MINORVERSION, VER_GREATER_EQUAL);

  osvi.dwMajorVersion = 10;
  osvi.dwMinorVersion = 0;
  osvi.dwBuildNumber = 22621;

  return VerifyVersionInfoW(&osvi, VER_MAJORVERSION | VER_MINORVERSION | VER_BUILDNUMBER, dwlConditionMask) != FALSE;
}

// 启用 Windows 11 的圆角窗口
void EnableRoundedCorners(HWND hwnd) {
  if (!IsWindows11OrGreater()) {
    return;
  }

  // 尝试使用新版本的 DWM 属性
  typedef HRESULT (WINAPI* PFN_DwmSetWindowAttribute)(HWND, DWORD, LPCVOID, DWORD);

  HMODULE dwmapi = LoadLibraryW(L"dwmapi.dll");
  if (dwmapi) {
    auto DwmSetWindowAttributeFunc =
        reinterpret_cast<PFN_DwmSetWindowAttribute>(
            GetProcAddress(dwmapi, "DwmSetWindowAttribute"));

    if (DwmSetWindowAttributeFunc) {
      // 设置圆角偏好为小圆角（更现代）
      DWM_WINDOW_CORNER_PREFERENCE corner_pref = DWMWCP_ROUNDSMALL;
      DwmSetWindowAttributeFunc(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE,
                                &corner_pref, sizeof(corner_pref));
    }
    FreeLibrary(dwmapi);
  }
}

// 尝试启用 Mica 效果（Windows 11 22H2+）
void TryEnableMicaEffect(HWND hwnd, BOOL is_dark_mode) {
  if (!IsWindows11_22H2OrGreater()) {
    return;
  }

  typedef HRESULT (WINAPI* PFN_DwmSetWindowAttribute)(HWND, DWORD, LPCVOID, DWORD);

  HMODULE dwmapi = LoadLibraryW(L"dwmapi.dll");
  if (dwmapi) {
    auto DwmSetWindowAttributeFunc =
        reinterpret_cast<PFN_DwmSetWindowAttribute>(
            GetProcAddress(dwmapi, "DwmSetWindowAttribute"));

    if (DwmSetWindowAttributeFunc) {
      // 尝试启用 Mica 效果
      // 注意：MICA_EFFECT 只在特定条件下有效（窗口必须有标题栏等）
      // 对于完全自定义标题栏的窗口，可能无法生效
      int mica_enabled = 1;
      DwmSetWindowAttributeFunc(hwnd, DWMWA_MICA_EFFECT,
                                &mica_enabled, sizeof(mica_enabled));
    }
    FreeLibrary(dwmapi);
  }
}

// 设置窗口边框颜色（暗色模式下使用深色边框）
void SetWindowBorderColor(HWND hwnd, BOOL is_dark_mode) {
  if (!IsWindows11OrGreater()) {
    return;
  }

  typedef HRESULT (WINAPI* PFN_DwmSetWindowAttribute)(HWND, DWORD, LPCVOID, DWORD);

  HMODULE dwmapi = LoadLibraryW(L"dwmapi.dll");
  if (dwmapi) {
    auto DwmSetWindowAttributeFunc =
        reinterpret_cast<PFN_DwmSetWindowAttribute>(
            GetProcAddress(dwmapi, "DwmSetWindowAttribute"));

    if (DwmSetWindowAttributeFunc) {
      // 暗色模式使用深色边框
      if (is_dark_mode) {
        COLORREF border_color = RGB(0x30, 0x36, 0x3D);  // #30363D
        DwmSetWindowAttributeFunc(hwnd, DWMWA_BORDER_COLOR,
                                  &border_color, sizeof(border_color));
      }
    }
    FreeLibrary(dwmapi);
  }
}

}  // namespace

// ========== WindowClassRegistrar ==========

class WindowClassRegistrar {
 public:
  ~WindowClassRegistrar() = default;

  static WindowClassRegistrar* GetInstance() {
    if (!instance_) {
      instance_ = new WindowClassRegistrar();
    }
    return instance_;
  }

  const wchar_t* GetWindowClass();
  void UnregisterWindowClass();

 private:
  WindowClassRegistrar() = default;

  static WindowClassRegistrar* instance_;
  bool class_registered_ = false;
};

WindowClassRegistrar* WindowClassRegistrar::instance_ = nullptr;

const wchar_t* WindowClassRegistrar::GetWindowClass() {
  if (!class_registered_) {
    WNDCLASSEXW window_class = {};
    window_class.cbSize = sizeof(WNDCLASSEXW);
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.lpfnWndProc = Win32Window::WndProc;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.hIcon =
        LoadIcon(window_class.hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
    window_class.lpszClassName = kWindowClassName;
    window_class.hbrBackground = nullptr;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;

    RegisterClassExW(&window_class);
    class_registered_ = true;
  }
  return kWindowClassName;
}

void WindowClassRegistrar::UnregisterWindowClass() {
  UnregisterClassW(kWindowClassName, nullptr);
  class_registered_ = false;
}

// ========== Win32Window 实现 ==========

Win32Window::Win32Window() {
  ++g_active_window_count;
}

Win32Window::~Win32Window() {
  --g_active_window_count;
  Destroy();
}

bool Win32Window::Create(const std::wstring& title,
                         const Point& origin,
                         const Size& size) {
  Destroy();

  const wchar_t* window_class =
      WindowClassRegistrar::GetInstance()->GetWindowClass();

  const POINT target_point = {static_cast<LONG>(origin.x),
                              static_cast<LONG>(origin.y)};
  HMONITOR monitor = MonitorFromPoint(target_point, MONITOR_DEFAULTTONEAREST);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  double scale_factor = dpi / 96.0;

  // Windows 11 使用更现代的窗口样式
  DWORD window_style = WS_OVERLAPPEDWINDOW;

  // 创建窗口
  HWND window = CreateWindowExW(
      0,  // dwExStyle
      window_class,
      title.c_str(),
      window_style,
      Scale(origin.x, scale_factor),
      Scale(origin.y, scale_factor),
      Scale(size.width, scale_factor),
      Scale(size.height, scale_factor),
      nullptr,  // parent
      nullptr,  // menu
      GetModuleHandle(nullptr),
      this);

  if (!window) {
    return false;
  }

  // 应用视觉效果
  UpdateTheme(window);

  return OnCreate();
}

bool Win32Window::Show() {
  return ShowWindow(window_handle_, SW_SHOWNORMAL);
}

LRESULT CALLBACK Win32Window::WndProc(HWND const window,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));

    auto that = static_cast<Win32Window*>(window_struct->lpCreateParams);
    EnableFullDpiSupportIfAvailable(window);
    that->window_handle_ = window;

    // Windows 11: 创建后立即设置圆角
    if (IsWindows11OrGreater()) {
      EnableRoundedCorners(window);
    }
  } else if (Win32Window* that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT
Win32Window::MessageHandler(HWND hwnd,
                            UINT const message,
                            WPARAM const wparam,
                            LPARAM const lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      window_handle_ = nullptr;
      Destroy();
      if (quit_on_close_) {
        PostQuitMessage(0);
      }
      return 0;

    case WM_DPICHANGED: {
      auto newRectSize = reinterpret_cast<RECT*>(lparam);
      LONG newWidth = newRectSize->right - newRectSize->left;
      LONG newHeight = newRectSize->bottom - newRectSize->top;

      SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth,
                   newHeight, SWP_NOZORDER | SWP_NOACTIVATE);

      // DPI 变化时重新应用视觉效果
      UpdateTheme(hwnd);
      return 0;
    }

    case WM_SIZE: {
      RECT rect = GetClientArea();
      if (child_content_ != nullptr) {
        MoveWindow(child_content_, rect.left, rect.top, rect.right - rect.left,
                   rect.bottom - rect.top, TRUE);
      }
      return 0;
    }

    case WM_ACTIVATE:
      if (child_content_ != nullptr) {
        SetFocus(child_content_);
      }
      // 窗口激活/失活时更新主题效果
      UpdateTheme(hwnd);
      return 0;

    case WM_DWMCOLORIZATIONCOLORCHANGED:
    case WM_SETTINGCHANGE:
      // 系统设置变化时更新主题
      UpdateTheme(hwnd);
      return 0;

    case WM_THEMECHANGED:
      // 主题变化时更新
      UpdateTheme(hwnd);
      return 0;
  }

  return DefWindowProc(window_handle_, message, wparam, lparam);
}

void Win32Window::Destroy() {
  OnDestroy();

  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
  if (g_active_window_count == 0) {
    WindowClassRegistrar::GetInstance()->UnregisterWindowClass();
  }
}

Win32Window* Win32Window::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(content, window_handle_);
  RECT frame = GetClientArea();

  MoveWindow(content, frame.left, frame.top, frame.right - frame.left,
             frame.bottom - frame.top, true);

  SetFocus(child_content_);
}

RECT Win32Window::GetClientArea() {
  RECT frame;
  GetClientRect(window_handle_, &frame);
  return frame;
}

HWND Win32Window::GetHandle() {
  return window_handle_;
}

void Win32Window::SetQuitOnClose(bool quit_on_close) {
  quit_on_close_ = quit_on_close;
}

bool Win32Window::OnCreate() {
  return true;
}

void Win32Window::OnDestroy() {
  // No-op
}

void Win32Window::UpdateTheme(HWND const window) {
  // 检测系统主题（暗色/亮色）
  DWORD light_mode;
  DWORD light_mode_size = sizeof(light_mode);
  LSTATUS result = RegGetValue(HKEY_CURRENT_USER, kGetPreferredBrightnessRegKey,
                               kGetPreferredBrightnessRegValue,
                               RRF_RT_REG_DWORD, nullptr, &light_mode,
                               &light_mode_size);

  BOOL is_dark_mode = FALSE;
  if (result == ERROR_SUCCESS) {
    is_dark_mode = (light_mode == 0);
  }

  typedef HRESULT (WINAPI* PFN_DwmSetWindowAttribute)(HWND, DWORD, LPCVOID, DWORD);

  HMODULE dwmapi = LoadLibraryW(L"dwmapi.dll");
  if (!dwmapi) {
    return;
  }

  auto DwmSetWindowAttributeFunc =
      reinterpret_cast<PFN_DwmSetWindowAttribute>(
          GetProcAddress(dwmapi, "DwmSetWindowAttribute"));

  if (DwmSetWindowAttributeFunc) {
    // 1. 设置沉浸式暗色模式
    DwmSetWindowAttributeFunc(window, DWMWA_USE_IMMERSIVE_DARK_MODE,
                              &is_dark_mode, sizeof(is_dark_mode));

    // 2. Windows 11: 设置圆角
    if (IsWindows11OrGreater()) {
      DWM_WINDOW_CORNER_PREFERENCE corner_pref = DWMWCP_ROUNDSMALL;
      DwmSetWindowAttributeFunc(window, DWMWA_WINDOW_CORNER_PREFERENCE,
                                &corner_pref, sizeof(corner_pref));
    }

    // 3. Windows 11: 暗色模式下设置边框颜色
    if (IsWindows11OrGreater() && is_dark_mode) {
      COLORREF border_color = RGB(0x30, 0x36, 0x3D);  // #30363D 匹配主题
      DwmSetWindowAttributeFunc(window, DWMWA_BORDER_COLOR,
                                &border_color, sizeof(border_color));
    }

    // 4. Windows 11 22H2+: 尝试启用 Mica 效果
    // 注意：由于我们使用隐藏标题栏（TitleBarStyle.hidden），
    // Mica 可能无法生效，但尝试设置无害
    if (IsWindows11_22H2OrGreater()) {
      // 尝试启用 Mica（在支持的系统上）
      // 对于完全自定义的窗口，这主要影响窗口边框的视觉效果
      BOOL mica_enabled = TRUE;
      // 使用 DWMWA_MICA_EFFECT 如果可用
      // 这是一个较新的属性，仅在 Windows 11 22H2+ 上可用
      // 我们尝试设置它，忽略可能的失败
      DwmSetWindowAttributeFunc(window, static_cast<DWORD>(1029),  // DWMWA_MICA_EFFECT
                                &mica_enabled, sizeof(mica_enabled));
    }
  }

  FreeLibrary(dwmapi);

  // 5. 扩展客户区到框架（移除标题栏分隔线）
  // 这对于实现无缝的沉浸式标题栏很重要
  MARGINS margins = {0, 0, 0, 0};  // 全零表示完全扩展到框架
  DwmExtendFrameIntoClientArea(window, &margins);
}
