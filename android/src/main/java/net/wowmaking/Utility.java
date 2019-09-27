package net.wowmaking;

import android.content.ContentResolver;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Matrix;
import android.support.media.ExifInterface;
import android.net.Uri;
import android.os.Build;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.views.imagehelper.ResourceDrawableIdHelper;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.util.HashMap;
import java.util.UUID;
import java.io.OutputStream;
import java.io.InputStream;

final class Utility {

    private static final String SCHEME_FILE = "file";
    private static final String SCHEME_CONTENT = "content";
    public static final int EOF = -1;
    private static final int DEFAULT_BUFFER_SIZE = 1024 * 4;

    static WritableMap buildImageReactMap(File file, Bitmap bmp) {
        WritableMap map = Arguments.createMap();
        map.putString("uri", "file://" + file.toString());
        map.putDouble("width", bmp.getWidth());
        map.putDouble("height", bmp.getHeight());
        return map;
    }

    public static long copyLarge(final InputStream input, final OutputStream output, final byte[] buffer)
            throws IOException {
        long count = 0;
        int n;
        while (EOF != (n = input.read(buffer))) {
            output.write(buffer, 0, n);
            count += n;
        }
        return count;
    }


    public static int copy(final InputStream input, final OutputStream output) throws IOException {
        final long count = copyLarge(input, output, new byte[DEFAULT_BUFFER_SIZE]);
        if (count > Integer.MAX_VALUE) {
            return -1;
        }
        return (int) count;
    }

    static Bitmap bitmapFromUriString(String uriString, final Promise promise, Context context) {
        try {
            Uri uri = Uri.parse(uriString);
            String scheme = Uri.parse(uriString).getScheme();
            if (scheme != null && (scheme.equals(SCHEME_CONTENT) || scheme.equals(SCHEME_FILE))) {
                ContentResolver resolver = context.getContentResolver();
                try {
                    InputStream streamOrient = resolver.openInputStream(uri);
                    final int orientation = Utility.getOrientation(streamOrient);

                    InputStream streamBmp = resolver.openInputStream(uri);
                    Bitmap bmp = BitmapFactory.decodeStream(streamBmp);

                    return Utility.fixOrientation(bmp, orientation);

                } catch (FileNotFoundException e) {
                    handleError(e, promise);
                }
            } else {
                int id = ResourceDrawableIdHelper.getInstance().getResourceDrawableId(context, uriString);
                if (id > 0) {
                    return BitmapFactory.decodeResource(context.getResources(), id);
                }
            }

            URL url = new URL(uriString);
            try {
                URLConnection connection = url.openConnection();
                InputStream inputStream = connection.getInputStream();

                File tempFile = new File(context.getFilesDir(), UUID.randomUUID().toString() + ".tmp");

                final FileOutputStream outputStream = new FileOutputStream(tempFile);

                Utility.copy(inputStream, outputStream);

                final int orientation = Utility.getOrientation(tempFile.getAbsolutePath());

                Bitmap bmp = BitmapFactory.decodeFile(tempFile.getAbsolutePath());

                tempFile.delete();

                return Utility.fixOrientation(bmp, orientation);
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

    static File createRandomPNGFile(ReactContext context) {
        String filename = UUID.randomUUID().toString() + ".png";
        return new File(context.getFilesDir(), filename);
    }


    static void writeBMPToPNGFile(Bitmap bmp, File file, Promise promise) {
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

    static int getOrientation(String filename) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                return new ExifInterface(filename).getAttributeInt(
                        ExifInterface.TAG_ORIENTATION,
                        ExifInterface.ORIENTATION_UNDEFINED
                );
            } catch (IOException e) {
                e.printStackTrace(System.err);
                return -1;
            }
        } else {
            return -1;
        }
    }



    static int getOrientation(InputStream stream) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                return new ExifInterface(stream).getAttributeInt(
                        ExifInterface.TAG_ORIENTATION,
                        ExifInterface.ORIENTATION_UNDEFINED
                );
            } catch (IOException e) {
                e.printStackTrace(System.err);
                return -1;
            }
        } else {
            return -1;
        }
    }

    static Bitmap fixOrientation(Bitmap bitmap, int orientation) {
        Matrix matrix = new Matrix();
        switch (orientation) {
            case ExifInterface.ORIENTATION_NORMAL:
                return bitmap;
            case ExifInterface.ORIENTATION_FLIP_HORIZONTAL:
                matrix.setScale(-1, 1);
                break;
            case ExifInterface.ORIENTATION_ROTATE_180:
                matrix.setRotate(180);
                break;
            case ExifInterface.ORIENTATION_FLIP_VERTICAL:
                matrix.setRotate(180);
                matrix.postScale(-1, 1);
                break;
            case ExifInterface.ORIENTATION_TRANSPOSE:
                matrix.setRotate(90);
                matrix.postScale(-1, 1);
                break;
            case ExifInterface.ORIENTATION_ROTATE_90:
                matrix.setRotate(90);
                break;
            case ExifInterface.ORIENTATION_TRANSVERSE:
                matrix.setRotate(-90);
                matrix.postScale(-1, 1);
                break;
            case ExifInterface.ORIENTATION_ROTATE_270:
                matrix.setRotate(-90);
                break;
            default:
                return bitmap;
        }
        try {
            Bitmap bmRotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
            bitmap.recycle();
            return bmRotated;
        }
        catch (OutOfMemoryError e) {
            e.printStackTrace();
            return null;
        }
    }
}
