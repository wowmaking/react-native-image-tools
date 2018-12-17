package net.wowmaking;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableMap;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.HashMap;
import java.util.UUID;

final class Utility {
    static WritableMap buildImageReactMap (File file, Bitmap bmp) {
        WritableMap map = Arguments.createMap();
        map.putString("uri", "file://" + file.toString());
        map.putDouble("width", bmp.getWidth());
        map.putDouble("height", bmp.getHeight());
        return map;
    }

    static Bitmap bitmapFromUriString (String uriString, final Promise promise) {
        try {
            URL url = new URL(uriString);
            try {
                Bitmap bmp = BitmapFactory.decodeStream(url.openConnection().getInputStream());
                return bmp;
            } catch (IOException e) {
                handleError(e, promise);
            }
        } catch (MalformedURLException e) {
            handleError(e, promise);
        }
        return null;
    }

    static void handleError(Exception e, Promise promise) {
        e.printStackTrace(System.err);
        promise.reject(e);
    }

    static File createRandomPNGFile (ReactContext context) {
        String filename = UUID.randomUUID().toString() + ".png";
        return new File(context.getFilesDir(), filename);
    }



    static void writeBMPToPNGFile (Bitmap bmp, File file, Promise promise) {
        try {
            FileOutputStream out = new FileOutputStream(file);
            bmp.compress(Bitmap.CompressFormat.PNG, 100, out);
            out.close();
        } catch (IOException e) {
            handleError(e, promise);
        }
    }

    static Bitmap trimTransparency(Bitmap source) {
        int firstX = 0, firstY = 0;
        int lastX = source.getWidth();
        int lastY = source.getHeight();
        int[] pixels = new int[source.getWidth() * source.getHeight()];
        source.getPixels(pixels, 0, source.getWidth(), 0, 0, source.getWidth(), source.getHeight());
        loop:
        for (int x = 0; x < source.getWidth(); x++) {
            for (int y = 0; y < source.getHeight(); y++) {
                if (pixels[x + (y * source.getWidth())] != Color.TRANSPARENT) {
                    firstX = x;
                    break loop;
                }
            }
        }
        loop:
        for (int y = 0; y < source.getHeight(); y++) {
            for (int x = firstX; x < source.getWidth(); x++) {
                if (pixels[x + (y * source.getWidth())] != Color.TRANSPARENT) {
                    firstY = y;
                    break loop;
                }
            }
        }
        loop:
        for (int x = source.getWidth() - 1; x >= firstX; x--) {
            for (int y = source.getHeight() - 1; y >= firstY; y--) {
                if (pixels[x + (y * source.getWidth())] != Color.TRANSPARENT) {
                    lastX = x;
                    break loop;
                }
            }
        }
        loop:
        for (int y = source.getHeight() - 1; y >= firstY; y--) {
            for (int x = source.getWidth() - 1; x >= firstX; x--) {
                if (pixels[x + (y * source.getWidth())] != Color.TRANSPARENT) {
                    lastY = y;
                    break loop;
                }
            }
        }
        return Bitmap.createBitmap(source, firstX, firstY, lastX - firstX, lastY - firstY);
    }

    static HashMap calcRectForContainedRect(int srcWidth, int srcHeight, int dstWidth, int dstHeight) {
        int width;
        int height;
        int x;
        int y;

        if (srcWidth > srcHeight) {
            width = dstWidth;
            height = srcHeight * dstWidth / srcWidth;
            x = 0;
            y = dstHeight / 2 - height / 2;
        } else {
            width = srcWidth * dstHeight / srcHeight;
            height = dstHeight;
            x = dstWidth / 2 - width / 2;
            y = 0;
        }


        HashMap map = new HashMap<String, Integer>();
        map.put("width", width);
        map.put("height", height);
        map.put("x", x);
        map.put("y", y);

        return map;
    }
}
