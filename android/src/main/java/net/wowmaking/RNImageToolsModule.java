
package net.wowmaking;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;

import java.io.File;
import java.util.HashMap;

public class RNImageToolsModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;

    public RNImageToolsModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @ReactMethod
    public void resize(String uriString, int width, int height, final Promise promise) {
        Bitmap bmp = Utility.bitmapFromUriString(uriString, promise, reactContext);
        if (bmp == null) {
            return;
        }

        final HashMap containedRectMap = Utility.calcRectForContainedRect(
            bmp.getWidth(), bmp.getHeight(),
            width, height
        );
        int rectWidth = (int) containedRectMap.get("width");
        int rectHeight = (int) containedRectMap.get("height");
        int rectX = (int) containedRectMap.get("x");
        int rectY = (int) containedRectMap.get("y");

        Bitmap editBmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(editBmp);

        Rect srcRect = new Rect(0, 0, bmp.getWidth(), bmp.getHeight());
        Rect dstRect = new Rect(rectX, rectY, rectWidth + rectX, rectHeight + rectY);

        canvas.drawBitmap(bmp, srcRect, dstRect, null);

        File file = Utility.createRandomPNGFile(reactContext);
        Utility.writeBMPToPNGFile(editBmp, file, promise);

        final WritableMap map = Utility.buildImageReactMap(file, editBmp);
        promise.resolve(map);
    }

    @ReactMethod
    public void crop(String uriString, int x, int y, int width, int height, final Promise promise) {
        Bitmap bmp = Utility.bitmapFromUriString(uriString, promise, reactContext);
        if (bmp == null) {
            return;
        }
        Bitmap croppedBmp = Bitmap.createBitmap(bmp, x, y, width, height);

        File file = Utility.createRandomPNGFile(reactContext);
        Utility.writeBMPToPNGFile(croppedBmp, file, promise);

        final WritableMap map = Utility.buildImageReactMap(file, croppedBmp);
        promise.resolve(map);
    }

    @ReactMethod
    public void transform(String uriString, float translateX, float translateY, float rotate, float scale, final Promise promise) {
        Bitmap bmp = Utility.bitmapFromUriString(uriString, promise, reactContext);
        if (bmp == null) {
            return;
        }
        Matrix mtrx = new Matrix();
        mtrx.preTranslate(translateX, translateY);
        mtrx.preTranslate(bmp.getWidth() / 2 * (1 - scale), bmp.getHeight() / 2 * (1 - scale));
        mtrx.preScale(scale, scale);
        mtrx.preRotate(rotate, bmp.getWidth() / 2, bmp.getHeight() / 2);

        Bitmap editBmp = Bitmap.createBitmap(bmp.getWidth(), bmp.getHeight(), Bitmap.Config.ARGB_8888);

        Canvas canvas = new Canvas(editBmp);
        Paint rectPaint = new Paint();
        rectPaint.setColor(Color.WHITE);
        canvas.drawRect(0, 0, bmp.getWidth(), bmp.getHeight(), rectPaint);
        canvas.drawBitmap(bmp, mtrx, null);

        File file = Utility.createRandomPNGFile(reactContext);
        Utility.writeBMPToPNGFile(editBmp, file, promise);

        final WritableMap map = Utility.buildImageReactMap(file, editBmp);
        promise.resolve(map);
    }

    @ReactMethod
    public void merge(ReadableArray uriStrings, Promise promise) {
        Bitmap firstBmp = Utility.bitmapFromUriString(uriStrings.getString(0), promise, reactContext);
        if (firstBmp == null) {
            return;
        }
        Bitmap editBmp = Bitmap.createBitmap(firstBmp.getWidth(), firstBmp.getHeight(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(editBmp);
        canvas.drawBitmap(firstBmp, new Matrix(), null);

        for (int i = 1; i < uriStrings.size(); i++) {
            Bitmap bmp = Utility.bitmapFromUriString(uriStrings.getString(i), promise, reactContext);
            if (bmp == null) {
                return;
            }
            Rect srcRect = new Rect(0, 0, bmp.getWidth(), bmp.getHeight());
            Rect dstRect = new Rect(0, 0, canvas.getWidth(), canvas.getHeight());
            canvas.drawBitmap(bmp, srcRect, dstRect, null);
        }

        File file = Utility.createRandomPNGFile(reactContext);
        Utility.writeBMPToPNGFile(editBmp, file, promise);

        final WritableMap map = Utility.buildImageReactMap(file, editBmp);
        promise.resolve(map);
    }

    @ReactMethod
    public void createMaskFromShape(ReadableMap options, Promise promise) {
        final ReadableArray points = options.getArray("points");
        final int width = options.getInt("width");
        final int height = options.getInt("height");
        final boolean inverted = options.getBoolean("inverted");

        final Paint bgPaint = new Paint();
        final Paint shapePaint = new Paint();

        if (inverted) {
            bgPaint.setColor(Color.BLACK);
            bgPaint.setAlpha(0);
            shapePaint.setColor(Color.WHITE);
        } else {
            bgPaint.setColor(Color.WHITE);
            shapePaint.setColor(Color.BLACK);
            shapePaint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.CLEAR));
        }

        Bitmap bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bmp);

        final Rect bgRect = new Rect(0, 0, width, height);

        canvas.drawRect(bgRect, bgPaint);

        final Path shapePath = new Path();

        for (int i = 0; i < points.size(); i++) {
            final ReadableMap pointsItem = points.getMap(i);
            final int x = pointsItem.getInt("x");
            final int y = pointsItem.getInt("y");
            if (i == 0) {
                shapePath.moveTo(x, y);
            } else {
                shapePath.lineTo(x, y);
            }
            if (i == points.size() - 1) {
                shapePath.close();
            }
        }

        canvas.drawPath(shapePath, shapePaint);

        File file = Utility.createRandomPNGFile(reactContext);
        Utility.writeBMPToPNGFile(bmp, file, promise);

        final WritableMap map = Utility.buildImageReactMap(file, bmp);
        promise.resolve(map);
    }

    @ReactMethod
    public void mask(String uriString, String maskUriString, ReadableMap options, Promise promise) {

        final boolean trimTransparency = options.getBoolean("trimTransparency");

        Bitmap bmp = Utility.bitmapFromUriString(uriString, promise, reactContext);
        if (bmp == null) {
            return;
        }

        Bitmap maskBmp = Utility.bitmapFromUriString(maskUriString, promise, reactContext);
        if (maskBmp == null) {
            return;
        }

        final HashMap containedRectMap = Utility.calcRectForContainedRect(
            maskBmp.getWidth(), maskBmp.getHeight(),
            bmp.getWidth(), bmp.getHeight()
        );
        int editWidth = (int) containedRectMap.get("width");
        int editHeight = (int) containedRectMap.get("height");
        int editX = (int) containedRectMap.get("x");
        int editY = (int) containedRectMap.get("y");

        Bitmap editBmp = Bitmap.createBitmap(editWidth, editHeight, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(editBmp);

        Paint maskPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        maskPaint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.DST_IN));

        canvas.drawBitmap(bmp, -editX, editY, null);

        Rect maskSrcRect = new Rect(0, 0, maskBmp.getWidth(), maskBmp.getHeight());
        Rect maskDstRect = new Rect(0, 0, canvas.getWidth(), canvas.getHeight());

        canvas.drawBitmap(maskBmp, maskSrcRect, maskDstRect, maskPaint);

        maskPaint.setXfermode(null);

        canvas.drawBitmap(editBmp, 0, 0, new Paint());

        if (trimTransparency) {
            editBmp = Utility.trimTransparency(editBmp);
        }

        File file = Utility.createRandomPNGFile(reactContext);
        Utility.writeBMPToPNGFile(editBmp, file, promise);

        final WritableMap map = Utility.buildImageReactMap(file, editBmp);
        promise.resolve(map);
    }


    @Override
    public String getName() {
        return "RNImageTools";
    }
}
