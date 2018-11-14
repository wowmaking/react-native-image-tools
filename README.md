# react-native-image-tools

## Getting started

`$ npm install react-native-image-tools --save`

### Mostly automatic installation

`$ react-native link react-native-image-tools`

### Manual installation

#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-image-tools` and add `RNImageTools.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNImageTools.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)

#### iOS CocoaPods
1. Add `pod 'RNImageTools', :path => '../node_modules/react-native-image-tools'` to your `ios/Podfile`
2. Run `pod install` while in `ios` directory

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`

- Add `import com.wowmaking.RNImageToolsPackage;` to the imports at the top of the file
- Add `new RNImageToolsPackage()` to the list returned by the `getPackages()` method

2. Append the following lines to `android/settings.gradle`:
   ```
   include ':react-native-image-tools'
   project(':react-native-image-tools').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-image-tools/android')
   ```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
   ```
     compile project(':react-native-image-tools')
   ```
## Usage

```javascript
import RNImageTools from 'react-native-image-tools';
```
See examples in the API section.

## API
### mask(image, maskImage)
#### Platform support warning
Not implemented on Android yet.
#### Parameter(s)
* **image:** path to image
* **maskImage:** path to mask image
#### Returns Promise of
* **product:** 
    * **path:** String
    * **width:** Number
    * **height:** Number
```javascript
RNImageTools.mask(image, maskImage)
  .then(({ path, width, height }) => {
      // Sync with your app state
  })
  .catch(console.error);
```