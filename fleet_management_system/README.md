# fleet_management_system

# Pre-requisites to work with this project in local projects

## android\app\src\main\AndroidManifest.xml

Make sure to get the bluetooth permissions from this file

## pubspec.yaml

Make sure to get all the dependencies
Make sure to update image path

# Fixing error of the flutter_bluetooth_serial dependency

1. Run the project and in the error the path of the build.gradle for the relevant will be present using that go to that file. ( ex. "C:\Users\GustAcc\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_bluetooth_serial-0.4.0\android\build.gradle" )

2. In the build.gradle file Inside the "android" block add "namespace 'com.pauldemarco.flutter_bluetooth_serial' "

Similar to below example

```
android {
compileSdkVersion 30
compileOptions {
sourceCompatibility JavaVersion.VERSION_1_8
targetCompatibility JavaVersion.VERSION_1_8
}
defaultConfig {
minSdkVersion 19
testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
}
lintOptions {
disable 'InvalidPackage'
}
dependencies {
implementation 'androidx.appcompat:appcompat:1.3.0'
}
buildToolsVersion '30.0.3'
namespace 'com.pauldemarco.flutter_bluetooth_serial' // <-- ADD THIS
}
```

3. After that naviagte to the "src\main\AndroidManifest.xml" in the same android directory. (ex complete path of file: "C:\Users\GustAcc\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_bluetooth_serial-0.4.0\android\src\main\AndroidManifest.xml")

4. In that at the top remove the " package="io.github.edufolly.flutterbluetoothserial" "

ex.

before change

```
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="io.github.edufolly.flutterbluetoothserial">
```

after the change

```
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
```
