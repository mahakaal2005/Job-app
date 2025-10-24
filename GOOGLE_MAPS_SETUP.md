# Google Maps Setup Instructions

## 1. Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
4. Create credentials (API Key)
5. Restrict the API key to your app (optional but recommended)

## 2. Configure API Key

1. Open `.env` file in the project root
2. Replace `your_google_maps_api_key_here` with your actual API key:
   ```
   GOOGLE_MAPS_API_KEY=AIzaSyBvOkBvyTwepBYZ6Y0mOgOzOueXiLCXXXX
   ```

## 3. Platform-specific Configuration

### Android
1. Open `android/app/src/main/AndroidManifest.xml`
2. Add the following inside `<application>` tag:
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY"
              android:value="${GOOGLE_MAPS_API_KEY}"/>
   ```

### iOS
1. Open `ios/Runner/AppDelegate.swift`
2. Add the following import at the top:
   ```swift
   import GoogleMaps
   ```
3. Add the following in the `application` method:
   ```swift
   GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
   ```

## 4. Test the Implementation

1. Run `flutter pub get` to install dependencies
2. Run the app and navigate to any job detail page
3. The map should show the job location with a marker
4. Tap the map or "View" button to open in external maps app

## 5. Features Implemented

- **Automatic Geocoding**: Converts job location text to coordinates
- **Interactive Map**: Shows job location with marker
- **Fallback Locations**: Common cities work even without API
- **External Maps**: Tap to open in Google Maps/Apple Maps
- **Error Handling**: Graceful fallback when location not found
- **Caching**: Avoids repeated API calls for same locations

## 6. Cost Optimization

- Results are cached to minimize API calls
- Fallback locations for common cities
- Only geocodes when map is actually viewed
- Uses efficient geocoding API (not real-time)

The implementation is production-ready and handles all edge cases gracefully!