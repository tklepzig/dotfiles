# Install xcode developer tools

    xcode-select --install

# Remap Keys

    swapKeys() {
      # right cmd -> right ctrl
      # left ctrl -> fn
      # fn -> left ctrl
      hidutil property --set '{"UserKeyMapping": [
          {"HIDKeyboardModifierMappingSrc":0x7000000e7, "HIDKeyboardModifierMappingDst":0x7000000e4},
          {"HIDKeyboardModifierMappingSrc":0x7000000e0, "HIDKeyboardModifierMappingDst":1095216660483},
          {"HIDKeyboardModifierMappingSrc":1095216660483, "HIDKeyboardModifierMappingDst":0x7000000e0},
      ]}' > /dev/null
    }

    resetSwap() {
      hidutil property --set '{"UserKeyMapping":[]}'
    }

> https://developer.apple.com/library/archive/technotes/tn2450/_index.html

# Use touch id for sudo

    # To enable it also while in tmux
    brew install pam-reattach

    # Make file writable
    sudo chmod 644 /etc/pam.d/sudo

    # Open the sudo utility
    sudo vi /etc/pam.d/sudo

    # Add the following as the first two lines
    auth optional /opt/homebrew/lib/pam/pam_reattach.so
    auth sufficient pam_tid.so

# Hide Dock completely

    defaults write com.apple.dock autohide-delay -float 1000 && killall Dock

> Back to defaults:
>
>     defaults delete com.apple.Dock autohide-delay && killall Dock

# Enable AppSwitcher (Cmd-Tab) on all screens

    defaults write com.apple.dock appswitcher-all-displays -bool true && killall Dock

> Back to defaults:
>
>     defaults write com.apple.dock appswitcher-all-displays -bool false && killall Dock

# Restart Window Manager

    killall -KILL Dock
