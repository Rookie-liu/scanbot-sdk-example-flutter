import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scanbot_sdk/barcode_scanning_data.dart';
import 'package:scanbot_sdk/common_data.dart';
import 'package:scanbot_sdk/document_scan_data.dart';
import 'package:scanbot_sdk/ehic_scanning_data.dart';
import 'package:scanbot_sdk/mrz_scanning_data.dart';
import 'package:scanbot_sdk/scanbot_sdk.dart';
import 'package:scanbot_sdk/scanbot_sdk_models.dart';
import 'package:scanbot_sdk/scanbot_sdk_ui.dart';
import 'package:scanbot_sdk_example_flutter/ui/barcode_preview.dart';
import 'package:scanbot_sdk_example_flutter/ui/preview_document_widget.dart';
import 'package:scanbot_sdk_example_flutter/ui/progress_dialog.dart';

import 'pages_repository.dart';
import 'ui/menu_items.dart';
import 'ui/utils.dart';

void main() => runApp(MyApp());

// TODO add the Scanbot SDK license key here.
// Please note: The Scanbot SDK will run without a license key for one minute per session!
// After the trial period is over all Scanbot SDK functions as well as the UI components will stop working
// or may be terminated. You can get an unrestricted "no-strings-attached" 30 day trial license key for free.
// Please submit the trial license form (https://scanbot.io/en/sdk/demo/trial) on our website by using
// the app identifier "io.scanbot.example.sdk.flutter" of this example app or of your app.
const SCANBOT_SDK_LICENSE_KEY = "";

initScanbotSdk() async {
  // Consider adjusting this optional storageBaseDirectory - see the comments below.
  var customStorageBaseDirectory = await getDemoStorageBaseDirectory();

  var config = ScanbotSdkConfig(
      loggingEnabled: true, // Consider switching logging OFF in production builds for security and performance reasons.
      licenseKey: SCANBOT_SDK_LICENSE_KEY,
      imageFormat: ImageFormat.JPG,
      imageQuality: 80,
      storageBaseDirectory: customStorageBaseDirectory,
      documentDetectorMode: DocumentDetectorMode.ML_BASED);

  try {
    await ScanbotSdk.initScanbotSdk(config);
    await PageRepository().loadPages();
  } catch (e) {
    print(e);
  }
}

Future<String> getDemoStorageBaseDirectory() async {
  // !! Please note !!
  // It is strongly recommended to use the default (secure) storage location of the Scanbot SDK.
  // However, for demo purposes we overwrite the "storageBaseDirectory" of the Scanbot SDK by a custom storage directory.
  //
  // On Android we use the "ExternalStorageDirectory" which is a public(!) folder.
  // All image files and export files (PDF, TIFF, etc) created by the Scanbot SDK in this demo app will be stored
  // in this public storage directory and will be accessible for every(!) app having external storage permissions!
  // Again, this is only for demo purposes, which allows us to easily fetch and check the generated files
  // via Android "adb" CLI tools, Android File Transfer app, Android Studio, etc.
  //
  // On iOS we use the "ApplicationDocumentsDirectory" which is accessible via iTunes file sharing.
  //
  // For more details about the storage system of the Scanbot SDK Flutter Plugin please see our docs:
  // - https://scanbotsdk.github.io/documentation/flutter/
  //
  // For more details about the file system on Android and iOS we also recommend to check out:
  // - https://developer.android.com/guide/topics/data/data-storage
  // - https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html

  Directory storageDirectory;
  if (Platform.isAndroid) {
    storageDirectory = await getExternalStorageDirectory();
  } else if (Platform.isIOS) {
    storageDirectory = await getApplicationDocumentsDirectory();
  } else {
    throw ("Unsupported platform");
  }

  return "${storageDirectory.path}/my-custom-storage";
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() {
    initScanbotSdk();
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainPageWidget());
  }
}

class MainPageWidget extends StatefulWidget {
  @override
  _MainPageWidgetState createState() => _MainPageWidgetState();
}

class _MainPageWidgetState extends State<MainPageWidget> {
  PageRepository _pageRepository = PageRepository();

  @override
  void initState() {
    super.initState();
    // add some custom init code here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Scanbot SDK Example Flutter',
            style: TextStyle(inherit: true, color: Colors.black)),
      ),
      body: ListView(
        children: <Widget>[
          TitleItemWidget("Document Scanner"),
          MenuItemWidget(
            "Scan Document",
            onTap: () {
              startDocumentScanning();
            },
          ),
          MenuItemWidget(
            "Import Image",
            onTap: () {
              importImage();
            },
          ),
          MenuItemWidget(
            "View Image Results",
            endIcon: Icons.keyboard_arrow_right,
            onTap: () {
              gotoImagesView();
            },
          ),
          TitleItemWidget("Data Detectors"),
          MenuItemWidget(
            "Scan Barcode (all formats: 1D + 2D)",
            onTap: () {
              startBarcodeScanner();
            },
          ),
          MenuItemWidget(
            "Scan QR code (QR format only)",
            onTap: () {
              startQRScanner();
            },
          ),
          MenuItemWidget(
            "Scan Multiple Barcodes ",
            onTap: () {
              startBatchBarcodeScanner();
            },
          ),
          MenuItemWidget(
            "Detect Barcode image",
            onTap: () {
              detectBarcodeOnImage();
            },
          ),
          MenuItemWidget(
            "Scan MRZ (Machine Readable Zone)",
            onTap: () {
              startMRZScanner();
            },
          ),
          MenuItemWidget(
            "Scan EHIC (European Health Insurance Card)",
            onTap: () {
              startEhicScanner();
            },
          ),
          TitleItemWidget("Test other SDK API methods"),
          MenuItemWidget(
            "getLicenseStatus()",
            startIcon: Icons.phonelink_lock,
            onTap: () {
              getLicenseStatus();
            },
          ),
          MenuItemWidget(
            "getOcrConfigs()",
            startIcon: Icons.settings,
            onTap: () {
              getOcrConfigs();
            },
          ),
          MenuItemWidget(
            "cleanUpStorage()",
            startIcon: Icons.plumbing,
            onTap: () {
              cleanUpStorage();
            },
          ),
        ],
      ),
    );
  }

  getOcrConfigs() async {
    try {
      var result = await ScanbotSdk.getOcrConfigs();
      showAlertDialog(context, jsonEncode(result), title: "OCR Configs");
    } catch (e) {
      print(e);
      showAlertDialog(context, "Error getting license status");
    }
  }

  getLicenseStatus() async {
    try {
      var result = await ScanbotSdk.getLicenseStatus();
      showAlertDialog(context, jsonEncode(result), title: "License Status");
    } catch (e) {
      print(e);
      showAlertDialog(context, "Error getting OCR configs");
    }
  }

  cleanUpStorage() async {
    await ScanbotSdk.cleanupStorage();
  }

  importImage() async {
    try {
      var image = await ImagePicker.pickImage(source: ImageSource.gallery);
      await createPage(image.uri);
      gotoImagesView();
    } catch (e) {
      print(e);
    }
  }

  createPage(Uri uri) async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    var dialog = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false);
    dialog.style(message: "Processing");
    dialog.show();
    try {
      var page = await ScanbotSdk.createPage(uri, false);
      page = await ScanbotSdk.detectDocument(page);
      await _pageRepository.addPage(page);
    } catch (e) {
      print(e);
    } finally {
      dialog.hide();
    }
  }

  startDocumentScanning() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    DocumentScanningResult result;
    try {
      var config = DocumentScannerConfiguration(
        bottomBarBackgroundColor: Colors.blue,
        ignoreBadAspectRatio: true,
        multiPageEnabled: true,
        //maxNumberOfPages: 3,
        //flashEnabled: true,
        //autoSnappingSensitivity: 0.7,
        cameraPreviewMode: CameraPreviewMode.FIT_IN,
        orientationLockMode: CameraOrientationMode.PORTRAIT,
        //documentImageSizeLimit: Size(2000, 3000),
        cancelButtonTitle: "Cancel",
        pageCounterButtonTitle: "%d Page(s)",
        textHintOK: "Perfect, don't move...",
        //textHintNothingDetected: "Nothing",
        // ...
      );
      result = await ScanbotSdkUi.startDocumentScanner(config);
    } catch (e) {
      print(e);
    }

    if (isOperationSuccessful(result)) {
      await _pageRepository.addPages(result.pages);
      gotoImagesView();
    }
  }

  startBarcodeScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    try {
      var config = BarcodeScannerConfiguration(
        topBarBackgroundColor: Colors.blue,
        finderTextHint:
            "Please align any supported barcode in the frame to scan it.",
        // ...
      );
      var result = await ScanbotSdkUi.startBarcodeScanner(config);
      _showBarcodeScanningResult(result);
    } catch (e) {
      print(e);
    }
  }

  startBatchBarcodeScanner() async {
    try {
      //var config = BarcodeScannerConfiguration(); // testing default configs
      var config = BatchBarcodeScannerConfiguration(
          barcodeFormatter: (item) async {
            Random random = new Random();
            int randomNumber = random.nextInt(4) + 2;
            await new Future.delayed(Duration(seconds: randomNumber));
            return BarcodeFormattedData(
                title: item.barcodeFormat.toString(),
                subtitle: item.text + "custom string");
          },
          topBarBackgroundColor: Colors.blueAccent,
          topBarButtonsColor: Colors.white70,
          cameraOverlayColor: Colors.black26,
          finderLineColor: Colors.red,
          finderTextHintColor: Colors.cyanAccent,
          cancelButtonTitle: "Cancel",
          enableCameraButtonTitle: "camera enable",
          enableCameraExplanationText: "explanation text",
          finderTextHint:
              "Please align any supported barcode in the frame to scan it.",
          // clearButtonTitle: "CCCClear",
          // submitButtonTitle: "Submitt",
          barcodesCountText: "%d codes",
          fetchingStateText: "might be not needed",
          noBarcodesTitle: "nothing to see here",
          barcodesCountTextColor: Colors.purple,
          finderAspectRatio: FinderAspectRatio(width: 3, height: 2),
          topBarButtonsInactiveColor: Colors.orange,
          detailsActionColor: Colors.yellow,
          detailsBackgroundColor: Colors.amber,
          detailsPrimaryColor: Colors.yellowAccent,
          finderLineWidth: 7,
          successBeepEnabled: true,
          // flashEnabled: true,
          orientationLockMode: CameraOrientationMode.PORTRAIT,
          barcodeFormats: PredefinedBarcodes.allBarcodeTypes(),
          cancelButtonHidden: false);

      var result = await ScanbotSdkUi.startBatchBarcodeScanner(config);
      if (result.operationResult == OperationResult.SUCCESS) {
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => BarcodesResultPreviewWidget(result)),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  detectBarcodeOnImage() async {
    try {
      var image = await ImagePicker.pickImage(source: ImageSource.gallery);

      ///before processing image sdk need storage read permission

      Map<Permission, PermissionStatus> permissions =
          await [Permission.storage, Permission.photos].request();
      if (permissions[Permission.storage] ==
              PermissionStatus.granted || //android
          permissions[Permission.photos] == PermissionStatus.granted) {
        //ios
        var result = await ScanbotSdk.detectBarcodeFromImageFile(
            image.uri, PredefinedBarcodes.allBarcodeTypes(), true);
        if (result.operationResult == OperationResult.SUCCESS) {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => BarcodesResultPreviewWidget(result)),
          );
        }
      }
    } catch (e) {
      print(e);
    }
  }

  startQRScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    try {
      var config = BarcodeScannerConfiguration(
        barcodeFormats: [BarcodeFormat.QR_CODE],
        finderTextHint: "Please align a QR code in the frame to scan it.",
        // ...
      );
      var result = await ScanbotSdkUi.startBarcodeScanner(config);
      _showBarcodeScanningResult(result);
    } catch (e) {
      print(e);
    }
  }

  _showBarcodeScanningResult(final BarcodeScanningResult result) {
    if (result.operationResult == OperationResult.SUCCESS) {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => BarcodesResultPreviewWidget(result)),
      );
    }
  }

  startEhicScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    HealthInsuranceCardRecognitionResult result;
    try {
      var config = HealthInsuranceScannerConfiguration(
        topBarBackgroundColor: Colors.blue,
        topBarButtonsColor: Colors.white70,
        // ...
      );
      result = await ScanbotSdkUi.startEhicScanner(config);
    } catch (e) {
      print(e);
    }

    if (isOperationSuccessful(result) && result?.fields != null) {
      var concatenate = StringBuffer();
      result.fields
          .map((field) =>
              "${field.type.toString().replaceAll("HealthInsuranceCardFieldType.", "")}:${field.value}\n")
          .forEach((s) {
        concatenate.write(s);
      });
      showAlertDialog(context, concatenate.toString());
    }
  }

  startMRZScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    MrzScanningResult result;
    try {
      var config = MrzScannerConfiguration(
        topBarBackgroundColor: Colors.blue,
        // ...
      );
      result = await ScanbotSdkUi.startMrzScanner(config);
    } catch (e) {
      print(e);
    }

    if (isOperationSuccessful(result)) {
      var concatenate = StringBuffer();
      result.fields
          .map((field) =>
              "${field.name.toString().replaceAll("MRZFieldName.", "")}:${field.value}\n")
          .forEach((s) {
        concatenate.write(s);
      });
      showAlertDialog(context, concatenate.toString());
    }
  }

  gotoImagesView() async {
    imageCache.clear();
    return await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => DocumentPreview()),
    );
  }
}
