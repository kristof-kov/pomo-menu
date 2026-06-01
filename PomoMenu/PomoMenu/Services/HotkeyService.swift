import Cocoa
import Carbon

/// Registers a global CGEventTap hotkey (⌥Space) to toggle Pause/Resume
/// without requiring the user to touch the mouse.
///
/// Requires Accessibility permission: `AXIsProcessTrusted()` must be true.
/// If not granted, prompts macOS to show the Accessibility dialog.
final class HotkeyService {

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var action: (() -> Void)?

    // MARK: - Public API

    /// Call once at app launch, providing the closure to invoke on ⌥Space.
    func register(action: @escaping () -> Void) {
        self.action = action

        guard ensureAccessibilityPermission() else { return }

        // The C callback cannot capture Swift closures, so we pass `self`
        // through the `userInfo` void pointer.
        // passUnretained is safe: HotkeyService owns the tap and outlives it
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let mask: CGEventMask = 1 << CGEventType.keyDown.rawValue

        // CGEvent.tapCreate is the correct Swift API (not CGEventTap.create)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: hotkeyCallback,
            userInfo: selfPtr
        ) else {
            print("[HotkeyService] Failed to create event tap — check Accessibility permission.")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func unregister() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    // MARK: - Private

    fileprivate func handleEvent(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // ⌥Space: keyCode 49 (Space) with .maskAlternate
        if keyCode == 49 && flags.contains(.maskAlternate) {
            DispatchQueue.main.async { [weak self] in self?.action?() }
            return nil  // consume the event
        }
        return Unmanaged.passRetained(event)
    }

    @discardableResult
    private func ensureAccessibilityPermission() -> Bool {
        if AXIsProcessTrusted() { return true }

        // Prompt macOS to show the Accessibility permission dialog
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(opts as CFDictionary)
        return false
    }
}

// MARK: - C-Compatible Callback (must be a free function, no captures)

/// Top-level function satisfying CGEventTapCallBack's C function pointer requirement.
private func hotkeyCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passRetained(event) }
    let service = Unmanaged<HotkeyService>.fromOpaque(userInfo).takeUnretainedValue()
    return service.handleEvent(event)
}
