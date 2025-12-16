# Task Manager Pro - Native Device Resources

Flutter app demonstrating advanced native device integration including camera, sensors, and GPS functionality.

## 🎯 Features Implemented

### 📷 Camera Integration
- **Photo Capture**: Take photos using device camera
- **Photo Storage**: Save photos to app documents directory
- **Photo Display**: View captured photos in task cards
- **Photo Management**: Delete photos when tasks are removed

### 📱 Sensor Integration  
- **Shake Detection**: Complete tasks by shaking the device
- **Accelerometer Monitoring**: Real-time motion detection
- **Haptic Feedback**: Vibration confirmation on shake detection
- **Smart Cooldown**: Prevents false triggers with timing controls

### 📍 GPS & Location Services
- **Current Location**: Get precise GPS coordinates
- **Geocoding**: Convert coordinates to readable addresses
- **Address Search**: Find locations by typing addresses
- **Location-based Filtering**: Show nearby tasks within 1km radius
- **Interactive Location Picker**: Modal UI for location selection

### 🗄️ Enhanced Database
- **Schema Migration**: Automatic database updates from v1 to v4
- **New Fields**: photoPath, GPS coordinates, completion tracking
- **Location Queries**: Find tasks by proximity
- **Completion Analytics**: Track how tasks were completed (manual vs shake)

## 🛠️ Technical Implementation

### Architecture
```
lib/
├── models/
│   └── task.dart           # Enhanced Task model with native features
├── services/
│   ├── database_service.dart   # v4 with migration support
│   ├── camera_service.dart     # Camera management
│   ├── sensor_service.dart     # Accelerometer & shake detection
│   └── location_service.dart   # GPS & geocoding
├── screens/
│   ├── task_list_screen.dart   # Main screen with shake detection
│   ├── task_form_screen.dart   # Enhanced form with camera/GPS
│   └── camera_screen.dart      # Custom camera interface
└── widgets/
    ├── task_card.dart          # Visual badges for features
    └── location_picker.dart    # Location selection UI
```

### Key Technologies
- **Camera**: `camera: ^0.10.5+9`
- **Sensors**: `sensors_plus: ^4.0.2` 
- **GPS**: `geolocator: ^10.1.0`
- **Geocoding**: `geocoding: ^2.1.1`
- **Permissions**: `permission_handler: ^11.3.1`
- **Haptics**: `vibration: ^1.8.4`

## 🧪 Testing Instructions

### Setup
1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Run on physical device: `flutter run`

> **Important**: Test on a **physical device** as camera, GPS, and accelerometer don't work properly on simulators.

### Testing Camera Features
1. **Create New Task**
   - Tap the "+" button
   - Tap "Take Photo" in the Camera section
   - Allow camera permissions when prompted
   - Take a photo using the circular capture button
   - Verify photo appears in the form

2. **View Photos**
   - Tap on a photo in the task card to view full-screen
   - Use pinch-to-zoom in the photo viewer

### Testing Shake Detection  
1. **Enable Shake Detection**
   - Create some pending tasks
   - Go to the main task list
   - Shake your phone moderately (not too gentle, not too violent)

2. **Complete Tasks via Shake**
   - When shake is detected, a dialog appears
   - Select a task to complete
   - Task gets marked as completed with "Shake" badge

### Testing GPS Features
1. **Add Current Location**
   - Create/edit a task
   - Tap "Add Location" 
   - Tap "Use Current Location"
   - Allow location permissions
   - Verify GPS coordinates and address appear

2. **Search Addresses**
   - In location picker, type an address (e.g., "Av. Afonso Pena, 1000, BH")
   - Tap search or press Enter
   - Verify coordinates are found

3. **Filter Nearby Tasks**
   - Create tasks with different locations
   - In main screen, tap filter menu
   - Select "Nearby"
   - Only tasks within 1km should appear

### Testing Visual Indicators
1. **Priority Badges**: Different colors for Low/Medium/High/Urgent
2. **Feature Badges**: 
   - Blue "Photo" badge for tasks with photos
   - Purple "Location" badge for tasks with GPS
   - Green "Shake" badge for shake-completed tasks

## 📊 Testing Scenarios

### Scenario 1: Complete Task Workflow
```
1. Create task "Buy groceries" 
2. Add photo of shopping list
3. Add supermarket location
4. Save task
5. At supermarket: shake phone to complete
6. Verify "Shake" badge appears
```

### Scenario 2: Location-based Tasks
```
1. Create 3 tasks at different locations
2. Go to location A
3. Filter by "Nearby" 
4. Only tasks near location A should show
```

### Scenario 3: Photo Management
```
1. Create task with photo
2. Edit task and remove photo
3. Add different photo
4. Delete entire task
5. Verify all photos are cleaned up
```

## 🎬 Video Demo Script

**"Task Manager Pro - Native Features Demo"** (2-3 minutes)

### Scene 1: App Overview (30s)
- Show main screen with task statistics
- Demonstrate task filtering (All, Pending, Completed, Nearby)
- Show different priority levels and visual badges

### Scene 2: Camera Integration (45s)
- Create new task
- Tap "Take Photo" 
- Show camera interface
- Capture photo of a note/document
- Show photo preview in task card
- Tap to view full-screen photo

### Scene 3: Shake Detection (30s)
- Create 2-3 pending tasks
- Hold phone and shake moderately
- Show shake detection dialog
- Select task to complete
- Show "Shake" badge on completed task

### Scene 4: GPS & Location (45s)
- Create new task
- Tap "Add Location"
- Demonstrate "Use Current Location" 
- Show address resolution
- Try manual address search
- Show location badge on task
- Demonstrate "Nearby" filter

### Scene 5: Advanced Features (30s)
- Show statistics dashboard
- Demonstrate task editing with all features
- Show database persistence by closing/reopening app
- Quick overview of all visual badges

## 🐛 Common Issues & Solutions

### Camera Issues
- **Problem**: Camera not working
- **Solution**: Test on physical device, check permissions in Settings

### Shake Detection Issues  
- **Problem**: Too sensitive/not sensitive enough
- **Solution**: Adjust `_shakeThreshold` in `sensor_service.dart` (default: 15.0)

### GPS Issues
- **Problem**: Location not found
- **Solution**: Ensure location services enabled, test outdoors

### Address Search Issues
- **Problem**: Address not found
- **Solution**: Use complete addresses (e.g., "Street, Number, City")

## 📱 Supported Platforms
- **Android**: Full feature support
- **iOS**: Full feature support (if properly configured)
- **Web/Desktop**: Limited support (no camera/GPS/sensors)

## 📈 Performance Notes
- Photos are compressed and stored locally
- Database migrations are automatic
- Shake detection has built-in cooldown to prevent spam
- GPS requests use high accuracy when needed

## 🎓 Learning Outcomes Achieved
✅ Camera capture and management  
✅ Accelerometer-based gesture detection  
✅ GPS location services  
✅ Geocoding and reverse geocoding  
✅ Complex permission handling  
✅ Database schema migrations  
✅ File system operations  
✅ Real-time sensor monitoring  
✅ Cross-platform native integration