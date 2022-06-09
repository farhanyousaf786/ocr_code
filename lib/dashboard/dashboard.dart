import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../editable/editable_text.dart';
import 'package:url_launcher/url_launcher.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({Key? key}) : super(key: key);

  @override
  _DashBoardState createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  /// This is list that will store every text that OCR api will detect
  List<List<String>> textList = [];

  /// this list will store lines from image that OCR api will detect
  List<String> lineList = [];

  /// will check if image is loaded from gallery or not
  bool isImageLoaded = false;

  /// we will store our output from API to text to make if copyable
  String text = "";

  /// file path to change file type for API
  String filePath = "";

  /// This variable is from crop package, this will store our image
  /// temporarily to crop it
  CroppedFile? croppedImage;

  /// this function will always run one time when we access this class.
  @override
  void initState() {
    /// to load banner ad from google api
    loadBannerAd();

    /// To load interstitial ad from Google API
    _intAd();

    /// this is a timer to display ad after 10 sec of loading this class
    Future.delayed(const Duration(seconds: 10), () {
      /// id ad is loaded then display it w/o error
      if (_isAdLoaded) _interstitialAd.show();
    });

    super.initState();
  }

  /// function to pick file from gallery
  pickImage() async {
    var tempStore = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (tempStore != null) {
        filePath = tempStore.path;
      }
      cropImage(filePath);
    });
  }

  /// function to click image direct from device camera
  openCamera() async {
    var tempStore = await ImagePicker().pickImage(source: ImageSource.camera);
    setState(() {
      if (tempStore != null) {
        filePath = tempStore.path;
      }
      cropImage(filePath);
    });
  }

  /// function will allow us to select our options, like
  /// weather we want image from gallery or camera?.
  _showChoiceDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              "Choose option",
              style: TextStyle(color: Colors.blue),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  const Divider(
                    height: 1,
                    color: Colors.blue,
                  ),
                  ListTile(
                    onTap: () {
                      pickImage();
                    },
                    title: const Text("Gallery"),
                    leading: const Icon(
                      Icons.account_box,
                      color: Colors.blue,
                    ),
                  ),
                  const Divider(
                    height: 1,
                    color: Colors.blue,
                  ),
                  ListTile(
                    onTap: () {
                      openCamera();
                    },
                    title: const Text("Camera"),
                    leading: const Icon(
                      Icons.camera,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  /// a function from crop library to crop image.
  void cropImage(filePath) async {
    croppedImage = await ImageCropper().cropImage(
      sourcePath: filePath,
      maxWidth: 2500,
      maxHeight: 2500,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        ),
      ],
    );

    if (croppedImage != null) {
      setState(() {
        isImageLoaded = true;
      });

      Navigator.pop(context);
    }
  }

  /// this is our main function which will read text from image file

  Future readText() async {
    try {
      if (filePath == "") {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Select an image!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 100,
              right: 20,
              left: 20),
        ));
        return;
      }

      final bytes = File(croppedImage!.path).readAsBytesSync();

      String img64 = base64Encode(bytes);

      print("Base64Image:" + img64);

      final Map<String, dynamic> data = Map<String, dynamic>();
      data['requests'] = [
        {
          "features": [
            {"type": "TEXT_DETECTION"}
          ],
          "image": {"content": img64},
        }
      ];
      var bodydata = json.encode(data);

      showLoaderDialog(context);

      final response = await http.post(
          Uri.parse(
              "api"),    // replace api with you api link here

          body: bodydata);

      print(json.decode(response.body));
      Navigator.pop(context);
      if (response.statusCode == 200) {
        print("Success");
        setState(() {
          text = response.body;
        });

        Future.delayed(const Duration(milliseconds: 100), () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EditableTexts(
                        scanText: json.decode(response.body)["responses"][0]
                            ["fullTextAnnotation"]["text"],
                      )));
        });
      } else {
        /// If that response was not OK, throw an error.
        /// throw Exception('Fail ["fullTextAnnotation"]["text"]d to load ConversationRepo');
        showAlertDialog(context, "Ooh! there is an error, please try again!");
      }

      setState(() {
        text = text + textList.toString();
        ;
      });
    } on Exception catch (exception) {
      Navigator.pop(context);
      showAlertDialog(context,
          "Ooh! there is an error, please try again!" + exception.toString());
    }
  }

  /// This function will lead us to browser to run a url.
  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  /// below is  Banner ads functionality
  late BannerAd myBanner1;
  bool isLoaded1 = false;

  void loadBannerAd() {
    myBanner1 = BannerAd(
        adUnitId: 'ca-app-pub-5525086149175557/3750954818',
        size: AdSize.banner,
        request: request,
        listener: BannerAdListener(onAdLoaded: (ad) {
          setState(() {
            isLoaded1 = true;
          });
        }, onAdFailedToLoad: (ad, error) {
          ad.dispose();

          print('ad failed to load ${error.message}');
        }));

    myBanner1.load();
  }

  static const AdRequest request = AdRequest();

  /// below is InterstitialAd ads functionality

  late InterstitialAd _interstitialAd;

  bool _isAdLoaded = false;

  void _intAd() {
    InterstitialAd.load(
        adUnitId: "ca-app-pub-5525086149175557/7307056443",
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: onAdLoaded, onAdFailedToLoad: (error) {}));
  }

  void onAdLoaded(InterstitialAd ad) {
    _interstitialAd = ad;
    _isAdLoaded = true;
  }

  /// This is a simple pop up widget, will display after pressing copy button
  showAlertDialog(BuildContext context, String text) {

    Widget continueButton = TextButton(
      child: const Text("Copy to Clipboard"),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Text Copied to clipboard!"),
        ));
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Captured Text"),
      content: SingleChildScrollView(child: SelectableText(text)),
      actions: [
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  /// loading widget
  showLoaderDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          Container(
              margin: const EdgeInsets.only(left: 7),
              child: const Text("Loading...")),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  /// this is main body of that class which will display when we approach this class
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
          body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.blue.shade800,
            Colors.blue.shade300,
          ],
        )),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        child: const Icon(
                          Icons.list,
                          color: Colors.white,
                        ),
                        onTap: () {
                          showModalBottomSheet(
                              useRootNavigator: true,
                              isScrollControlled: true,
                              barrierColor: Colors.red.withOpacity(0.2),
                              elevation: 0,
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              context: context,
                              builder: (context) {
                                return Container(
                                  height:
                                      MediaQuery.of(context).size.height / 2.7,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.linear_scale_sharp),
                                            ],
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            "How to use",
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontFamily: "cutes",
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            "Click on 'Pick an image' button > select gallery or camera > get the image > click on scan.",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontFamily: "cutes",
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              });
                        },
                      ),
                      const Center(
                        child: Text(
                          'Image To Text',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 25),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _launchURL(
                            "https://doubleslit.tech/#/image-to-text"),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),

                isImageLoaded
                    ? Center(
                        child: Container(
                          height: 150.0,
                          width: 150.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                                image: FileImage(File(croppedImage!.path)),
                                fit: BoxFit.cover),
                          ),
                        ),
                      )
                    : Container(),
                SizedBox(height: 20.0),
                isImageLoaded
                    ? Material(
                        borderRadius: BorderRadius.circular(10),
                        elevation: 10,
                        child: GestureDetector(
                          onTap: readText,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                            height: 50,
                            width: MediaQuery.of(context).size.width / 2,
                            child: Center(
                                child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Scan This Image ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue),
                                ),
                                Icon(
                                  Icons.amp_stories_outlined,
                                  color: Colors.blue,
                                )
                              ],
                            )),
                          ),
                        ),
                      )
                    : const SizedBox(
                        height: 0,
                        width: 0,
                      ),
                SizedBox(height: 30.0),

                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(10),
                  child: GestureDetector(
                      onTap: () {
                        _showChoiceDialog(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        height: isImageLoaded ? 50 : 100,
                        width: MediaQuery.of(context).size.width / 1.8,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isImageLoaded
                                    ? "Pick Another Image   "
                                    : 'Pick an Image   ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              ),
                              Icon(
                                isImageLoaded
                                    ? Icons.refresh_sharp
                                    : Icons.image,
                                color: Colors.red,
                              )
                            ],
                          ),
                        ),
                      )),
                ),

                const SizedBox(
                  height: 20,
                ),
                isImageLoaded
                    ? const SizedBox(
                        height: 0,
                        width: 0,
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Text(
                              'Supported Languages',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 20),
                            ),
                            SingleChildScrollView(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: const Padding(
                                  padding: EdgeInsets.only(
                                      top: 20, left: 10, right: 10),
                                  child: Text(
                                    'English, Chines, Spanish, Japanese, Urdu, Hindi',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                //Text(text),
              ],
            ),
          ),
        ),
      )),
      Positioned(
        bottom: 0.0,
        right: 0.0,
        left: 0.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            child: AdWidget(
              ad: myBanner1,
            ),
            width: myBanner1.size.width.toDouble(),
            height: myBanner1.size.height.toDouble(),
          ),
        ),
      )
    ]);
  }
}
