#!/bin/bash

PROJECT_NAME="<Your project name>"
PROJECT_DIR="./Packages/${PROJECT_NAME}" # Relative path to the directory containing the `Package.swift` file
BUILD_FOLDER="./build"
OUTPUT_DIR="${PROJECT_DIR}/Output"
SIMULATOR_ARCHIVE="${OUTPUT_DIR}/${PROJECT_NAME}-iphonesimulator.xcarchive"
DEVICE_ARCHIVE="${OUTPUT_DIR}/${PROJECT_NAME}-iphoneos.xcarchive"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 2 iterations: 1 for device arch and another for simulator arch
for PLATFORM in "iOS" "iOS Simulator"; do
    case $PLATFORM in
      "iOS")
        ARCHIVE=$DEVICE_ARCHIVE
        SDK=iphoneos
        RELEASE_FOLDER="Release-iphoneos"
      ;;
      "iOS Simulator")
        ARCHIVE=$SIMULATOR_ARCHIVE
        SDK=iphonesimulator
        RELEASE_FOLDER="Release-iphonesimulator"
      ;;
    esac

    # Step 2
    xcodebuild archive \
      -workspace <your workspace>.xcworkspace \
      -scheme $PROJECT_NAME \
      -destination="generic/platform=${PLATFORM}" \
      -archivePath $ARCHIVE \
      -sdk $SDK \
      -derivedDataPath $BUILD_FOLDER \
      SKIP_INSTALL=NO \
      BUILD_LIBRARY_FOR_DISTRIBUTION=YES

    FRAMEWORK_PATH="${ARCHIVE}/Products/Library/Frameworks/${PROJECT_NAME}.framework"
    MODULES_PATH="$FRAMEWORK_PATH/Modules"
    mkdir -p $MODULES_PATH

    BUILD_PRODUCTS_PATH="${BUILD_FOLDER}/Build/Intermediates.noindex/ArchiveIntermediates/${PROJECT_NAME}/BuildProductsPath"
    RELEASE_PATH="${BUILD_PRODUCTS_PATH}/${RELEASE_FOLDER}"
    SWIFT_MODULE_PATH="${RELEASE_PATH}/${PROJECT_NAME}.swiftmodule"
    RESOURCES_BUNDLE_PATH="${RELEASE_PATH}/${PROJECT_NAME}_${PROJECT_NAME}.bundle"

    # Step 3
    if [ -d $SWIFT_MODULE_PATH ] 
    then
      cp -r $SWIFT_MODULE_PATH $MODULES_PATH
    fi

    # Step 4
    if [ -e $RESOURCES_BUNDLE_PATH ] 
    then
      cp -r $RESOURCES_BUNDLE_PATH $FRAMEWORK_PATH
    fi

done

# Step 5
xcodebuild -create-xcframework \
 -framework "${DEVICE_ARCHIVE}/Products/Library/Frameworks/${PROJECT_NAME}.framework" \
 -framework "${SIMULATOR_ARCHIVE}/Products/Library/Frameworks/${PROJECT_NAME}.framework" \
 -output "${OUTPUT_DIR}/${PROJECT_NAME}.xcframework"