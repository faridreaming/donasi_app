import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/campaign_model.dart';
import '../../services/campaign_service.dart';
import '../../utils/currency_formatter.dart';

class AdminCampaignScreen extends StatefulWidget {
  const AdminCampaignScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminCampaignScreen> createState() => _AdminCampaignScreenState();
}

class _AdminCampaignScreenState extends State<AdminCampaignScreen> {
  final CampaignService _campaignService = CampaignService();
  bool _isProcessing = false;
  double? _uploadProgress;

  Future<void> _handleCreateCampaign() async {
    final formResult = await showDialog<_CampaignFormResult>(
      context: context,
      builder: (context) => const _CampaignFormDialog(),
    );

    if (formResult == null || !mounted) {
      return;
    }

    await _runProcessing(() async {
      String? imageUrl;
      if (formResult.pickedImage != null) {
        imageUrl = await _campaignService.uploadCampaignImage(
          formResult.pickedImage!,
          onProgress: (value) {
            if (mounted) {
              setState(() {
                _uploadProgress = value;
              });
            }
          },
        );
      }

      await _campaignService.createCampaign(
        title: formResult.title,
        description: formResult.description,
        target: formResult.target,
        collected: formResult.collected,
        imageUrl: imageUrl,
      );
    }, successMessage: 'Campaign baru berhasil ditambahkan.');
  }

  Future<void> _handleEditCampaign(Campaign campaign) async {
    final formResult = await showDialog<_CampaignFormResult>(
      context: context,
      builder: (context) => _CampaignFormDialog(existingCampaign: campaign),
    );

    if (formResult == null || !mounted) {
      return;
    }

    await _runProcessing(() async {
      var imageUrl = campaign.imageUrl;

      if (formResult.removeExistingImage && imageUrl != null) {
        await _campaignService.deleteImageByUrl(imageUrl);
        imageUrl = null;
      }

      if (formResult.pickedImage != null) {
        if (imageUrl != null) {
          await _campaignService.deleteImageByUrl(imageUrl);
        }
        imageUrl = await _campaignService.uploadCampaignImage(
          formResult.pickedImage!,
          onProgress: (value) {
            if (mounted) {
              setState(() {
                _uploadProgress = value;
              });
            }
          },
        );
      }

      await _campaignService.updateCampaign(
        campaignId: campaign.id,
        title: formResult.title,
        description: formResult.description,
        target: formResult.target,
        collected: formResult.collected,
        imageUrl: imageUrl,
      );
    }, successMessage: 'Campaign berhasil diperbarui.');
  }

  Future<void> _handleDeleteCampaign(Campaign campaign) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Campaign?'),
          content: Text(
            'Campaign "${campaign.title}" akan dihapus permanen beserta data gambar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await _runProcessing(() async {
      await _campaignService.deleteCampaign(
        campaign.id,
        imageUrl: campaign.imageUrl,
      );
    }, successMessage: 'Campaign berhasil dihapus.');
  }

  Future<void> _runProcessing(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    setState(() {
      _isProcessing = true;
      _uploadProgress = null;
    });

    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Aksi gagal: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _uploadProgress = null;
        });
      }
    }
  }

  Widget _buildBody() {
    return Column(
      children: [
        if (_isProcessing) const LinearProgressIndicator(minHeight: 3),
        if (_uploadProgress != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFDFCB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload gambar ${(100 * _uploadProgress!).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.brown.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Row(
            children: [
              Text(
                'Daftar Campaign',
                style: TextStyle(
                  color: Colors.brown.shade800,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              Text(
                'Edit secara real-time',
                style: TextStyle(
                  color: Colors.brown.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Campaign>>(
            stream: _campaignService.watchCampaigns(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Data campaign belum bisa dimuat. Coba lagi sebentar lagi.',
                      style: TextStyle(color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final campaigns = snapshot.data ?? const <Campaign>[];

              if (campaigns.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 52,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada campaign.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tekan tombol tambah untuk membuat campaign pertama.',
                          style: TextStyle(color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: campaigns.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final campaign = campaigns[index];
                  final raised = formatRupiah(campaign.collected);
                  final target = formatRupiah(campaign.target);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 68,
                              height: 68,
                              color: const Color(0xFFFFEEE2),
                              child:
                                  campaign.imageUrl != null &&
                                      campaign.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      campaign.imageUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.image_outlined),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  campaign.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(0xFF35221A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Terkumpul Rp $raised dari Rp $target',
                                  style: TextStyle(
                                    color: Colors.brown.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _isProcessing
                                          ? null
                                          : () => _handleEditCampaign(campaign),
                                      icon: const Icon(Icons.edit_outlined),
                                      label: const Text('Edit'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _isProcessing
                                          ? null
                                          : () =>
                                                _handleDeleteCampaign(campaign),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: body,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isProcessing ? null : _handleCreateCampaign,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Campaign'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 16,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF5EC), Color(0xFFFEE8D8)],
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD84A24).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.campaign_outlined,
                color: Color(0xFFB43D1E),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kelola Campaign',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E1C15),
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Tambah, edit, dan optimalkan campaign',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF7A5A4B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _handleCreateCampaign,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Campaign'),
      ),
    );
  }
}

class _CampaignFormDialog extends StatefulWidget {
  const _CampaignFormDialog({this.existingCampaign});

  final Campaign? existingCampaign;

  @override
  State<_CampaignFormDialog> createState() => _CampaignFormDialogState();
}

class _CampaignFormDialogState extends State<_CampaignFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetController;
  late final TextEditingController _collectedController;

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _removeExistingImage = false;

  void _dismissKeyboard() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.unfocus();
    }
  }

  @override
  void initState() {
    super.initState();
    final campaign = widget.existingCampaign;
    _titleController = TextEditingController(text: campaign?.title ?? '');
    _descriptionController = TextEditingController(
      text: campaign?.description ?? '',
    );
    _targetController = TextEditingController(
      text: campaign?.target.toString() ?? '',
    );
    _collectedController = TextEditingController(
      text: campaign?.collected.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _collectedController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    _dismissKeyboard();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (file == null || !mounted) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _pickedImage = file;
      _pickedImageBytes = bytes;
      _removeExistingImage = false;
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    _dismissKeyboard();

    final target = int.parse(_targetController.text.trim());
    final collected = int.parse(_collectedController.text.trim());

    Navigator.pop(
      context,
      _CampaignFormResult(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        target: target,
        collected: collected,
        pickedImage: _pickedImage,
        removeExistingImage: _removeExistingImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCampaign != null;
    final title = isEditing ? 'Edit Campaign' : 'Tambah Campaign';
    final existingImageUrl = widget.existingCampaign?.imageUrl;
    final showExistingImage =
        existingImageUrl != null &&
        existingImageUrl.isNotEmpty &&
        !_removeExistingImage &&
        _pickedImageBytes == null;

    return AlertDialog(
      backgroundColor: const Color(0xFFFFFBF7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul campaign',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul wajib diisi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi singkat',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Deskripsi wajib diisi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target donasi (angka)',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Masukkan target lebih dari 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _collectedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dana terkumpul awal (angka)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed < 0) {
                      return 'Masukkan angka 0 atau lebih.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                if (_pickedImageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      _pickedImageBytes!,
                      height: 170,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (showExistingImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      existingImageUrl,
                      height: 170,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (_pickedImageBytes == null && !showExistingImage)
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('Belum ada gambar terpilih'),
                    ),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Pilih gambar'),
                    ),
                    if (showExistingImage || _pickedImageBytes != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _pickedImage = null;
                            _pickedImageBytes = null;
                            _removeExistingImage =
                                widget.existingCampaign?.imageUrl != null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        icon: const Icon(Icons.image_not_supported_outlined),
                        label: const Text('Hapus gambar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _dismissKeyboard();
            Navigator.pop(context);
          },
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Simpan Perubahan' : 'Tambah Campaign'),
        ),
      ],
    );
  }
}

class _CampaignFormResult {
  const _CampaignFormResult({
    required this.title,
    required this.description,
    required this.target,
    required this.collected,
    this.pickedImage,
    required this.removeExistingImage,
  });

  final String title;
  final String description;
  final int target;
  final int collected;
  final XFile? pickedImage;
  final bool removeExistingImage;
}
