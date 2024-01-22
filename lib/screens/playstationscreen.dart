import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:azuracastadmin/cubits/filteredlist/filteredlist_cubit.dart';
import 'package:azuracastadmin/cubits/radioID/radio_id_cubit.dart';
import 'package:azuracastadmin/cubits/requestsonglist/requestsonglist_cubit.dart';
import 'package:azuracastadmin/cubits/searchstring/searchstring_cubit.dart';
import 'package:azuracastadmin/cubits/url/url_cubit.dart';
import 'package:azuracastadmin/functions/functions.dart';
import 'package:azuracastadmin/models/nowplaying.dart';
import 'package:azuracastadmin/models/requestsongdata.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transparent_image/transparent_image.dart';

class PlayStationScreen extends StatefulWidget {
  final String url;
  final int stationID;
  final String playURL;
  const PlayStationScreen(
      {required this.stationID,
      required this.url,
      super.key,
      required this.playURL});

  @override
  State<PlayStationScreen> createState() => _PlayStationScreenState();
}

class _PlayStationScreenState extends State<PlayStationScreen> {
  TextEditingController textEditingController = TextEditingController();
  AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();
  double volume = 1;
  late Future<NowPlaying> nowPlaying;
  late Timer timer;
  late Future<List<RequestSongData>> reqData;
  @override
  void initState() {
    super.initState();
    _assetsAudioPlayer.open(Audio.liveStream(widget.playURL),
        autoStart: true,
        playInBackground: PlayInBackground.disabledPause,
        volume: 1,
        showNotification: true);
    nowPlaying = fetchNowPlaying(widget.url, 'nowplaying', widget.stationID);
    timer = Timer.periodic(Duration(seconds: 3), (timer) {
      setState(() {
        nowPlaying =
            fetchNowPlaying(widget.url, 'nowplaying', widget.stationID);
      });
    });
    reqData = fetchSongRequestList(context.read<UrlCubit>().state.url,
        context.read<RadioIdCubit>().state.id);
    reqData.then(
        (value) => context.read<RequestsonglistCubit>().emitNewList(value));
    Timer(Duration(seconds: 1),() {
              context.read<SearchstringCubit>().emitNewSearch('test');
    context.read<SearchstringCubit>().emitNewSearch('');
    },);
  }

  @override
  void dispose() {
    timer.cancel();
    _assetsAudioPlayer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext screenContext) {
    return SafeArea(
      child: Scaffold(
        body: Stack(children: [
          Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Image.asset('assets/images/azu.png', fit: BoxFit.fill))
              .blurred(blur: 10, blurColor: Colors.black),
          Center(
            child: Container(
                margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RadioTitle(),
                    SizedBox(
                      height: 15,
                    ),
                    ImageAndTitle(),
                    SizedBox(
                      height: 10,
                    ),
                    PlayButtonAndVolume(),
                    SizedBox(
                      height: 0,
                    ),
                    SongHistoryAndRequestSongButtons(screenContext),
                  ],
                )),
          ),
        ]),
      ),
    );
  }

  Widget RadioTitle() {
    return Container(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'radio unicorn',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          FutureBuilder(
              future: nowPlaying,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        color: Colors.green,
                        size: 10,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'listening now: ${snapshot.data!.listeners!.current}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              }),
        ],
      ),
    );
  }

  Widget ImageAndTitle() {
    double screenWidth = MediaQuery.of(context).size.width;
    return FutureBuilder<NowPlaying>(
        future: nowPlaying,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: FadeInImage.memoryNetwork(
                    height: 50,
                    placeholder: kTransparentImage,
                    image: '${snapshot.data!.nowPlaying!.song!.art}',
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: screenWidth * 5 / 9,
                      child: Text(
                        '${snapshot.data!.nowPlaying!.song!.title}',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.fade,
                        maxLines: 2,
                        softWrap: false,
                      ),
                    ),
                    Container(
                      width: screenWidth * 5 / 9,
                      child: Text(
                        '${snapshot.data!.nowPlaying!.song!.artist}',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                        overflow: TextOverflow.clip,
                        maxLines: 2,
                        softWrap: false,
                      ),
                    ),
                  ],
                )
              ],
            );
          } else {
            return Container();
          }
        });
  }

  Widget PlayButtonAndVolume() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
            onPressed: () {
              _assetsAudioPlayer.playOrPause();
            },
            icon: PlayerBuilder.isPlaying(
                player: _assetsAudioPlayer,
                builder: (context, isPlaying) => isPlaying
                    ? Icon(
                        Icons.pause_circle_outline,
                        size: 40,
                        color: Colors.blue,
                      )
                    : Icon(
                        Icons.play_circle_outline,
                        size: 40,
                        color: Colors.blue,
                      ))),
        Row(children: [
          Icon(
            Icons.volume_mute,
            color: Colors.grey,
            size: 20,
          ),
          PlayerBuilder.volume(
            player: _assetsAudioPlayer,
            builder: (context, volume) => Slider(
              activeColor: Colors.grey,
              value: volume,
              onChanged: (value) {
                _assetsAudioPlayer.setVolume(value);
              },
            ),
          )
        ]),
        Icon(
          Icons.volume_up,
          color: Colors.grey,
          size: 20,
        ),
      ],
    );
  }

  Widget SongHistoryAndRequestSongButtons(BuildContext screenContext) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                  backgroundColor: Color.fromARGB(255, 42, 42, 42),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Song History',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  content: FutureBuilder<NowPlaying>(
                      future: nowPlaying,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Container(
                            width: screenWidth * 7 / 9,
                            height: screenHeight * 5 / 9,
                            child: ListView.builder(
                              itemCount: snapshot.data!.songHistory!.length,
                              itemBuilder: (context, index) => Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 20,
                                        child: Text(
                                          textAlign: TextAlign.center,
                                          (index + 1).toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Container(
                                        height: 50,
                                        width: 50,
                                        child: FadeInImage.memoryNetwork(
                                          placeholder: kTransparentImage,
                                          image:
                                              '${snapshot.data!.songHistory![index].song!.art}',
                                        ),
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: screenWidth * 1 / 2.5,
                                            child: Text(
                                              '${snapshot.data!.songHistory![index].song!.title}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.clip,
                                              maxLines: 2,
                                            ),
                                          ),
                                          Container(
                                            width: screenWidth * 1 / 2.5,
                                            child: Text(
                                              '${snapshot.data!.songHistory![index].song!.artist}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10),
                                              overflow: TextOverflow.clip,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 15,
                                  )
                                ],
                              ),
                            ),
                          );
                        } else {
                          return Center(
                              child: CircularProgressIndicator(
                            color: Colors.blue,
                          ));
                        }
                      })),
            );
          },
          icon: Icon(
            Icons.history,
            color: Colors.white,
          ),
          label: Text(
            'Song History',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                    backgroundColor: Color.fromARGB(255, 42, 42, 42),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Request Song',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            textEditingController.text = '';
                            context.read<SearchstringCubit>().emitNewSearch('');
                            Navigator.pop(context);
                          },
                        )
                      ],
                    ),
                    content: Column(
                      children: [
                        Flexible(
                          flex: 1,
                          child: TextField(
                            controller: textEditingController,
                            onChanged: (value) {
                              textEditingController.text = value;
                              context
                                  .read<SearchstringCubit>()
                                  .emitNewSearch(value);
                            },
                            style: TextStyle(color: Colors.white, fontSize: 20),
                            maxLines: 1,
                            cursorColor: Colors.blue,
                            decoration: InputDecoration(
                                hintText: 'Search a song or artist ...',
                                hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic),
                                enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white)),
                                focusedBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white)),
                                suffixIcon: Icon(
                                  Icons.search,
                                  color: Colors.white,
                                )),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Flexible(
                            flex: 9,
                            child: BlocBuilder<FilteredlistCubit,
                                FilteredlistState>(
                              builder: (context1, state) {
                                return Container(
                                  width: screenWidth * 8 / 9,
                                  height: screenHeight * 8 / 9,
                                  child: ListView.builder(
                                    itemCount: state.filteredList.length,
                                    itemBuilder: (context2, index) => Column(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            requestNewSong(
                                                context
                                                    .read<UrlCubit>()
                                                    .state
                                                    .url,
                                                state.filteredList[index]
                                                    .requestUrl!,
                                                screenContext);
                                            Navigator.pop(context);
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 25,
                                                child: Text(
                                                  textAlign: TextAlign.center,
                                                  (index + 1).toString(),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              Container(
                                                height: 50,
                                                width: 50,
                                                child:
                                                    FadeInImage.memoryNetwork(
                                                  placeholder:
                                                      kTransparentImage,
                                                  image:
                                                      '${state.filteredList[index].song!.art}',
                                                ),
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width:
                                                        screenWidth * 1 / 2.5,
                                                    child: Text(
                                                      '${state.filteredList[index].song!.title}',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      overflow:
                                                          TextOverflow.clip,
                                                      maxLines: 2,
                                                    ),
                                                  ),
                                                  Container(
                                                    width:
                                                        screenWidth * 1 / 2.5,
                                                    child: Text(
                                                      '${state.filteredList[index].song!.artist}',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10),
                                                      overflow:
                                                          TextOverflow.clip,
                                                      maxLines: 2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 15,
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )),
                      ],
                    )),
              );
            },
            icon: Icon(
              Icons.audiotrack_sharp,
              color: Colors.white,
            ),
            label: Text(
              'Request Song',
              style: TextStyle(color: Colors.white),
            )),
      ],
    );
  }
}
