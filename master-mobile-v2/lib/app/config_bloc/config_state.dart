part of 'config_bloc.dart';

class ConfigState {
  const ConfigState(this.configModel);
  final ConfigModel configModel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfigState && configModel == other.configModel;

  @override
  int get hashCode => configModel.hashCode;
}
