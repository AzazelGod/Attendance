import 'package:attendance_check/view/hub/model/services/map_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MapModel>(
      create: (context) => MapModel(),
      child: const _DataEntryWidget(),
    );
  }
}

class _DataEntryWidget extends StatelessWidget {
  const _DataEntryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<MapModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Перестроить маршрут',
            onPressed: model.isLoading ? null : model.buildRoute,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                YandexMap(
                  mapObjects: model.mapObjects,
                  onMapCreated: model.onMapCreated,
                ),
                if (model.isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          const RouteInfoWidget(),
        ],
      ),
    );
  }
}

class RouteInfoWidget extends StatelessWidget {
  const RouteInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<MapModel>(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              MapModel.universityAddress,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (model.error != null)
              Text(model.error!, style: const TextStyle(fontSize: 16, color: Colors.red))
            else if (model.routeInfo != null)
              Text(model.routeInfo!, style: const TextStyle(fontSize: 16))
            else
              const Text('Строим маршрут...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
