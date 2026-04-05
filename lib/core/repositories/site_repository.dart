import 'package:lmt/core/services/site_service.dart';
import 'package:lmt/src/models/site_detail_model.dart';

class SiteRepository {
  final SupabaseSiteService service;

  SiteRepository(this.service);

  Future<void> saveSite(SiteDetailModel model) async {
    await service.upsertSite(model);

    if (model.poles != null) {
      await service.savePoles(model.circuitId, model.poles!);
    }

    if (model.gallery != null) {
      model.gallery!.circuitId = model.circuitId;
      await service.saveGallery(model.gallery!);
    }
  }
}
