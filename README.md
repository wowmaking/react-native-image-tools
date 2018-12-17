# react-native-image-tools-wm
A collection of image processing tools for React Native

## Getting started

`$ npm install react-native-image-tools-wm --save`

### Automatic installation

`$ react-native link react-native-image-tools-wm`

### Manual installation

#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-image-tools-wm` and add `RNImageTools.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNImageTools.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)

#### iOS CocoaPods
1. Add `pod 'RNImageTools', :path => '../node_modules/react-native-image-tools-wm'` to your `ios/Podfile`
2. Run `pod install` while in `ios` directory

#### Android

1. Open up `android/app/src/main/java/[...]/MainApplication.java`

- Add `import net.wowmaking.RNImageToolsPackage;` to the imports at the top of the file
- Add `new RNImageToolsPackage()` to the list returned by the `getPackages()` method

2. Append the following lines to `android/settings.gradle`:
   ```
   include ':react-native-image-tools-wm'
   project(':react-native-image-tools-wm').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-image-tools-wm/android')
   ```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
   ```
     implementation project(':react-native-image-tools-wm')
   ```
## Usage

```javascript
import RNImageTools from 'react-native-image-tools-wm';
```
See examples in the API section.

## API
### mask(image, maskImage)
#### Parameter(s)
* **image:** String - path to image
* **maskImage:** String - path to mask image
* **options:** Object 
    * **trimTransparency:** Boolean
#### Returns Promise of
* **maskedImage:** Object 
    * **uri:** String
    * **width:** Number
    * **height:** Number
```javascript
RNImageTools.mask(image, maskImage, {
  trimTransparency: true
}).then(({ uri, width, height }) => {
    // Sync with your app state
}).catch(console.error);
```


### transform(image, translateX, translateY, scale, rotate)
#### Parameter(s)
* **image:** String - path to image
* **translateX:** Number
* **translateY:** Number
* **scale:** Number
* **rotate:** Number - in degrees
#### Returns Promise of
* **transformedImage:** Object 
    * **uri:** String
    * **width:** Number
    * **height:** Number
```javascript
RNImageTools.transform(image, 10, -10, 1.25, 45)
  .then(({ uri, width, height }) => {
      // Sync with your app state
  })
  .catch(console.error);
```


### resize(image, width, height)
#### Parameter(s)
* **image:** String - path to image
* **width:** Number
* **height:** Number - in degrees
#### Returns Promise of
* **resizedImage:** Object 
    * **uri:** String
    * **width:** Number
    * **height:** Number
```javascript
RNImageTools.resize(image, 500, 500)
  .then(({ uri, width, height }) => {
      // Sync with your app state
  })
  .catch(console.error);
```


### crop(image, x, y, width, height)
#### Parameter(s)
* **image:** String - path to image
* **x:** Number - top offset
* **y:** Number - left offset
* **width:** Number
* **height:** Number
#### Returns Promise of
* **croppedImage:** Object 
    * **uri:** String
    * **width:** Number
    * **height:** Number
```javascript
RNImageTools.crop(image, 100, 100, 500, 500)
  .then(({ uri, width, height }) => {
      // Sync with your app state
  })
  .catch(console.error);
```


### createMaskFromShape(options)
Creates a bitmap with white background and draws a black shape from provided points. It's intended usage is to generate mask images on the fly.
#### Parameter(s)
* **options:** Object 
    * **points:** Array of points
        * **point:** Object 
            * **x:** Number
            * **y:** Number
    * **width:** Number
    * **height:** Number
    * **inverted:** Boolean
#### Returns Promise of
* **maskImage:** Object 
    * **uri:** String
    * **width:** Number
    * **height:** Number
```javascript
RNImageTools.createMaskFromShape({
  points: [
    { x: 20, y: 20 },
    { x: 200, y: 200 },
    { x: 200, y: 20 },
    { x: 20, y: 20 },
  ],
  width: 500,
  height: 500,
  inverted: false,
}).then(({ uri, width, height }) => {
  // Sync with your app state
}).catch(console.error);
```

### merge(images)
#### Parameter(s)
* **images:** Array 
    * **uri:** String - path to image
#### Returns Promise of
* **mergedImage:** Object 
    * **uri:** String
    * **width:** Number
    * **height:** Number
```javascript
RNImageTools.merge(
    [
        image1,
        image2,
        image3,
    ]
).then(({ uri, width, height }) => {
  // Sync with your app state
}).catch(console.error);
```