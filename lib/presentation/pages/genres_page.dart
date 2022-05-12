// ignore_for_file: prefer_const_constructors

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:car_play_app/data/ads/ad_helper.dart';
import 'package:car_play_app/presentation/pages/audio_music_page.dart';
import 'package:car_play_app/presentation/state_management/show_search_bar_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/src/provider.dart';

class GenresPage extends StatefulWidget {
  const GenresPage({Key? key}) : super(key: key);

  @override
  State<GenresPage> createState() => _GenresPageState();
}

class _GenresPageState extends State<GenresPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  late BannerAd _bottomBannerAd;

  bool _isBottomBannerAdLoaded = false;

  late List<GenreModel> _generySong = [];

  late List<GenreModel> _generySongs = [];

  void _createBottomBannerAd() {
    _bottomBannerAd = BannerAd(
      size: AdSize.fullBanner,
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBottomBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bottomBannerAd.load();
  }

  @override
  void initState() {
    super.initState();
    _createBottomBannerAd();
    getGenresAllSong();
    Future.delayed(Duration(seconds: 3), () {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _bottomBannerAd.dispose();
  }

  void getGenresAllSong() async {
    _generySong = await _audioQuery.queryGenres(
      sortType: GenreSortType.GENRE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    for (var i = 0; i < _generySong.length; i++) {
      var isSong = await _audioQuery.queryAudiosFrom(
        AudiosFromType.ALBUM_ID,
        _generySong[i].id,
        sortType: SongSortType.TITLE, // Default
        orderType: OrderType.ASC_OR_SMALLER, // Default
      );

      if (isSong.isNotEmpty) {
        _generySongs.add(_generySong[i]);
      }
    }

    print(_generySongs.length.toString() + " I am called");
  }

  @override
  Widget build(BuildContext context) {
    context.read<ShowSearchBarProvider>().showSearchBar(false);
    return Scaffold(
      bottomNavigationBar: _isBottomBannerAdLoaded
          ? SizedBox(
              height: _bottomBannerAd.size.height.toDouble(),
              width: _bottomBannerAd.size.width.toDouble(),
              child: AdWidget(ad: _bottomBannerAd),
            )
          : null,
      body:
          // FutureBuilder<List<GenreModel>>(
          // future: getGenresAllSong(),
          // builder: (context, item) {
          //   if (item.data == null) {
          //     // print(item.data.toString() + " I am called");
          //     return const Center(child: CircularProgressIndicator());
          //   }
          //   if (item.data!.isEmpty) {
          //     return Center(
          //       child: Text("No Songs Found"),
          //     );
          //   }
          //   return
          _generySongs.isEmpty
              ? Center(
                  child: Text("No Songs Found"),
                )
              : ListView.builder(
                  itemCount: _generySongs.length,
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () async {
                      // final map = _generySong[index].getMap;
                      // print(_generySong[index].id);
                      // int.parse(map['album_id'])
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShowGenresSongs(
                            id: _generySongs[index].id,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height / 6,
                        child: Center(
                          child: ListTile(
                            leading: QueryArtworkWidget(
                              artworkHeight:
                                  MediaQuery.of(context).size.height / 10,
                              artworkWidth:
                                  MediaQuery.of(context).size.width / 15,
                              id: _generySongs[index].id,
                              type: ArtworkType.AUDIO,
                            ),
                            title: Text(_generySongs[index].genre),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // );
                  // },
                ),
    );
  }
}

class ShowGenresSongs extends StatefulWidget {
  final int id;
  const ShowGenresSongs({Key? key, required this.id}) : super(key: key);

  @override
  State<ShowGenresSongs> createState() => _ShowGenresSongsState();
}

class _ShowGenresSongsState extends State<ShowGenresSongs> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final assetsAudioPlayer = AssetsAudioPlayer();

  List<SongModel> listOfSong = [];

  final List<Audio> _listAudio = [];

  getAllSong() async {
    listOfSong = await _audioQuery.queryAudiosFrom(
      AudiosFromType.ALBUM_ID,
      widget.id,
      sortType: SongSortType.TITLE, // Default
      orderType: OrderType.ASC_OR_SMALLER, // Default
    );
    createPlaylist(listOfSong);
  }

  @override
  void dispose() {
    assetsAudioPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    getAllSong();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image(
          image:
              AssetImage("assets/images/app_title_image-removebg-preview.png"),
          width: 200,
          height: 200,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<SongModel>>(
        future: _audioQuery.queryAudiosFrom(
          AudiosFromType.ALBUM_ID,
          widget.id,
          sortType: SongSortType.TITLE, // Default
          orderType: OrderType.ASC_OR_SMALLER, // Default
        ),
        builder: (context, item) {
          if (item.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (item.data!.isEmpty) {
            return Center(
              child: Text("No Songs Found"),
            );
          }
          return ListView.builder(
            itemCount: _listAudio.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioMusicPage(
                      player: assetsAudioPlayer,
                      audio: _listAudio,
                      index: index,
                    ),
                  ),
                );
              },
              child: Card(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height / 6,
                  child: Center(
                    child: ListTile(
                      leading: QueryArtworkWidget(
                        artworkHeight: MediaQuery.of(context).size.height / 10,
                        artworkWidth: MediaQuery.of(context).size.width / 15,
                        id: int.parse(_listAudio[index].metas.id!),
                        type: ArtworkType.AUDIO,
                      ),
                      title: Text(
                          _listAudio[index].metas.extra?["displayName"] ?? ""),
                      subtitle: Text(_listAudio[index].metas.title ?? ""),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  createPlaylist(List<SongModel> songs) {
    listOfSong = songs;

    for (int i = 0; i < listOfSong.length; i++) {
      _listAudio.add(
        Audio.file(
          listOfSong[i].data,
          metas: Metas(
            album: listOfSong[i].album,
            artist: listOfSong[i].artist,
            title: listOfSong[i].title,
            id: listOfSong[i].id.toString(),
            extra: {
              "data": listOfSong[i].data,
              "displayName": listOfSong[i].displayName,
              "uri": listOfSong[i].uri,
            },
          ),
        ),
      );
    }
    assetsAudioPlayer.open(
      Playlist(
        audios: _listAudio,
      ),
      headPhoneStrategy: HeadPhoneStrategy.pauseOnUnplug,
      showNotification: true,
      autoStart: false,
    );
  }
}
