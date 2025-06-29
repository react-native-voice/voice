# Local Development Guide

This guide explains how to test local changes to this library (`@react-native-voice/voice`) in another React Native project without needing to publish the changes to npm.

The `file:` method in `package.json` may not work correctly for libraries with native code because it doesn't run the necessary build steps. The following process ensures that the library is compiled and packaged in the same way as if it were downloaded from npm.

## Local Linking Process

Follow these steps each time you make a change to the library and want to test it in your application.

### Step 1: Compile the Library

The library's source code is written in TypeScript (`src/`) and needs to be compiled to JavaScript (`dist/`).

1.  Open a terminal in the root directory of this library (`voice`).
2.  Run the following command to compile the code:

    ```bash
    yarn prepare
    ```

    This will run the TypeScript compiler (`tsc`) and create the `dist/` folder with the JavaScript code required for React Native to work.

### Step 2: Package the Library

Next, create a compressed package (`.tgz`) of the library, which is the same format that npm uses to distribute packages.

1.  In the same directory, run:

    ```bash
    npm pack
    ```

2.  This command will create a file with a name similar to `react-native-voice-voice-x.x.x.tgz`. This file contains all the library's files, ready to be installed.

### Step 3: Move the Package to Your Project

Copy the `.tgz` file you just created to the root of the project where you want to test the library.

```bash
# Example: Copy from the 'voice' library to your 'MyApp' project
# Make sure to replace the paths with your own
cp /path/to/voice/react-native-voice-voice-x.x.x.tgz /path/to/MyApp/
```

### Step 4: Install the Local Package in Your Project

Now, navigate to your project's folder and install the library from the `.tgz` file.

1.  Open a terminal in the root directory of your project (e.g., `MyApp`).
2.  **Important:** If you already have a version of the library installed, uninstall it first to avoid conflicts:

    ```bash
    yarn remove @react-native-voice/voice
    ```

3.  Install the library from the local file:

    ```bash
    # Replace the filename with the one you generated
    yarn add file:./react-native-voice-voice-x.x.x.tgz
    ```

    This will install the library into your `node_modules` and add the correct reference in your `package.json`.

### Step 5: Rebuild Your Application

Because this library contains native code (Kotlin/Swift), it is **crucial** that you rebuild your application so that the changes are compiled and included in your app.

1.  In your project's directory, run:

    ```bash
    # For Android
    npx react-native run-android

    # For iOS
    npx react-native run-ios
    ```

That's it! Your application will now be using the local version of the library with all your changes.

---

**Note:** You will need to repeat this process (compile, pack, copy, install, and rebuild) every time you make new changes to the library that you want to test.
