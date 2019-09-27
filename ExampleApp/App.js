import React, {Component} from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TouchableOpacity,
  SafeAreaView,
  Image,
} from 'react-native';
import RNImageTools from 'react-native-image-tools-wm';

const assetSource = Image.resolveAssetSource(require('./image.jpg'));
const balloonsAssetSource = Image.resolveAssetSource(require('./balloons.png'));

const TARGET_IMAGE_WIDTH = 200;
const TARGET_IMAGE_HEIGHT = 200;

const Button = ({ text, onPress }) => (
  <TouchableOpacity style={styles.btn} onPress={onPress}>
    <Text style={styles.btnText}>{text}</Text>
  </TouchableOpacity>
);

export default class App extends Component {

  state = {
    previewImageSource: null,
  };

  handleResizeImage = () => {
    RNImageTools.resize(assetSource.uri, TARGET_IMAGE_WIDTH, TARGET_IMAGE_HEIGHT).then(result => {
      this.setState({
        previewImageSource: result
      });
    }).catch(console.error);
  };

  handleCropImage = () => {
    RNImageTools.crop(assetSource.uri, 50, 50, TARGET_IMAGE_WIDTH, TARGET_IMAGE_HEIGHT).then(result => {
      this.setState({
        previewImageSource: result
      });
    }).catch(console.error);
  };

  handleCreateMask = () => {
    RNImageTools.createMaskFromShape({
      points: [
        { x: 10, y: 10 },
        { x: 80, y: 80 },
        { x: 80, y: 10 },
        { x: 10, y: 10 },
      ],
      width: TARGET_IMAGE_WIDTH,
      height: TARGET_IMAGE_HEIGHT,
      inverted: true,
    }).then(result => {
      this.setState({
        previewImageSource: result
      });
    }).catch(console.error);
  };

  handleMaskImage = () => {
    RNImageTools.createMaskFromShape({
      points: [
        { x: 10, y: 10 },
        { x: 80, y: 80 },
        { x: 80, y: 10 },
        { x: 10, y: 10 },
      ],
      width: TARGET_IMAGE_WIDTH,
      height: TARGET_IMAGE_HEIGHT,
      inverted: true,
    }).then(maskImage => {
      return RNImageTools.mask(assetSource.uri, maskImage.uri, {
        trimTransparency: true
      }).then(maskedImage => {
        this.setState({
          previewImageSource: maskedImage
        });
      }).catch(console.error);
    }).catch(console.error);
  };

  handleMergeImages = () => {
    RNImageTools.merge([
      assetSource.uri,
      balloonsAssetSource.uri,
    ]).then(mergedImage => {
      this.setState({
        previewImageSource: mergedImage
      });
    }).catch(console.error);
  };

  handleTransformImage = () => {
    RNImageTools.transform(balloonsAssetSource.uri, 10, -10, 0.9, 45).then(result => {
      this.setState({
        previewImageSource: result
      });
    }).catch(console.error);
  };


  render() {
    return (
      <SafeAreaView style={styles.container}>
        <ScrollView>
          <View style={styles.group}>
            <Text style={styles.title}>Preview</Text>
            <View style={styles.preview}>
              {this.state.previewImageSource ?  (
                <Image style={styles.previewImage} source={this.state.previewImageSource} />
              ) : (
                <Text style={styles.previewText}>No image</Text>
              )}
            </View>
          </View>
          <View style={styles.group}>
            <Text style={styles.title}>Methods</Text>
            <View style={styles.row}>
              <Button text={'Resize image'} onPress={this.handleResizeImage} />
              <Button text={'Transform image'} onPress={this.handleTransformImage} />
              <Button text={'Crop image'} onPress={this.handleCropImage} />
              <Button text={'Create mask from shape'} onPress={this.handleCreateMask} />
              <Button text={'Mask image'} onPress={this.handleMaskImage} />
              <Button text={'Merge images'} onPress={this.handleMergeImages} />
            </View>
          </View>
        </ScrollView>
      </SafeAreaView>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#f4f4fb",
  },
  btn: {
    backgroundColor: "#1c76ee",
    margin: 5,
    paddingVertical: 5,
    paddingHorizontal: 10,
    borderRadius: 100
  },
  btnText: {
    color: "#fff",
    fontSize: 14,
    fontWeight: "bold"
  },
  row: {
    flexDirection: "row",
    flexWrap: "wrap",
    alignItems: "center",
    justifyContent: "center",
    padding: 3
  },
  col: {
    alignItems: "center",
    justifyContent: "center",
    padding: 3
  },
  textContent: {
    padding: 3,
    alignItems: "center"
  },
  group: {
    marginVertical: 5,
    minWidth: "100%",
  },
  title: {
    fontWeight: "bold",
    width: "100%",
    backgroundColor: "#e6e1e4",
    textAlign: "center",
    padding: 3
  },
  preview: {
    backgroundColor: '#343434',
    minHeight: TARGET_IMAGE_HEIGHT,
    alignItems: 'center',
    justifyContent: 'center',
  },
  previewText: {
    color: "#fff",
  },
  previewImage: {
    maxWidth: '100%'
  },
});