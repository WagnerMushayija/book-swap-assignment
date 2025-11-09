// @ lib/screens/home/post_book_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';
import '../../models/book.dart';

class PostBookScreen extends StatefulWidget {
  final Book? editing;
  const PostBookScreen({super.key, this.editing});

  @override
  State<PostBookScreen> createState() => _PostBookScreenState();
}

class _PostBookScreenState extends State<PostBookScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _swapFor = TextEditingController();
  String _condition = 'Good';
  bool _loading = false;
  XFile? _image;

  @override
  void initState() {
    super.initState();
    final b = widget.editing;
    if (b != null) {
      _title.text = b.title;
      _author.text = b.author;
      _swapFor.text = b.swapFor;
      _condition = b.condition;
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        imageQuality: 50,
      );
      if (image != null) {
        setState(() => _image = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oops, image selection failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<BookProvider>();
    final editing = widget.editing;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? 'Share a Story' : 'Update Story'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildImage(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _title,
              validator: _req,
              decoration: const InputDecoration(
                labelText: 'Book Title',
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _author,
              validator: _req,
              decoration: const InputDecoration(
                labelText: 'Author',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _swapFor,
              decoration: const InputDecoration(
                labelText: 'Seeking in return (optional)',
                prefixIcon: Icon(Icons.sync_alt),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _condition,
              decoration: const InputDecoration(
                labelText: 'Condition',
                prefixIcon: Icon(Icons.star_half_outlined),
              ),
              items: ['New', 'Like New', 'Good', 'Used'].map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (v) => setState(() => _condition = v!),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(
                editing == null
                    ? Icons.add_circle_outline
                    : Icons.save_outlined,
              ),
              onPressed: _loading ? null : _submitForm,
              label: _loading
                  ? const Text('Working on it...')
                  : Text(editing == null ? 'Add to My Shelf' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_image != null) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: _image!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        );
      }
      return Image.file(
        File(_image!.path),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    if (widget.editing?.imageUrl.isNotEmpty == true) {
      return Image.network(
        widget.editing!.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text('Add Cover Photo', style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final message = widget.editing == null
          ? await _createBook()
          : await _updateBook();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oops! $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String> _createBook() async {
    await context.read<BookProvider>().create(
      title: _title.text.trim(),
      author: _author.text.trim(),
      condition: _condition,
      swapFor: _swapFor.text.trim(),
      image: _image,
    );
    return 'Story added to your shelf!';
  }

  Future<String> _updateBook() async {
    await context.read<BookProvider>().update(
      id: widget.editing!.id,
      title: _title.text.trim(),
      author: _author.text.trim(),
      condition: _condition,
      swapFor: _swapFor.text.trim(),
      image: _image,
      currentImageUrl: widget.editing!.imageUrl,
    );
    return 'Story details updated!';
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This detail is required!' : null;
}
