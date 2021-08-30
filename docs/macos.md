# Install xcode developer tools

    xcode-select --install

# Remap Keys

    # right cmd -> right ctrl
    # left ctrl -> fn
    # fn -> left ctrl
    hidutil property --set '{"UserKeyMapping": [
    {"HIDKeyboardModifierMappingSrc":0x7000000e7, "HIDKeyboardModifierMappingDst":0x7000000e4},
    {"HIDKeyboardModifierMappingSrc":0x7000000e0, "HIDKeyboardModifierMappingDst":1095216660483},
    {"HIDKeyboardModifierMappingSrc":1095216660483, "HIDKeyboardModifierMappingDst":0x7000000e0},
    ]}' > /dev/null

> https://developer.apple.com/library/archive/technotes/tn2450/_index.html

# Use touch id for sudo

    # Make file writable
    sudo chmod 644 /etc/pam.d/sudo

    # Open the sudo utility
    sudo vi /etc/pam.d/sudo

    # Add the following as the first line
    auth sufficient pam_tid.so

# Hide Dock completely

    defaults write com.apple.dock autohide-delay -float 1000; killall Dock

> Back to defaults:
>
>     defaults delete com.apple.Dock autohide-delay && killall Dock
