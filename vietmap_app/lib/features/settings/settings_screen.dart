import 'package:flutter/material.dart';
import 'settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsRepository _repo = SettingsRepository.instance;
  bool _cameraEnabled = true;
  bool _railwayEnabled = true;
  bool _dangerEnabled = true;
  bool _speedEnabled = true;
  bool _ttsEnabled = true;
  bool _autoStart = true;
  String _voiceType = 'system';
  double _cameraRadius = 150;
  double _railwayRadius = 300;
  double _dangerRadius = 50;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _repo.init();
    final cameraEnabled = await _repo.isWarningEnabled('camera');
    final railwayEnabled = await _repo.isWarningEnabled('railway');
    final dangerEnabled = await _repo.isWarningEnabled('danger');
    final speedEnabled = await _repo.isWarningEnabled('speed');
    final ttsEnabled = await _repo.isTtsEnabled();
    final autoStart = await _repo.isAutoStartEnabled();
    final voiceType = await _repo.getVoiceType();
    final cameraRadius = await _repo.getRadius('camera');
    final railwayRadius = await _repo.getRadius('railway');
    final dangerRadius = await _repo.getRadius('danger');
    
    if (mounted) {
      setState(() {
        _cameraEnabled = cameraEnabled;
        _railwayEnabled = railwayEnabled;
        _dangerEnabled = dangerEnabled;
        _speedEnabled = speedEnabled;
        _ttsEnabled = ttsEnabled;
        _autoStart = autoStart;
        _voiceType = voiceType;
        _cameraRadius = cameraRadius;
        _railwayRadius = railwayRadius;
        _dangerRadius = dangerRadius;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Cảnh báo'),
          SwitchListTile(
            title: const Text('Camera phạt nguội'),
            value: _cameraEnabled,
            onChanged: (value) {
              setState(() => _cameraEnabled = value);
              _repo.setWarningEnabled('camera', value);
            },
          ),
          SwitchListTile(
            title: const Text('Đường sắt'),
            value: _railwayEnabled,
            onChanged: (value) {
              setState(() => _railwayEnabled = value);
              _repo.setWarningEnabled('railway', value);
            },
          ),
          SwitchListTile(
            title: const Text('Khu vực nguy hiểm'),
            value: _dangerEnabled,
            onChanged: (value) {
              setState(() => _dangerEnabled = value);
              _repo.setWarningEnabled('danger', value);
            },
          ),
          SwitchListTile(
            title: const Text('Tốc độ'),
            value: _speedEnabled,
            onChanged: (value) {
              setState(() => _speedEnabled = value);
              _repo.setWarningEnabled('speed', value);
            },
          ),
          const Divider(),
          _buildSectionTitle('Khoảng cách cảnh báo'),
          ListTile(
            title: Text('Camera: ${_cameraRadius.toStringAsFixed(0)}m'),
            subtitle: Slider(
              value: _cameraRadius,
              min: 50,
              max: 500,
              divisions: 45,
              onChanged: (value) {
                setState(() => _cameraRadius = value);
                _repo.setRadius('camera', value);
              },
            ),
          ),
          ListTile(
            title: Text('Đường sắt: ${_railwayRadius.toStringAsFixed(0)}m'),
            subtitle: Slider(
              value: _railwayRadius,
              min: 100,
              max: 1000,
              divisions: 90,
              onChanged: (value) {
                setState(() => _railwayRadius = value);
                _repo.setRadius('railway', value);
              },
            ),
          ),
          ListTile(
            title: Text('Khu vực nguy hiểm: ${_dangerRadius.toStringAsFixed(0)}m'),
            subtitle: Slider(
              value: _dangerRadius,
              min: 20,
              max: 200,
              divisions: 18,
              onChanged: (value) {
                setState(() => _dangerRadius = value);
                _repo.setRadius('danger', value);
              },
            ),
          ),
          const Divider(),
          _buildSectionTitle('Giọng nói'),
          SwitchListTile(
            title: const Text('Bật TTS'),
            value: _ttsEnabled,
            onChanged: (value) {
              setState(() => _ttsEnabled = value);
              _repo.setTtsEnabled(value);
            },
          ),
          ListTile(
            title: const Text('Loại giọng'),
            trailing: DropdownButton<String>(
              value: _voiceType,
              items: const [
                DropdownMenuItem(value: 'system', child: Text('Hệ thống')),
                DropdownMenuItem(value: 'male', child: Text('Nam')),
                DropdownMenuItem(value: 'female', child: Text('Nữ')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _voiceType = value);
                  _repo.setVoiceType(value);
                }
              },
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Tự động bật cảnh báo'),
            subtitle: const Text('Bật cảnh báo khi mở app'),
            value: _autoStart,
            onChanged: (value) {
              setState(() => _autoStart = value);
              _repo.setAutoStartEnabled(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

