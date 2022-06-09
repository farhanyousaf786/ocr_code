import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class EditableTexts extends StatefulWidget {
  late final String scanText;

  EditableTexts({Key? key, required this.scanText}) : super(key: key);

  @override
  _EditableTextsState createState() => _EditableTextsState();
}

class _EditableTextsState extends State<EditableTexts> {
  @override
  void initState() {
    loadBannerAd();
    _intAd();
    Future.delayed(const Duration(seconds: 10), () {
      if (_isAdLoaded) _interstitialAd.show();
    });

    super.initState();
  }

  /// below is InterstitialAd ads functionality

  late InterstitialAd _interstitialAd;

  bool _isAdLoaded = false;

  void _intAd() {
    InterstitialAd.load(
        adUnitId: "ca-app-pub-5525086149175557/8996551791",
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: onAdLoaded, onAdFailedToLoad: (error) {}));
  }

  void onAdLoaded(InterstitialAd ad) {
    _interstitialAd = ad;
    _isAdLoaded = true;
  }

  /// below is Banner ads functionality

  late BannerAd myBanner1;

  bool isLoaded1 = false;

  void loadBannerAd() {
    myBanner1 = BannerAd(
        adUnitId: 'ca-app-pub-5525086149175557/4482591718',
        size: AdSize.banner,
        request: request,
        listener: BannerAdListener(onAdLoaded: (ad) {
          setState(() {
            isLoaded1 = true;
          });
        }, onAdFailedToLoad: (ad, error) {
          ad.dispose();
        }));

    myBanner1.load();
  }

  static const AdRequest request = AdRequest();

  /// this is main body of that class which will display when we approach this class

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        child: const Padding(
                          padding: EdgeInsets.only(top: 5, left: 12),
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        onTap: () => Navigator.pop(context),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Scanned Text',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 25),
                        ),
                      ),
                      Text("")
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue)),
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 2,
                        child: TextFormField(
                            maxLines: 20,
                            cursorColor: Colors.black,
                            initialValue: widget.scanText,
                            cursorHeight: 10,
                            style: const TextStyle(
                                fontSize: 15.0,
                                height: 2.0,
                                color: Colors.black),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.only(
                                  left: 8, bottom: 8, top: 5, right: 8),
                            ))),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Colors.blue,
                              size: 20,
                            ),
                            Text(
                              " Back",
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      TextButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              "Copy ",
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            Icon(
                              Icons.copy_rounded,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ],
                        ),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: widget.scanText));
                          ScaffoldMessenger.of(context)
                              .showSnackBar(new SnackBar(
                            content: const Text('Copied'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            margin: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).size.height - 100,
                                right: 20,
                                left: 20),
                          ));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
      ],
    );
  }
}
