#include "flutter_window.h"

#include <optional>
#include <algorithm>
#include <cmath>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_GETMINMAXINFO: {
      const UINT dpi = GetDpiForWindow(hwnd);
      RECT minimum = {0, 0, MulDiv(960, dpi, 96), MulDiv(720, dpi, 96)};
      AdjustWindowRectExForDpi(&minimum,
          static_cast<DWORD>(GetWindowLongPtr(hwnd, GWL_STYLE)), FALSE,
          static_cast<DWORD>(GetWindowLongPtr(hwnd, GWL_EXSTYLE)), dpi);
      auto info = reinterpret_cast<MINMAXINFO*>(lparam);
      info->ptMinTrackSize = {minimum.right - minimum.left,
                             minimum.bottom - minimum.top};
      return 0;
    }
    case WM_SIZING: {
      RECT outer;
      RECT client;
      GetWindowRect(hwnd, &outer);
      GetClientRect(hwnd, &client);
      const LONG border_width = outer.right - outer.left - client.right;
      const LONG border_height = outer.bottom - outer.top - client.bottom;
      auto proposed = reinterpret_cast<RECT*>(lparam);
      const UINT dpi = GetDpiForWindow(hwnd);
      LONG width = proposed->right - proposed->left - border_width;
      LONG height = proposed->bottom - proposed->top - border_height;
      // Top/bottom drags follow height; all side/corner drags follow width.
      if (wparam == WMSZ_TOP || wparam == WMSZ_BOTTOM) {
        height = std::max(height, static_cast<LONG>(MulDiv(720, dpi, 96)));
        width = static_cast<LONG>(std::lround(height * 4.0 / 3.0));
      } else {
        width = std::max(width, static_cast<LONG>(MulDiv(960, dpi, 96)));
        height = static_cast<LONG>(std::lround(width * 3.0 / 4.0));
      }
      if (wparam == WMSZ_LEFT || wparam == WMSZ_TOPLEFT || wparam == WMSZ_BOTTOMLEFT) {
        proposed->left = proposed->right - width - border_width;
      } else {
        proposed->right = proposed->left + width + border_width;
      }
      if (wparam == WMSZ_TOP || wparam == WMSZ_TOPLEFT || wparam == WMSZ_TOPRIGHT) {
        proposed->top = proposed->bottom - height - border_height;
      } else {
        proposed->bottom = proposed->top + height + border_height;
      }
      return TRUE;
    }
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
