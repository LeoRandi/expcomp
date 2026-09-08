import '../creatures/creature.dart';
import '../global_presentation/pixel_ui/pixel_ui.dart';

/// Keep presentation dependencies out of the creature model.
PixelUiThemeData themeForSource(CreatureSource source) => switch (source) {
  CreatureSource.falobris => FalobrisUi.theme,
  CreatureSource.raida => RaidaUi.theme,
  CreatureSource.koredull => NeonBulkheadUi.theme,
  CreatureSource.sunderkeep => SunderedKeepUi.theme,
  CreatureSource.undiria => UndiriaUi.theme,
};
