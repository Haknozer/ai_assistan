import 'package:flutter/material.dart';
import '../../../models/email.dart';
import '../../../models/email_account.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../screens/email/utils/email_utils.dart';

/// E-posta oluşturma dialog'u widget'ı
class ComposeEmailDialog extends StatefulWidget {
  final Function(Email) onEmailSent;
  final Function(Email)? onDraftSaved;
  final Email? replyTo;
  final Email? forwardTo;
  final int? accountId;
  final int? userId;
  final List<EmailAccount>? availableAccounts;

  const ComposeEmailDialog({
    super.key,
    required this.onEmailSent,
    this.onDraftSaved,
    this.replyTo,
    this.forwardTo,
    this.accountId,
    this.userId,
    this.availableAccounts,
  });

  @override
  State<ComposeEmailDialog> createState() => _ComposeEmailDialogState();
}

class _ComposeEmailDialogState extends State<ComposeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  EmailImportance _importance = EmailImportance.normal;
  bool _isLoading = false;
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    // Seçili account ID'yi ayarla
    _selectedAccountId = widget.accountId;
    if (widget.replyTo != null) {
      // Reply modu
      _toController.text = widget.replyTo!.fromEmail;
      _subjectController.text =
          widget.replyTo!.subject.startsWith('Re:') ? widget.replyTo!.subject : 'Re: ${widget.replyTo!.subject}';
      // Mesaj kutusu boş açılır, kullanıcı isterse kendisi ekleyebilir
    } else if (widget.forwardTo != null) {
      // Forward modu
      _subjectController.text = widget.forwardTo!.subject.startsWith('Fwd:')
          ? widget.forwardTo!.subject
          : 'Fwd: ${widget.forwardTo!.subject}';
      // Forward için orijinal mesajı ekle
      final originalText = widget.forwardTo!.plainText ?? widget.forwardTo!.htmlContent ?? '';
      if (originalText.isNotEmpty) {
        _bodyController.text =
            '\n\n--- İletilen Mesaj ---\nGönderen: ${widget.forwardTo!.fromDisplayName} <${widget.forwardTo!.fromEmail}>\nTarih: ${widget.forwardTo!.receivedDate?.toString() ?? ''}\nKonu: ${widget.forwardTo!.subject}\n\n$originalText';
      }
    }
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _sendEmail() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();

    // To emails'i parse et (virgülle ayrılmış olabilir)
    final toEmails = _toController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final newEmail = Email(
      userId: widget.userId ?? 1,
      accountId: _selectedAccountId ?? widget.accountId ?? 1,
      fromEmail: widget.replyTo?.toEmails.isNotEmpty == true
          ? widget.replyTo!.toEmails.first
          : widget.forwardTo?.toEmails.isNotEmpty == true
              ? widget.forwardTo!.toEmails.first
              : '',
      fromName: '', // Backend'den gelecek
      toEmails: toEmails,
      subject: _subjectController.text.trim(),
      plainText: _bodyController.text.trim(),
      htmlContent: _bodyController.text.trim(),
      sentDate: now,
      status: EmailStatus.sent,
      importance: _importance,
      isRead: true,
      folder: EmailFolder.sent,
      createdAt: now,
      updatedAt: now,
    );

    widget.onEmailSent(newEmail);
    setState(() => _isLoading = false);
  }

  void _saveDraft() {
    // Validasyon yapmadan taslak olarak kaydet (boş da olabilir)
    setState(() => _isLoading = true);

    final now = DateTime.now();

    // To emails'i parse et (virgülle ayrılmış olabilir, boş da olabilir)
    final toEmails = _toController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final draftEmail = Email(
      userId: widget.userId ?? 1,
      accountId: _selectedAccountId ?? widget.accountId ?? 1,
      fromEmail: widget.replyTo?.toEmails.isNotEmpty == true
          ? widget.replyTo!.toEmails.first
          : widget.forwardTo?.toEmails.isNotEmpty == true
              ? widget.forwardTo!.toEmails.first
              : '',
      fromName: '', // Backend'den gelecek
      toEmails: toEmails,
      subject: _subjectController.text.trim(),
      plainText: _bodyController.text.trim(),
      htmlContent: _bodyController.text.trim(),
      sentDate: null, // Taslak henüz gönderilmedi
      status: EmailStatus.draft,
      importance: _importance,
      isRead: true,
      folder: EmailFolder.drafts,
      createdAt: now,
      updatedAt: now,
    );

    if (widget.onDraftSaved != null) {
      widget.onDraftSaved!(draftEmail);
    }
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.getCardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account seçimi (birden fazla account varsa)
                      if (widget.availableAccounts != null && widget.availableAccounts!.length > 1)
                        _buildAccountSelector(context),
                      if (widget.availableAccounts != null && widget.availableAccounts!.length > 1)
                        const SizedBox(height: 16),
                      _buildToField(context),
                      const SizedBox(height: 16),
                      _buildSubjectField(context),
                      const SizedBox(height: 16),
                      _buildImportanceSelector(context),
                      const SizedBox(height: 16),
                      _buildBodyField(context),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.mail_outline, color: AppTheme.primaryColor, size: 28),
        const SizedBox(width: 12),
        Text(
          widget.replyTo != null
              ? 'Yanıtla'
              : widget.forwardTo != null
                  ? 'Yönlendir'
                  : 'Yeni E-posta',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildToField(BuildContext context) {
    return TextFormField(
      controller: _toController,
      decoration: InputDecoration(
        labelText: 'Alıcı *',
        hintText: 'ornek@email.com',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Alıcı adresi zorunludur';
        }
        if (!EmailUtils.isValidEmail(value)) {
          return 'Geçerli bir e-posta adresi girin';
        }
        return null;
      },
    );
  }

  Widget _buildSubjectField(BuildContext context) {
    return TextFormField(
      controller: _subjectController,
      decoration: InputDecoration(
        labelText: 'Konu *',
        hintText: 'E-posta konusu',
        prefixIcon: const Icon(Icons.subject),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Konu zorunludur' : null,
    );
  }

  Widget _buildImportanceSelector(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.priority_high, size: 20),
        const SizedBox(width: 8),
        Text(
          'Önem Derecesi:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SegmentedButton<EmailImportance>(
            segments: const [
              ButtonSegment(
                value: EmailImportance.normal,
                label: Text('Normal'),
                icon: Icon(Icons.mail_outline, size: 18),
              ),
              ButtonSegment(
                value: EmailImportance.important,
                label: Text('Önemli'),
                icon: Icon(Icons.priority_high, size: 18),
              ),
            ],
            selected: {_importance},
            onSelectionChanged: (Set<EmailImportance> newSelection) {
              setState(() => _importance = newSelection.first);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBodyField(BuildContext context) {
    return TextFormField(
      controller: _bodyController,
      decoration: InputDecoration(
        labelText: 'Mesaj *',
        hintText: 'E-posta içeriğini yazın...',
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      maxLines: 10,
      validator: (value) => value == null || value.isEmpty ? 'Mesaj içeriği zorunludur' : null,
    );
  }

  Widget _buildAccountSelector(BuildContext context) {
    if (widget.availableAccounts == null || widget.availableAccounts!.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedAccountId ?? widget.accountId,
      decoration: InputDecoration(
        labelText: 'Gönderen Hesap',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: AppColors.getCardColor(context),
      ),
      items: widget.availableAccounts!.map((account) {
        final providerName = account.provider == EmailProvider.gmail ? 'Gmail' : 'Outlook';
        return DropdownMenuItem<int>(
          value: account.id,
          child: Text('$providerName - ${account.emailAddress}'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedAccountId = value;
        });
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Taslak Olarak Kaydet
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _saveDraft,
          icon: const Icon(Icons.drafts),
          label: const Text('Taslak'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            side: BorderSide(color: AppColors.getBorderColor(context)),
          ),
        ),
        const Spacer(),
        // İptal
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            'İptal',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        const SizedBox(width: 12),
        // Gönder
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _sendEmail,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.send, size: 18),
          label: const Text('Gönder'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
