#./bin/bash

# Simple build script for AgentPet

echo "Building AgentPet.app..."

# Clean old build
rm -rf AgentPet.app

# Create app bundle structure
mkdir -p AgentPet.app/Contents/MacOS
mkdir -p AgentPet.app/Contents/Resources

# Compile Swift code
swiftc AgentPet.swift -o AgentPet.app/Contents/MacOS/AgentPet

# Copy assets
if [ -d "Assets" ]; then
    cp Assets/*.png AgentPet.app/Contents/Resources/
    cp Assets/AppIcon.icns AgentPet.app/Contents/Resources/
fi

# Create Info.plist for app icon
cat <<EOF > AgentPet.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AgentPet</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.jliu.AgentPet</string>
    <key>CFBundleName</key>
    <string>AgentPet</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "Build complete. You can now run AgentPet.app"
